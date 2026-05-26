// webauthnAssertionFinish — Cloud Function callable for the assertion
// ceremony's second leg.
//
// Flow:
//   1. Auth check (HttpsError unauthenticated if no uid).
//   2. Read the challenge at users/{uid}/webauthnChallenges/{challengeId};
//      reject + cleanup if missing / past TTL / wrong purpose.
//   3. Read the registered credential (single-credential v1.5).
//   4. Call verifyAuthenticationResponse with the stored public key +
//      counter.
//   5. Counter-regression detection per ADR-0014 Decision B — if the
//      asserted counter is NOT strictly greater than the stored counter
//      (and the stored counter is > 0), emit a `webauthn.counter_regression`
//      structured-log line and reject as `verificationFailed` (which the
//      Dart repo maps to `counter_regression`).
//   6. On success: bump counter, set lastUsedAt, clear failedAttempts +
//      lockedUntil. Delete the challenge.
//   7. On failure: bump failedAttempts; set lockedUntil if the soft (5)
//      or hard (10) threshold crosses. Delete the challenge.
//
// PII discipline: logs include uid + outcome + latencyMs only. The
// counter-regression log also includes the last 8 chars of the
// credentialId (per ADR-0014 §"Logging schema") so the operator can
// distinguish events without exposing the full credential.
//
// CF posture: region asia-southeast1, 256MiB, 30s timeout,
// enforceAppCheck: false (matches the existing CF suite).

import {
  getFirestore,
  FieldValue,
  Timestamp,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { verifyAuthenticationResponse } from '@simplewebauthn/server';

import {
  WEBAUTHN_PRODUCTION_ORIGIN,
  WEBAUTHN_RPID,
  WEBAUTHN_STAGING_ORIGINS,
  isProvisioned,
  resolveExpectedOrigins,
  resolveExpectedRpId,
} from './webauthnConstants.js';

// Rate-limit ladder mirrors the PIN side
// (apps/mobile/lib/features/auth/data/pin_repository_impl.dart:44..47).
const SOFT_LOCK_THRESHOLD = 5;
const SOFT_LOCK_MS = 60_000; // 1 minute
const HARD_LOCK_THRESHOLD = 10;
const HARD_LOCK_MS = 30 * 60_000; // 30 minutes

interface FinishRequest {
  v?: number;
  challengeId?: unknown;
  response?: unknown;
}

export interface WebauthnAssertionFinishResponse {
  ok: boolean;
  code?: string;
  lockedUntilMs?: number;
}

export async function handleWebauthnAssertionFinish(
  request: CallableRequest<FinishRequest>,
): Promise<WebauthnAssertionFinishResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();
  const db = getFirestore();

  const payload = request.data ?? {};
  const challengeId = typeof payload.challengeId === 'string' ? payload.challengeId : null;
  const assertion = payload.response as Record<string, unknown> | undefined;
  if (!challengeId || !assertion) {
    logger.info({
      event: 'webauthnAssertionFinish',
      uid,
      outcome: 'invalid_argument',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  if (!isProvisioned()) {
    logger.info({
      event: 'webauthnAssertionFinish',
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

  const challengeRef = db.doc(
    `users/${uid}/webauthnChallenges/${challengeId}`,
  );
  const challengeSnap = await challengeRef.get();
  if (!challengeSnap.exists) {
    logger.info({
      event: 'webauthnAssertionFinish',
      uid,
      outcome: 'challenge_expired',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'challenge_expired' };
  }
  const challengeData = challengeSnap.data() as
    | {
        challenge?: string;
        purpose?: string;
        expiresAt?: { toMillis(): number } | Date;
      }
    | undefined;
  const expiresAt = challengeData?.expiresAt;
  const expiresMs =
    expiresAt instanceof Date
      ? expiresAt.getTime()
      : typeof (expiresAt as { toMillis?: () => number } | undefined)?.toMillis === 'function'
        ? (expiresAt as { toMillis: () => number }).toMillis()
        : 0;
  if (!expiresMs || expiresMs < Date.now() || challengeData?.purpose !== 'assert') {
    await challengeRef.delete().catch(() => undefined);
    logger.info({
      event: 'webauthnAssertionFinish',
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

  // Read the credential.
  const credSnap = await db.collection(`users/${uid}/webauthn`).limit(1).get();
  const credDoc = credSnap.docs[0];
  if (credSnap.empty || !credDoc) {
    await challengeRef.delete().catch(() => undefined);
    logger.info({
      event: 'webauthnAssertionFinish',
      uid,
      outcome: 'no_credential',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'no_credential' };
  }
  const credData = credDoc.data() as {
    credentialId?: string;
    publicKeyBase64?: string;
    counter?: number;
    transports?: string[];
    failedAttempts?: number;
    lockedUntil?: { toMillis(): number } | Date | null;
  };

  // Re-check the per-credential lock window. The start handler already
  // gated this, but the time between start and finish could expose the
  // race; this also catches a tampered client that called finish
  // directly without start.
  const lockedUntil = credData.lockedUntil;
  const lockedUntilMs =
    lockedUntil instanceof Date
      ? lockedUntil.getTime()
      : typeof (lockedUntil as { toMillis?: () => number } | null | undefined)?.toMillis === 'function'
        ? (lockedUntil as { toMillis: () => number }).toMillis()
        : null;
  if (lockedUntilMs !== null && lockedUntilMs > Date.now()) {
    await challengeRef.delete().catch(() => undefined);
    return { ok: false, code: 'rate_limited', lockedUntilMs };
  }

  const credentialId =
    typeof credData.credentialId === 'string' ? credData.credentialId : credDoc.id;
  const storedPublicKey = credData.publicKeyBase64 ?? '';
  const storedCounter = typeof credData.counter === 'number' ? credData.counter : 0;
  if (storedPublicKey.length === 0) {
    await challengeRef.delete().catch(() => undefined);
    return { ok: false, code: 'verification_failed' };
  }
  const publicKeyBytes = new Uint8Array(Buffer.from(storedPublicKey, 'base64'));
  const transports = Array.isArray(credData.transports)
    ? credData.transports.filter((t): t is string => typeof t === 'string')
    : [];

  // Verify.
  let verification;
  try {
    verification = await verifyAuthenticationResponse({
      response: assertion as unknown as Parameters<typeof verifyAuthenticationResponse>[0]['response'],
      expectedChallenge,
      expectedOrigin: resolveExpectedOrigins(),
      expectedRPID: rpId,
      credential: {
        id: credentialId,
        publicKey: publicKeyBytes,
        counter: storedCounter,
        transports: transports as Parameters<
          typeof verifyAuthenticationResponse
        >[0]['credential']['transports'],
      },
      requireUserVerification: false,
    });
  } catch (e) {
    await challengeRef.delete().catch(() => undefined);
    await bumpFailedAttempts(db, uid, credDoc.id, credData.failedAttempts ?? 0);
    logger.warn({
      event: 'webauthnAssertionFinish',
      uid,
      outcome: 'verification_threw',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  if (!verification.verified || !verification.authenticationInfo) {
    await challengeRef.delete().catch(() => undefined);
    const next = await bumpFailedAttempts(
      db,
      uid,
      credDoc.id,
      credData.failedAttempts ?? 0,
    );
    logger.info({
      event: 'webauthnAssertionFinish',
      uid,
      outcome: 'verification_failed',
      latencyMs: Date.now() - startMs,
    });
    if (next.lockedUntilMs !== null) {
      return { ok: false, code: 'rate_limited', lockedUntilMs: next.lockedUntilMs };
    }
    return { ok: false, code: 'verification_failed' };
  }

  const newCounter = verification.authenticationInfo.newCounter ?? 0;

  // Counter-regression check (ADR-0014 Decision B). If the asserted
  // counter is NOT strictly greater than the stored counter AND the
  // stored counter is > 0, treat as a cloned-authenticator signal and
  // fail closed.
  if (storedCounter > 0 && newCounter <= storedCounter) {
    await challengeRef.delete().catch(() => undefined);
    await bumpFailedAttempts(db, uid, credDoc.id, credData.failedAttempts ?? 0);
    const credSuffix = credentialId.length >= 8
      ? credentialId.slice(credentialId.length - 8)
      : credentialId;
    logger.warn({
      event: 'webauthn.counter_regression',
      uid,
      credentialIdSuffix: credSuffix,
      storedCounter,
      assertedCounter: newCounter,
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  // Success: bump counter, clear failure state, update lastUsedAt.
  await db.doc(`users/${uid}/webauthn/${credDoc.id}`).set(
    {
      counter: newCounter,
      lastUsedAt: FieldValue.serverTimestamp(),
      failedAttempts: 0,
      lockedUntil: null,
    },
    { merge: true },
  );
  await challengeRef.delete().catch(() => undefined);

  logger.info({
    event: 'webauthnAssertionFinish',
    uid,
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return { ok: true };
}

/**
 * Increment failedAttempts on the credential and set lockedUntil if a
 * threshold crosses. Returns the next lockedUntilMs (or null) so the
 * caller can surface it to the client.
 */
async function bumpFailedAttempts(
  db: ReturnType<typeof getFirestore>,
  uid: string,
  credentialDocId: string,
  current: number,
): Promise<{ next: number; lockedUntilMs: number | null }> {
  const next = current + 1;
  let lockedUntilMs: number | null = null;
  if (next >= HARD_LOCK_THRESHOLD) {
    lockedUntilMs = Date.now() + HARD_LOCK_MS;
  } else if (next >= SOFT_LOCK_THRESHOLD) {
    lockedUntilMs = Date.now() + SOFT_LOCK_MS;
  }
  await db.doc(`users/${uid}/webauthn/${credentialDocId}`).set(
    {
      failedAttempts: next,
      lockedUntil: lockedUntilMs !== null ? Timestamp.fromMillis(lockedUntilMs) : null,
    },
    { merge: true },
  );
  return { next, lockedUntilMs };
}

export const webauthnAssertionFinish = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    cors: false,
  },
  (req: CallableRequest<FinishRequest>) => {
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnAssertionFinish(req);
  },
);
