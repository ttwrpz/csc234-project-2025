// webauthnRegisterStart — Cloud Function callable for the registration
// ceremony's first leg (ADR-0014 Decision B).
//
// Flow:
//   1. Auth check (HttpsError unauthenticated if no uid).
//   2. PIN guard — read users/{uid}/security/pin; if absent, reject with
//      { ok: false, code: 'pin_required' }. ADR-0014 Decision E: WebAuthn
//      cannot be enabled without a PIN (the PIN is the recovery factor).
//   3. Provisioning guard — if WEBAUTHN_PRODUCTION_ORIGIN is empty AND no
//      RPID is set, reject with { ok: false, code: 'webauthn_not_provisioned' }.
//      This is the v1.5-dark server-side safety net (ADR-0014 §"Cuts to
//      make first if a day slips" #3).
//   4. Rate-limit consume via rateLimits.webauthn/{uid}.
//   5. Generate creation options via @simplewebauthn/server.
//   6. Persist the challenge at users/{uid}/security/webauthnChallenges/
//      {challengeId} with expiresAt = now + 5min.
//   7. Return { ok: true, options, challengeId }.
//
// PII canary: log payload includes uid + outcome + latencyMs only.
// Never log the challenge, the RP id, or any field from the options
// payload (the user-handle in particular is the uid bytes — already in
// the allowlisted `uid` field, but no need to log it twice).
//
// CF posture (ADR-0014 Decision B): region asia-southeast1, 256MiB, 30s
// timeout, enforceAppCheck: false (matches the existing CF suite).

import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { generateRegistrationOptions } from '@simplewebauthn/server';

import { consumeToken } from './rateLimit.js';
import {
  WEBAUTHN_PRODUCTION_ORIGIN,
  WEBAUTHN_RPID,
  WEBAUTHN_STAGING_ORIGINS,
  isProvisioned,
  resolveExpectedRpId,
} from './webauthnConstants.js';

const RATE_LIMIT_COLLECTION = 'rateLimits.webauthn';
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 10;
const CHALLENGE_TTL_MS = 5 * 60 * 1000;

export interface WebauthnRegisterStartResponse {
  ok: boolean;
  options?: unknown;
  challengeId?: string;
  code?: string;
}

export async function handleWebauthnRegisterStart(
  request: CallableRequest<unknown>,
): Promise<WebauthnRegisterStartResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();
  const db = getFirestore();

  // PIN guard — WebAuthn cannot be enabled without a PIN (Decision E).
  const pinSnap = await db.doc(`users/${uid}/security/pin`).get();
  if (!pinSnap.exists) {
    logger.info({
      event: 'webauthnRegisterStart',
      uid,
      outcome: 'pin_required',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'pin_required' };
  }

  // Provisioning guard — the v1.5-dark server-side fence.
  if (!isProvisioned()) {
    logger.info({
      event: 'webauthnRegisterStart',
      uid,
      outcome: 'not_provisioned',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'webauthn_not_provisioned' };
  }

  // Rate-limit. Consumed BEFORE the credential-options generation so an
  // attacker spamming the CF cannot DoS the Firestore challenge store.
  let rl;
  try {
    rl = await consumeToken(uid, Date.now(), {
      windowMs: RATE_LIMIT_WINDOW_MS,
      max: RATE_LIMIT_MAX,
      collection: RATE_LIMIT_COLLECTION,
    });
  } catch (e) {
    logger.error({
      event: 'webauthnRegisterStart',
      uid,
      outcome: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    throw new HttpsError('internal', 'internal-error');
  }
  if (!rl.allowed) {
    logger.info({
      event: 'webauthnRegisterStart',
      uid,
      outcome: 'rate_limited',
      latencyMs: Date.now() - startMs,
    });
    return {
      ok: false,
      code: 'rate_limited',
    };
  }

  const rpId = resolveExpectedRpId();
  if (rpId === null) {
    // isProvisioned() above guarantees this can't happen in practice,
    // but the null-check satisfies the type system and provides
    // defence in depth if the env var is partially configured.
    return { ok: false, code: 'webauthn_not_provisioned' };
  }

  // Build creation options. `attestationType: 'none'` per ADR-0014
  // Open Follow-up #6 — v1.5 does not verify attestation; v1.6 may
  // revisit if the project moves to enterprise authentication.
  const options = await generateRegistrationOptions({
    rpName: 'MoodBloom',
    rpID: rpId,
    userID: new TextEncoder().encode(uid),
    userName: uid,
    attestationType: 'none',
    authenticatorSelection: {
      residentKey: 'preferred',
      userVerification: 'preferred',
    },
  });

  // Persist the challenge. The Firestore TTL policy on `expiresAt`
  // (operator-configured in console) auto-reaps after 5 minutes; the
  // finish handler also explicitly deletes the doc on success.
  const challengeId = options.challenge;
  await db
    .doc(`users/${uid}/security/webauthnChallenges/${challengeId}`)
    .set({
      challenge: options.challenge,
      purpose: 'register',
      expiresAt: new Date(Date.now() + CHALLENGE_TTL_MS),
      createdAt: new Date(),
    });

  logger.info({
    event: 'webauthnRegisterStart',
    uid,
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return {
    ok: true,
    options,
    challengeId,
  };
}

export const webauthnRegisterStart = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    // ADR-0014 §Origin handling — the constants are read at runtime via
    // defineString; declaring them here gives Firebase Functions the
    // wiring it needs to resolve the params at deploy time.
    secrets: [],
    cors: false,
  },
  // The defineString params have to be in the closure for v2 to bind
  // them; reference each one once so the param is registered.
  (req: CallableRequest<unknown>) => {
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnRegisterStart(req);
  },
);
