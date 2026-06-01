// webauthnLoginStart - UNAUTHENTICATED cold-boot sign-in, ceremony leg 1.
//
// Unlike webauthnAssertionStart (which re-authenticates an ALREADY
// signed-in user for the Privacy Lock), this handler runs before any
// Firebase session exists. It drives a usernameless / discoverable-
// credential ceremony: the client calls `navigator.credentials.get()`
// with an EMPTY allowCredentials list, the platform authenticator offers
// the resident passkey it holds, and returns the `userHandle` (= the uid
// bytes set at registration) so the finish leg can resolve the user.
//
// Flow:
//   1. Provisioning guard - refuse when the production origin / RPID are
//      unset (server-side fence mirroring the client kill-switch).
//   2. Rate-limit consume keyed by caller IP (there is no uid yet) so a
//      noisy client cannot spam the global challenge store.
//   3. generateAuthenticationOptions with allowCredentials: [] (empty →
//      discoverable credential selection on the client).
//   4. Persist the challenge GLOBALLY at webauthnLoginChallenges/
//      {challengeId} with purpose 'login' + 5-min TTL. Top-level + admin-
//      only (firestore.rules denies all client access) because there is
//      no uid to scope it under yet.
//   5. Return { ok: true, options, challengeId }.
//
// PII discipline: logs include outcome + latencyMs only. No IP, no
// challenge, no credential material is logged.
//
// CF posture: region asia-southeast1, 256MiB, 30s timeout,
// enforceAppCheck: false (matches the existing CF suite).

import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { generateAuthenticationOptions } from '@simplewebauthn/server';

import { consumeToken } from './rateLimit.js';
import {
  WEBAUTHN_PRODUCTION_ORIGIN,
  WEBAUTHN_RPID,
  WEBAUTHN_STAGING_ORIGINS,
  isProvisioned,
  resolveExpectedRpId,
} from './webauthnConstants.js';

// Shared IP-keyed rate-limit bucket for the unauthenticated login
// ceremony. Both legs (start + finish) consume from it so the throttle
// covers the whole cold-boot path, not just challenge issuance.
export const LOGIN_RATE_LIMIT_COLLECTION = 'rateLimits.webauthnLogin';
export const LOGIN_RATE_LIMIT_WINDOW_MS = 60_000;
export const LOGIN_RATE_LIMIT_MAX = 20;
const CHALLENGE_TTL_MS = 5 * 60 * 1000;

/** Top-level, admin-only challenge store for the no-uid login ceremony. */
export const LOGIN_CHALLENGE_COLLECTION = 'webauthnLoginChallenges';

export interface WebauthnLoginStartResponse {
  ok: boolean;
  options?: unknown;
  challengeId?: string;
  code?: string;
  lockedUntilMs?: number;
}

/**
 * Caller key for rate limiting when no uid exists. Returns `null` when no
 * source IP is resolvable so the caller FAILS CLOSED rather than sharing a
 * single global `'unknown'` bucket (which an attacker could exploit to keep
 * their own traffic isolated from real users, or to DoS everyone else).
 */
export function callerKey(request: CallableRequest<unknown>): string | null {
  const ip = request.rawRequest?.ip;
  return typeof ip === 'string' && ip.length > 0 ? ip : null;
}

export async function handleWebauthnLoginStart(
  request: CallableRequest<unknown>,
): Promise<WebauthnLoginStartResponse> {
  const startMs = Date.now();
  const db = getFirestore();

  if (!isProvisioned()) {
    logger.info({
      event: 'webauthnLoginStart',
      outcome: 'not_provisioned',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'webauthn_not_provisioned' };
  }
  const rpId = resolveExpectedRpId();
  if (rpId === null) {
    return { ok: false, code: 'webauthn_not_provisioned' };
  }

  // Rate-limit by caller IP BEFORE issuing a challenge - the only
  // identifier available pre-auth. Fail closed when the IP is unknown.
  const key = callerKey(request);
  if (key === null) {
    logger.info({
      event: 'webauthnLoginStart',
      outcome: 'no_caller_ip',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'rate_limited' };
  }
  let rl;
  try {
    rl = await consumeToken(key, Date.now(), {
      windowMs: LOGIN_RATE_LIMIT_WINDOW_MS,
      max: LOGIN_RATE_LIMIT_MAX,
      collection: LOGIN_RATE_LIMIT_COLLECTION,
    });
  } catch (e) {
    logger.error({
      event: 'webauthnLoginStart',
      outcome: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return { ok: false, code: 'internal' };
  }
  if (!rl.allowed) {
    logger.info({
      event: 'webauthnLoginStart',
      outcome: 'rate_limited',
      latencyMs: Date.now() - startMs,
    });
    return {
      ok: false,
      code: 'rate_limited',
      lockedUntilMs: Date.now() + rl.retryAfterSec * 1000,
    };
  }

  // Empty allowCredentials → the client performs a discoverable-credential
  // (usernameless) get; the authenticator surfaces its resident passkey
  // and returns the userHandle the finish leg needs.
  const options = await generateAuthenticationOptions({
    rpID: rpId,
    userVerification: 'preferred',
    allowCredentials: [],
  });

  const challengeId = options.challenge;
  await db.doc(`${LOGIN_CHALLENGE_COLLECTION}/${challengeId}`).set({
    challenge: options.challenge,
    purpose: 'login',
    expiresAt: new Date(Date.now() + CHALLENGE_TTL_MS),
    createdAt: new Date(),
  });

  logger.info({
    event: 'webauthnLoginStart',
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return { ok: true, options, challengeId };
}

export const webauthnLoginStart = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    // Enable CORS so browser callers (Flutter web) can reach the callable.
    // The real WebAuthn security boundary is the `expectedOrigin` check on
    // the finish leg (server-side via @simplewebauthn), not transport CORS.
    cors: true,
  },
  (req: CallableRequest<unknown>) => {
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnLoginStart(req);
  },
);
