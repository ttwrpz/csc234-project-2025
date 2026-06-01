// webauthnRegisterFinish - Cloud Function callable for the registration
// ceremony's second leg.
//
// Flow:
//   1. Auth check (HttpsError unauthenticated if no uid).
//   2. Read the challenge at users/{uid}/webauthnChallenges/{challengeId};
//      reject with { ok: false, code: 'challenge_expired' } if missing or
//      past `expiresAt`.
//   3. Provisioning guard - same isProvisioned() check the start handler
//      runs (defence in depth; the start handler should already have
//      blocked the call if the env-var isn't set, but the finish path
//      should refuse to verify against a placeholder origin).
//   4. Call verifyRegistrationResponse with the client's
//      `attestationResponse`.
//   5. On success: persist the credential at users/{uid}/webauthn/
//      {credentialId} with the canonical schema (ADR-0014 §"Decision C")
//      and delete the challenge doc.
//   6. Return { ok: true, credentialId }.
//
// PII discipline: logs include uid + outcome + latencyMs only. Never log
// the challenge, the clientDataJSON, the attestationObject, the public
// key, or the credentialId itself (it's a stable per-user identifier).
//
// CF posture: region asia-southeast1, 256MiB, 30s timeout,
// enforceAppCheck: false (matches the existing CF suite).

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { verifyRegistrationResponse } from '@simplewebauthn/server';

import {
  WEBAUTHN_PRODUCTION_ORIGIN,
  WEBAUTHN_RPID,
  WEBAUTHN_STAGING_ORIGINS,
  isProvisioned,
  resolveExpectedOrigins,
  resolveExpectedRpId,
} from './webauthnConstants.js';

export interface WebauthnRegisterFinishResponse {
  ok: boolean;
  credentialId?: string;
  code?: string;
}

interface FinishRequest {
  v?: number;
  challengeId?: unknown;
  response?: unknown;
}

export async function handleWebauthnRegisterFinish(
  request: CallableRequest<FinishRequest>,
): Promise<WebauthnRegisterFinishResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();
  const db = getFirestore();

  const payload = request.data ?? {};
  const challengeId = typeof payload.challengeId === 'string' ? payload.challengeId : null;
  const attestation = payload.response as Record<string, unknown> | undefined;
  if (!challengeId || !attestation) {
    logger.info({
      event: 'webauthnRegisterFinish',
      uid,
      outcome: 'invalid_argument',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  if (!isProvisioned()) {
    logger.info({
      event: 'webauthnRegisterFinish',
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

  // Read + validate the challenge.
  const challengeRef = db.doc(
    `users/${uid}/webauthnChallenges/${challengeId}`,
  );
  const challengeSnap = await challengeRef.get();
  if (!challengeSnap.exists) {
    logger.info({
      event: 'webauthnRegisterFinish',
      uid,
      outcome: 'challenge_expired',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'challenge_expired' };
  }
  const challengeData = challengeSnap.data() as
    | { challenge?: string; purpose?: string; expiresAt?: { toMillis(): number } | Date }
    | undefined;
  const expiresAt = challengeData?.expiresAt;
  const expiresMs =
    expiresAt instanceof Date
      ? expiresAt.getTime()
      : typeof (expiresAt as { toMillis?: () => number } | undefined)?.toMillis === 'function'
        ? (expiresAt as { toMillis: () => number }).toMillis()
        : 0;
  if (!expiresMs || expiresMs < Date.now() || challengeData?.purpose !== 'register') {
    // Best-effort cleanup of the stale doc.
    await challengeRef.delete().catch(() => undefined);
    logger.info({
      event: 'webauthnRegisterFinish',
      uid,
      outcome: 'challenge_expired',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'challenge_expired' };
  }
  const expectedChallenge = challengeData?.challenge;
  if (typeof expectedChallenge !== 'string' || expectedChallenge.length === 0) {
    await challengeRef.delete().catch(() => undefined);
    return { ok: false, code: 'verification_failed' };
  }

  // Verify the attestation.
  let verification;
  try {
    verification = await verifyRegistrationResponse({
      response: attestation as unknown as Parameters<typeof verifyRegistrationResponse>[0]['response'],
      expectedChallenge,
      expectedOrigin: resolveExpectedOrigins(),
      expectedRPID: rpId,
      requireUserVerification: false,
    });
  } catch (e) {
    logger.warn({
      event: 'webauthnRegisterFinish',
      uid,
      outcome: 'verification_threw',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    await challengeRef.delete().catch(() => undefined);
    return { ok: false, code: 'verification_failed' };
  }

  if (!verification.verified || !verification.registrationInfo) {
    logger.info({
      event: 'webauthnRegisterFinish',
      uid,
      outcome: 'verification_failed',
      latencyMs: Date.now() - startMs,
    });
    await challengeRef.delete().catch(() => undefined);
    return { ok: false, code: 'verification_failed' };
  }

  // Persist the credential. `@simplewebauthn/server@^11` returns the
  // registration info nested under a `credential` object - extract the
  // canonical fields and serialize the binary ones to base64url.
  const regInfo = verification.registrationInfo as {
    credential: {
      id: string;
      publicKey: Uint8Array;
      counter: number;
      transports?: readonly string[];
    };
    aaguid?: string;
    credentialDeviceType?: string;
    credentialBackedUp?: boolean;
  };

  const credentialId = regInfo.credential.id;
  const publicKeyBase64 = Buffer.from(regInfo.credential.publicKey).toString(
    'base64',
  );
  const counter = regInfo.credential.counter;
  const transports = Array.isArray(regInfo.credential.transports)
    ? regInfo.credential.transports.filter((t): t is string => typeof t === 'string')
    : [];
  const aaguid = typeof regInfo.aaguid === 'string' ? regInfo.aaguid : '';

  await db.doc(`users/${uid}/webauthn/${credentialId}`).set({
    credentialId,
    publicKeyBase64,
    counter,
    transports,
    aaguid,
    createdAt: FieldValue.serverTimestamp(),
    lastUsedAt: null,
    failedAttempts: 0,
    lockedUntil: null,
  });

  // Delete the challenge - single-use.
  await challengeRef.delete().catch(() => undefined);

  logger.info({
    event: 'webauthnRegisterFinish',
    uid,
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return { ok: true, credentialId };
}

export const webauthnRegisterFinish = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    // CORS open for browser callers; the callable still requires
    // request.auth.uid and `expectedOrigin` is enforced in
    // verifyRegistrationResponse.
    cors: true,
  },
  (req: CallableRequest<FinishRequest>) => {
    // Touch the defineString params so they're registered with the
    // Functions v2 runtime - same pattern the start handler uses.
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnRegisterFinish(req);
  },
);
