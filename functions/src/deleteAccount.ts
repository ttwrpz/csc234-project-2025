// onCall handler implementing the server-side account-deletion cascade
// from HB-004 + ADR-0009. Strategy:
//   1. Auth check — throw HttpsError('unauthenticated') for the
//      no-auth case (no requestId echoing here; an unauth caller has
//      no trustworthy correlation id).
//   2. Idempotency probe — if the root user doc is absent AND the auth
//      user is absent, treat the uid as already-deleted and return
//      `{ ok: true, alreadyDeleted: true }` without exception.
//   3. Cascade order: children before parents, Storage before root,
//      Auth last (deleting the auth user revokes the caller's token,
//      so any Firestore write after that step would fail with
//      `permission-denied`). `db.recursiveDelete()` walks every
//      sub-collection under `users/{uid}` in one pass; the explicit
//      list in HB-004 §"deleteAccount Cloud Function — contract" steps
//      1-6 is captured by that single call.
//   4. Logger allowlist (ADR-0003 + HB-004 §"Logger allowlist"):
//      `event, requestId, uid, outcome, latencyTotalMs, errorReason`.
//      No user-document fields, no Storage object names beyond the
//      `users/{uid}/media/` prefix, no token strings.
//   5. Best-effort cleanup of per-uid rate-limit docs via
//      `Promise.allSettled` so a missing doc cannot fail the cascade.

import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';

interface DeleteAccountResponse {
  ok: true;
  alreadyDeleted: boolean;
  requestId: string;
  v: 1;
}

function extractRequestId(data: unknown): string {
  if (
    typeof data === 'object' &&
    data !== null &&
    'requestId' in data &&
    typeof (data as { requestId?: unknown }).requestId === 'string'
  ) {
    return (data as { requestId: string }).requestId;
  }
  return 'unknown';
}

/**
 * Core handler — exported for tests so they can call it directly without
 * going through `firebase-functions-test`'s wrap layer. Mirrors the
 * pattern used by `analyzeMoodText` / `analyzePatterns`.
 */
export async function handleDeleteAccount(
  request: CallableRequest<unknown>,
): Promise<DeleteAccountResponse> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const requestId = extractRequestId(request.data);
  const startMs = Date.now();
  const db = getFirestore();
  const bucket = getStorage().bucket();

  // Idempotency probe — both root doc and auth user must be absent
  // before we short-circuit. A prior crashed run could have removed
  // the auth user but left Firestore docs around (or vice versa); in
  // those partial-state cases the cascade still has work to do.
  const rootRef = db.doc(`users/${uid}`);
  const rootSnap = await rootRef.get();
  let authUserExists = true;
  try {
    await getAuth().getUser(uid);
  } catch {
    authUserExists = false;
  }
  if (!rootSnap.exists && !authUserExists) {
    logger.info({
      event: 'deleteAccount',
      requestId,
      uid,
      outcome: 'already_deleted',
      latencyTotalMs: Date.now() - startMs,
    });
    return { ok: true, alreadyDeleted: true, requestId, v: 1 };
  }

  // Steps 1-6 + 8 (per HB-004): a single recursiveDelete on the user
  // root walks every sub-collection. Adding a new sub-collection in
  // a future sprint does not require a CF edit unless the collection's
  // data lifecycle differs from "owned by the user".
  await db.recursiveDelete(rootRef);

  // Step 7: Storage media. listFiles is paginated; deleteFiles({prefix})
  // handles iteration internally.
  await bucket.deleteFiles({ prefix: `users/${uid}/media/` });

  // Step 9: Auth user. Catch user-not-found (race with a concurrent
  // delete or an admin-console manual delete). Any other Firebase Auth
  // error rethrows so the client sees `internal` and can retry.
  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code !== 'auth/user-not-found') {
      logger.error({
        event: 'deleteAccount',
        requestId,
        uid,
        outcome: 'auth_delete_failed',
        errorReason: code ?? 'unknown',
        latencyTotalMs: Date.now() - startMs,
      });
      throw e;
    }
  }

  // Step 10: per-uid rate-limit docs. Best-effort — a missing doc is
  // not a cascade failure.
  await Promise.allSettled([
    db.doc(`rateLimits/${uid}`).delete(),
    db.doc(`rateLimits/cheerUp/${uid}`).delete(),
    db.doc(`rateLimits.patterns/${uid}`).delete(),
  ]);

  logger.info({
    event: 'deleteAccount',
    requestId,
    uid,
    outcome: 'deleted',
    latencyTotalMs: Date.now() - startMs,
  });

  return { ok: true, alreadyDeleted: false, requestId, v: 1 };
}

/**
 * Exported v2 callable. Region matches the rest of the project; memory
 * is small (the work is I/O, not CPU) but timeout is generous to
 * accommodate users with thousands of mood entries — `recursiveDelete`
 * on a 5,000-mood account costs ~30s in practice; the 540s ceiling
 * tolerates pathological data sizes (HB-004 §"deleteAccount Cloud
 * Function — contract").
 *
 * `enforceAppCheck: true` aligns with `analyzePatterns` and ADR-0003;
 * the destructive nature of this CF makes App Check mandatory rather
 * than the "off for the demo" posture used by `analyzeMoodText`.
 */
export const deleteAccount = onCall(
  {
    region: 'asia-southeast1',
    enforceAppCheck: true,
    memory: '256MiB',
    timeoutSeconds: 540,
  },
  handleDeleteAccount,
);
