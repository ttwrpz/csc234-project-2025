// webauthnLoginFinish — UNAUTHENTICATED cold-boot sign-in, ceremony leg 2.
//
// Verifies a usernameless assertion produced by webauthnLoginStart and,
// on success, mints a Firebase custom token so the client can call
// `signInWithCustomToken`. This is the ONLY unauthenticated CF that mints
// a token, so it fails closed at every step.
//
// Flow:
//   1. Provisioning guard.
//   2. IP-keyed rate-limit (shared bucket with the start leg). Fails
//      closed when the source IP is unresolvable.
//   3. Pull `userHandle` from the assertion (the uid bytes set at
//      registration) and decode it to the uid string. Reject if absent.
//   4. ATOMICALLY claim (read + delete in one transaction) the single-use
//      GLOBAL challenge at webauthnLoginChallenges/{challengeId}. Claiming
//      before verification means two concurrent finishes can never both
//      consume the same challenge — closing the assertion-replay race that
//      would otherwise let one captured assertion mint two tokens.
//   5. Read the uid's registered credential (single-credential v1.5).
//      Honour the per-credential lockout ladder (failedAttempts /
//      lockedUntil) exactly as webauthnAssertionFinish does.
//   6. Bind the assertion to that credential: the asserted credential id
//      MUST equal the stored credentialId.
//   7. verifyAuthenticationResponse against the stored public key +
//      counter. Counter-regression → fail closed (ADR-0014 Decision B).
//   8. Confirm the uid is a live Firebase Auth user, then mint
//      admin.createCustomToken(uid).
//   9. On failure: bump failedAttempts + set lockedUntil on threshold.
//
// Privacy: pre-auth surface, so failure codes are deliberately OPAQUE —
// no_credential / credential_mismatch / bad-signature all collapse to
// `verification_failed`, and the per-credential lockout time is never
// returned to the unauthenticated caller (it would leak account
// existence + lockout state). PII discipline: logs include outcome +
// latencyMs only; never the uid, never credential material, never the
// minted token.
//
// CF posture: region asia-southeast1, 256MiB, 30s timeout,
// enforceAppCheck: false (matches the existing CF suite).

import { getAuth } from 'firebase-admin/auth';
import {
  getFirestore,
  FieldValue,
  Timestamp,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { verifyAuthenticationResponse } from '@simplewebauthn/server';

import { consumeToken } from './rateLimit.js';
import {
  LOGIN_CHALLENGE_COLLECTION,
  LOGIN_RATE_LIMIT_COLLECTION,
  LOGIN_RATE_LIMIT_MAX,
  LOGIN_RATE_LIMIT_WINDOW_MS,
  callerKey,
} from './webauthnLoginStart.js';
import {
  WEBAUTHN_PRODUCTION_ORIGIN,
  WEBAUTHN_RPID,
  WEBAUTHN_STAGING_ORIGINS,
  isProvisioned,
  resolveExpectedOrigins,
  resolveExpectedRpId,
} from './webauthnConstants.js';

// Lockout ladder mirrors the PIN + assertion sides.
const SOFT_LOCK_THRESHOLD = 5;
const SOFT_LOCK_MS = 60_000;
const HARD_LOCK_THRESHOLD = 10;
const HARD_LOCK_MS = 30 * 60_000;

interface FinishRequest {
  v?: number;
  challengeId?: unknown;
  response?: unknown;
}

export interface WebauthnLoginFinishResponse {
  ok: boolean;
  token?: string;
  code?: string;
}

/** Decode the base64url `userHandle` from the assertion into a uid. */
function uidFromUserHandle(assertion: Record<string, unknown>): string | null {
  const response = assertion.response as Record<string, unknown> | undefined;
  const raw = response?.userHandle;
  if (typeof raw !== 'string' || raw.length === 0) return null;
  try {
    const uid = Buffer.from(raw, 'base64url').toString('utf8');
    return uid.length > 0 ? uid : null;
  } catch {
    return null;
  }
}

function toMillis(v: { toMillis?: () => number } | Date | null | undefined): number | null {
  if (v instanceof Date) return v.getTime();
  if (typeof (v as { toMillis?: () => number } | null | undefined)?.toMillis === 'function') {
    return (v as { toMillis: () => number }).toMillis();
  }
  return null;
}

export async function handleWebauthnLoginFinish(
  request: CallableRequest<FinishRequest>,
): Promise<WebauthnLoginFinishResponse> {
  const startMs = Date.now();
  const db = getFirestore();

  const payload = request.data ?? {};
  const challengeId = typeof payload.challengeId === 'string' ? payload.challengeId : null;
  const assertion = payload.response as Record<string, unknown> | undefined;
  if (!challengeId || !assertion) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'invalid_argument',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  if (!isProvisioned()) {
    return { ok: false, code: 'webauthn_not_provisioned' };
  }
  const rpId = resolveExpectedRpId();
  if (rpId === null) {
    return { ok: false, code: 'webauthn_not_provisioned' };
  }

  // Rate-limit the finish leg too (shared IP bucket with the start leg);
  // fail closed when the IP is unresolvable. Without this the only throttle
  // on the token-mint surface would be the per-credential lockout, which an
  // attacker can only reach after guessing a valid uid.
  const key = callerKey(request);
  if (key === null) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'no_caller_ip',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'rate_limited' };
  }
  try {
    const rl = await consumeToken(key, Date.now(), {
      windowMs: LOGIN_RATE_LIMIT_WINDOW_MS,
      max: LOGIN_RATE_LIMIT_MAX,
      collection: LOGIN_RATE_LIMIT_COLLECTION,
    });
    if (!rl.allowed) {
      logger.info({
        event: 'webauthnLoginFinish',
        outcome: 'rate_limited',
        latencyMs: Date.now() - startMs,
      });
      return { ok: false, code: 'rate_limited' };
    }
  } catch (e) {
    logger.error({
      event: 'webauthnLoginFinish',
      outcome: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return { ok: false, code: 'internal' };
  }

  const uid = uidFromUserHandle(assertion);
  if (uid === null) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'no_user_handle',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  // Atomically CLAIM the single-use challenge: read + delete inside one
  // transaction so concurrent finishes can't both consume it. The delete
  // happens whether or not the doc is valid, so a replayed challenge is
  // burned on first touch.
  const challengeRef = db.doc(`${LOGIN_CHALLENGE_COLLECTION}/${challengeId}`);
  let expectedChallenge: string | null;
  try {
    expectedChallenge = await db.runTransaction(async (tx) => {
      const snap = await tx.get(challengeRef);
      if (!snap.exists) return null;
      const data = snap.data() as
        | { challenge?: string; purpose?: string; expiresAt?: { toMillis(): number } | Date }
        | undefined;
      // Single-use: claim by deleting now, even on a reject path.
      tx.delete(challengeRef);
      const expiresMs = toMillis(data?.expiresAt) ?? 0;
      if (!expiresMs || expiresMs < Date.now() || data?.purpose !== 'login') {
        return null;
      }
      const challenge = data?.challenge;
      if (typeof challenge !== 'string' || challenge.length === 0) return null;
      return challenge;
    });
  } catch (e) {
    logger.error({
      event: 'webauthnLoginFinish',
      outcome: 'challenge_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return { ok: false, code: 'internal' };
  }
  if (expectedChallenge === null) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'challenge_expired',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'challenge_expired' };
  }

  // Read the uid's registered credential.
  const credSnap = await db.collection(`users/${uid}/webauthn`).limit(1).get();
  const credDoc = credSnap.docs[0];
  if (credSnap.empty || !credDoc) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'no_credential',
      latencyMs: Date.now() - startMs,
    });
    // Opaque on the wire — do not reveal account existence pre-auth.
    return { ok: false, code: 'verification_failed' };
  }
  const credData = credDoc.data() as {
    credentialId?: string;
    publicKeyBase64?: string;
    counter?: number;
    transports?: string[];
    failedAttempts?: number;
    lockedUntil?: { toMillis(): number } | Date | null;
  };

  const lockedUntilMs = toMillis(credData.lockedUntil);
  if (lockedUntilMs !== null && lockedUntilMs > Date.now()) {
    // Locked — surface only the coarse code, never the unlock time (would
    // leak account-existence + lockout timing to an unauthenticated caller).
    return { ok: false, code: 'rate_limited' };
  }

  const credentialId =
    typeof credData.credentialId === 'string' ? credData.credentialId : credDoc.id;
  // Bind the assertion to the stored credential — reject an assertion that
  // names a different credential id than the one we hold for this uid.
  const assertedId = typeof assertion.id === 'string' ? assertion.id : null;
  if (assertedId !== null && assertedId !== credentialId) {
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'credential_mismatch',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }
  const storedPublicKey = credData.publicKeyBase64 ?? '';
  const storedCounter = typeof credData.counter === 'number' ? credData.counter : 0;
  if (storedPublicKey.length === 0) {
    return { ok: false, code: 'verification_failed' };
  }
  const publicKeyBytes = new Uint8Array(Buffer.from(storedPublicKey, 'base64'));
  const transports = Array.isArray(credData.transports)
    ? credData.transports.filter((t): t is string => typeof t === 'string')
    : [];

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
    await bumpFailedAttempts(db, uid, credDoc.id, credData.failedAttempts ?? 0);
    logger.warn({
      event: 'webauthnLoginFinish',
      outcome: 'verification_threw',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  if (!verification.verified || !verification.authenticationInfo) {
    const next = await bumpFailedAttempts(db, uid, credDoc.id, credData.failedAttempts ?? 0);
    logger.info({
      event: 'webauthnLoginFinish',
      outcome: 'verification_failed',
      latencyMs: Date.now() - startMs,
    });
    // Coarse code only — no lockout time on the wire.
    return {
      ok: false,
      code: next.lockedUntilMs !== null ? 'rate_limited' : 'verification_failed',
    };
  }

  const newCounter = verification.authenticationInfo.newCounter ?? 0;
  if (storedCounter > 0 && newCounter <= storedCounter) {
    await bumpFailedAttempts(db, uid, credDoc.id, credData.failedAttempts ?? 0);
    const credSuffix = credentialId.length >= 8
      ? credentialId.slice(credentialId.length - 8)
      : credentialId;
    logger.warn({
      event: 'webauthn.counter_regression',
      credentialIdSuffix: credSuffix,
      storedCounter,
      assertedCounter: newCounter,
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  // Success: persist counter + clear failure state. (The challenge was
  // already deleted atomically in the claim transaction above.)
  await db.doc(`users/${uid}/webauthn/${credDoc.id}`).set(
    {
      counter: newCounter,
      lastUsedAt: FieldValue.serverTimestamp(),
      failedAttempts: 0,
      lockedUntil: null,
    },
    { merge: true },
  );

  // Confirm the resolved uid is a live Firebase Auth account before minting
  // — guards against a stale credential doc for a deleted user being able
  // to mint a token for an orphaned uid.
  try {
    await getAuth().getUser(uid);
  } catch (e) {
    logger.warn({
      event: 'webauthnLoginFinish',
      outcome: 'auth_user_missing',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'verification_failed' };
  }

  let token: string;
  try {
    token = await getAuth().createCustomToken(uid);
  } catch (e) {
    logger.error({
      event: 'webauthnLoginFinish',
      outcome: 'mint_failed',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    return { ok: false, code: 'internal' };
  }

  logger.info({
    event: 'webauthnLoginFinish',
    outcome: 'success',
    latencyMs: Date.now() - startMs,
  });

  return { ok: true, token };
}

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

export const webauthnLoginFinish = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    // CORS open for browser callers; the real origin gate is the
    // `expectedOrigin` check inside verifyAuthenticationResponse.
    cors: true,
  },
  (req: CallableRequest<FinishRequest>) => {
    void WEBAUTHN_PRODUCTION_ORIGIN.value();
    void WEBAUTHN_STAGING_ORIGINS.value();
    void WEBAUTHN_RPID.value();
    return handleWebauthnLoginFinish(req);
  },
);
