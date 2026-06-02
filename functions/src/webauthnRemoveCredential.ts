// webauthnRemoveCredential - Cloud Function callable that retires the
// user's registered WebAuthn credential(s).
//
// The credential doc at users/{uid}/webauthn/{credentialId} is admin-SDK
// owned (firestore.rules denies all client writes), so removal cannot be a
// client-side delete - it goes through this authenticated callable.
//
// Authorization: a valid Firebase session (request.auth.uid) is the server
// boundary. The client performs a step-up re-auth (security key, PIN,
// biometric, or password) BEFORE invoking this - PIN and biometric are
// client-only secrets the server cannot verify, matching how the Privacy
// Lock already treats them. Removal only ever weakens auth (it drops a
// fallback factor), so it never grants access; the existing session plus
// the client re-auth gate is the appropriate bar.
//
// Idempotent: deleting when no credential exists returns { ok: true,
// removed: 0 } so a double-tap or a retry after a partial failure is safe.
//
// PII discipline: logs include uid + outcome + removed-count + latencyMs
// only. Never the credentialId (a stable per-user identifier).
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

export interface WebauthnRemoveCredentialResponse {
  ok: boolean;
  removed?: number;
  code?: string;
}

export async function handleWebauthnRemoveCredential(
  request: CallableRequest<unknown>,
): Promise<WebauthnRemoveCredentialResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();
  const db = getFirestore();

  let removed = 0;
  try {
    const col = db.collection(`users/${uid}/webauthn`);
    const snap = await col.get();
    if (!snap.empty) {
      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      removed = snap.size;
    }
  } catch (e) {
    logger.error({
      event: 'webauthnRemoveCredential',
      uid,
      outcome: 'delete_failed',
      cause: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    });
    throw new HttpsError('internal', 'internal-error');
  }

  logger.info({
    event: 'webauthnRemoveCredential',
    uid,
    outcome: 'success',
    removed,
    latencyMs: Date.now() - startMs,
  });

  return { ok: true, removed };
}

export const webauthnRemoveCredential = onCall(
  {
    region: 'asia-southeast1',
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
    secrets: [],
    // CORS open for browser callers; the callable still requires a valid
    // Firebase ID token (request.auth.uid), so origin spoofing alone gains
    // no access.
    cors: true,
  },
  handleWebauthnRemoveCredential,
);
