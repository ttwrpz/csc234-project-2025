// webauthnAssertionStart — Cloud Function callable for the assertion
// ceremony's first leg.
//
// Flow:
//   1. Auth check (HttpsError unauthenticated if no uid).
//   2. Provisioning guard — refuse to issue a challenge when the
//      production origin / RPID are unset.
//   3. Rate-limit consume via rateLimits.webauthn/{uid}.
//   4. Read the user's registered credential (single, v1.5); if absent,
//      return { ok: false, code: 'no_credential' }.
//   5. Honour `lockedUntil` from the credential doc — assertion is
//      gated by the rate-limit anchor mirroring the PIN ladder.
//   6. Call generateAuthenticationOptions with allowCredentials populated.
//   7. Persist the challenge at users/{uid}/webauthnChallenges/
//      {challengeId} with purpose 'assert' and a 5-min TTL.
//   8. Return { ok: true, options, challengeId }.
//
// PII discipline: logs include uid + outcome + latencyMs only. The
// credentialId is intentionally NOT logged (per ADR-0014 §"Logging
// schema" — the full id is treated as PII-adjacent).
//
// CF posture: region asia-southeast1, 256MiB, 30s timeout,
// enforceAppCheck: false (matches the existing CF suite).

import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { generateAuthenticationOptions } from '@simplewebauthn/server';

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

export interface WebauthnAssertionStartResponse {
  ok: boolean;
  options?: unknown;
  challengeId?: string;
  code?: string;
  lockedUntilMs?: number;
}

export async function handleWebauthnAssertionStart(
  request: CallableRequest<unknown>,
): Promise<WebauthnAssertionStartResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();
  const db = getFirestore();

  if (!isProvisioned()) {
    logger.info({
      event: 'webauthnAssertionStart',
      uid,
      outcome: 'not_provisioned',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'webauthn_not_provisioned' };
  }
  const rpId = resolveExpectedRpId();
  if (rpId === null) {
    return { ok: false, code: 'webauthn_not_provisioned' };
  }

  // Rate-limit consume BEFORE reading the credential — denies a noisy
  // attacker from hammering Firestore reads for free.
  let rl;
  try {
    rl = await consumeToken(uid, Date.now(), {
      windowMs: RATE_LIMIT_WINDOW_MS,
      max: RATE_LIMIT_MAX,
      collection: RATE_LIMIT_COLLECTION,
    });
  } catch (e) {
    logger.error({
      event: 'webauthnAssertionStart',
      uid,
      outcome: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    throw new HttpsError('internal', 'internal-error');
  }
  if (!rl.allowed) {
    logger.info({
      event: 'webauthnAssertionStart',
      uid,
      outcome: 'rate_limited',
      latencyMs: Date.now() - startMs,
    });
    return {
      ok: false,
      code: 'rate_limited',
      lockedUntilMs: Date.now() + rl.retryAfterSec * 1000,
    };
  }

  // Read the registered credential — v1.5 ships single-credential, so
  // the first doc is the only doc.
  const credSnap = await db.collection(`users/${uid}/webauthn`).limit(1).get();
  const credDoc = credSnap.docs[0];
  if (credSnap.empty || !credDoc) {
    logger.info({
      event: 'webauthnAssertionStart',
      uid,
      outcome: 'no_credential',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'no_credential' };
  }
  const credData = credDoc.data() as {
    credentialId?: string;
    transports?: string[];
    lockedUntil?: { toMillis(): number } | Date | null;
  };

  // Per-credential rate-limit anchor — distinct from the per-uid rate
  // window above. Mirrors the PIN ladder ("5 failures → 60s, 10/hour →
  // 30min") which lives at the same doc on the PIN side.
  const lockedUntil = credData.lockedUntil;
  const lockedUntilMs =
    lockedUntil instanceof Date
      ? lockedUntil.getTime()
      : typeof (lockedUntil as { toMillis?: () => number } | null | undefined)?.toMillis === 'function'
        ? (lockedUntil as { toMillis: () => number }).toMillis()
        : null;
  if (lockedUntilMs !== null && lockedUntilMs > Date.now()) {
    logger.info({
      event: 'webauthnAssertionStart',
      uid,
      outcome: 'rate_limited_credential',
      latencyMs: Date.now() - startMs,
    });
    return {
      ok: false,
      code: 'rate_limited',
      lockedUntilMs,
    };
  }

  const credentialId =
    typeof credData.credentialId === 'string' ? credData.credentialId : credDoc.id;
  const transports = Array.isArray(credData.transports)
    ? credData.transports.filter((t): t is string => typeof t === 'string')
    : [];

  const options = await generateAuthenticationOptions({
    rpID: rpId,
    userVerification: 'preferred',
    allowCredentials: [
      {
        id: credentialId,
        transports: transports as Parameters<
          typeof generateAuthenticationOptions
        >[0]['allowCredentials'] extends (infer U)[] | undefined
          ? U extends { transports?: infer T }
            ? T
            : never
          : never,
      },
    ],
  });

  const challengeId = options.challenge;
  await db.doc(`users/${uid}/webauthnChallenges/${challengeId}`).set({
    challenge: options.challenge,
    purpose: 'assert',
    expiresAt: new Date(Date.now() + CHALLENGE_TTL_MS),
    createdAt: new Date(),
  });

  logger.info({
    event: 'webauthnAssertionStart',
    uid,
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return { ok: true, options, challengeId };
}

export const webauthnAssertionStart = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    // CORS open for browser callers; callable already requires
    // request.auth.uid for the re-auth path.
    cors: true,
  },
  (req: CallableRequest<unknown>) => {
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnAssertionStart(req);
  },
);
