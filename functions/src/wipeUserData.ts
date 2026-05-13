/**
 * wipeUserData — server-side data cascade for account deletion.
 *
 * Used by:
 *   (a) Settings → Account → Delete account (WBS 2.4 / cb2f623c) — the
 *       production user-initiated cascade. The client
 *       (DeleteAccountFunctionsDatasource) invokes this CF, then calls
 *       FirebaseAuth.currentUser.delete() to revoke the Auth record
 *       client-side. See ADR-0009 for the topology rationale.
 *   (b) Settings → Debug → Wipe data (kDebugMode) — developer tool for
 *       resetting test accounts without the Auth-side delete.
 *
 * Cascade order (ADR-0009 §"Decision"):
 *   1. Firestore: drain every users/{uid}/** subcollection + reset the
 *      user-profile doc fields. Bypasses the immutability rules via the
 *      admin SDK — this is the only path to delete 24h-locked moods.
 *   2. Storage: bucket.deleteFiles({prefix: 'users/{uid}/media/'}).
 *   3. Auth: handled CLIENT-SIDE post-CF via currentUser.delete(). Not in
 *      this function — see AuthRepositoryImpl.deleteCurrentUser.
 *   4. Rate-limit docs: best-effort delete of the four per-uid docs (one
 *      per CF; see rateLimit.ts for the collection-name set).
 *
 * Idempotency: re-running on an already-deleted uid returns
 * {ok: true, alreadyDeleted: true} without doing any work. See ADR-0009
 * §"Good" point 5 for the rationale.
 *
 * PII discipline: logs include uid (allowed per ADR-0003) and counts
 * only. Never log mood text, Storage object names, FCM tokens, or any
 * doc payload.
 *
 * Callable contract:
 *   onCall(request) →
 *     { ok: true, alreadyDeleted: false, deleted: { moods: 12, ... } }
 *     | { ok: true, alreadyDeleted: true }
 *   throws HttpsError('unauthenticated') if not signed in.
 */

import { logger } from 'firebase-functions';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

/**
 * Subcollections under `users/{uid}/` that are drained. The order is
 * stable + alphabetised so the structured log line below renders
 * deterministically across runs.
 */
const SUBCOLLECTIONS = [
  'cheerUpEvents',
  'cooldowns',
  'insights',
  'interventionState',
  'interventions',
  'moods',
  'patterns',
  'settings',
  'weeklyGardens',
] as const;

/**
 * Per-uid rate-limit doc collections — one per Cloud Function that
 * consumes a token (analyzeMoodText, analyzePatterns, sendCheerUpPush,
 * suggestQuote). The cleanup step delete()s `{collection}/{uid}` on each
 * best-effort. Firestore TTL on `expireAt` would reap these on its own,
 * but the inline pass is tidier and gives the user a clean slate at the
 * moment of deletion.
 */
const RATE_LIMIT_COLLECTIONS = [
  'rateLimits',
  'rateLimits.patterns',
  'rateLimits.cheerUp',
  'rateLimits.suggestQuote',
] as const;

type Deleted = Record<(typeof SUBCOLLECTIONS)[number], number>;

export type WipeOutcome =
  | {
      ok: true;
      alreadyDeleted: true;
    }
  | {
      ok: true;
      alreadyDeleted: false;
      deleted: Deleted;
      mediaDeletedCount: number;
      rateLimitDeletedCount: number;
    };

/**
 * Handler split out from `onCall` so the unit-test harness can invoke it
 * directly (mirrors the suggestQuote / analyzeMoodText pattern).
 */
export async function handleWipeUserData(
  request: CallableRequest,
): Promise<WipeOutcome> {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError(
      'unauthenticated',
      'Sign in before calling wipeUserData.',
    );
  }
  const uid = auth.uid;
  const db = getFirestore();

  // Idempotency check — per ADR-0009 §"Decision" line ~16. If the
  // user-profile doc is absent AND the moods subcollection is empty,
  // treat as a re-run on a cleaned account and return early. This
  // distinguishes the "first run" log line from the "second invocation,
  // nothing to do" line.
  const profileSnap = await db.doc(`users/${uid}`).get();
  if (!profileSnap.exists) {
    // Spot-check one subcollection to confirm the cleaned state. Using
    // moods because it's the largest and most likely to have stragglers
    // surviving a partially-completed first run.
    const moodsSnap = await db.collection(`users/${uid}/moods`).limit(1).get();
    if (moodsSnap.empty) {
      logger.info({ event: 'wipeUserData.alreadyDeleted', uid });
      return { ok: true, alreadyDeleted: true };
    }
  }

  const deleted: Record<string, number> = {};

  // 1. Firestore subcollection drain — batches of 500 (Firestore batch
  // hard limit). Empty subcollections fall through cheaply. Errors abort
  // the wipe and surface to the client; the partial state is acceptable
  // because the function is idempotent (see check above).
  for (const name of SUBCOLLECTIONS) {
    const colRef = db.collection(`users/${uid}/${name}`);
    let count = 0;
    // Drain in batches of 500 docs.
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const snap = await colRef.limit(500).get();
      if (snap.empty) break;
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      count += snap.size;
      if (snap.size < 500) break;
    }
    deleted[name] = count;
  }

  // 2. Storage prefix delete — per ADR-0009 §"Decision" cascade order
  //    (Firestore → Storage → Auth → rate-limit cleanup). The
  //    `bucket.deleteFiles({prefix})` call walks every object under the
  //    prefix in one pass and is best-effort against eventual-consistency
  //    reads (a race between the cascade and a late upload may survive
  //    into the next batch; the function's idempotency contract makes
  //    this a non-issue — re-run cleans the survivor).
  //
  //    `@google-cloud/storage` ^7.x types deleteFiles({prefix}) as
  //    `Promise<void>` (see bucket.d.ts line ~689). To produce a count
  //    for the log we list first via getFiles({prefix}), then delete.
  //    Cost is acceptable — bounded by user account size.
  let mediaDeletedCount = 0;
  try {
    const bucket = getStorage().bucket();
    const prefix = `users/${uid}/media/`;
    const [files] = await bucket.getFiles({ prefix });
    mediaDeletedCount = files.length;
    await bucket.deleteFiles({ prefix, force: true });
  } catch (e) {
    // Best-effort cleanup. Log without object names (PII-canary
    // discipline — Storage object paths may include user-selected
    // identifiers) and continue — Storage SDK errors should not block
    // the rest of the cascade. The Auth-side delete happens client-side
    // anyway.
    logger.warn({
      event: 'wipeUserData.storage',
      uid,
      errorName: e instanceof Error ? e.name : 'Unknown',
    });
  }

  // 3. Reset the user-profile-doc fields the app populates as the user
  //    logs moods. Keep displayName / email / photoUrl / createdAt —
  //    those identify the account and survive the wipe. `set(merge:
  //    true)` so we don't clobber any future fields the schema may add.
  //
  //    For the (a) production account-deletion path the FirebaseAuth
  //    user is deleted by the client AFTER this CF returns, which would
  //    in practice also orphan this profile doc. For the (b) debug-reset
  //    path the profile doc must stay so the user remains usable. The
  //    reset is the union that satisfies both callsites.
  await db.doc(`users/${uid}`).set(
    {
      tokenBalance: 0,
      tokensEarnedToday: 0,
      lastTokenEarnedDate: null,
      unlockedSkins: {},
      gardenSettings: {},
      insightsDisclaimerAcked: false,
    },
    { merge: true },
  );

  // 4. Rate-limit doc cleanup — per ADR-0009 §"Decision" step 4.
  //    Best-effort; the docs have Firestore TTL set in the console so
  //    they'd reap on their own within the window, but inline cleanup is
  //    tidier. The four collections (one per CF) mirror the namespaces
  //    used by analyzeMoodText (`rateLimits`), analyzePatterns
  //    (`rateLimits.patterns`), sendCheerUpPush (`rateLimits.cheerUp`),
  //    and suggestQuote (`rateLimits.suggestQuote`).
  let rateLimitDeletedCount = 0;
  for (const coll of RATE_LIMIT_COLLECTIONS) {
    try {
      await db.collection(coll).doc(uid).delete();
      rateLimitDeletedCount++;
    } catch {
      // Not-found is fine; admin SDK delete is idempotent. Other errors
      // are best-effort — the doc has TTL and will reap on its own.
    }
  }

  logger.info({
    event: 'wipeUserData',
    uid,
    deleted,
    mediaDeletedCount,
    rateLimitDeletedCount,
  });

  return {
    ok: true,
    alreadyDeleted: false,
    deleted: deleted as Deleted,
    mediaDeletedCount,
    rateLimitDeletedCount,
  };
}

export const wipeUserData = onCall(
  {
    // Match the region used by the rest of the project's callables
    // (`firebaseFunctionsProvider` instantiates
    // `FirebaseFunctions.instanceFor(region: 'asia-southeast1')`). A
    // mismatch surfaces to the client as `not-found` because the SDK
    // looks up the function in its configured region only.
    region: 'asia-southeast1',
    timeoutSeconds: 540,
    memory: '512MiB',
    // enforceAppCheck deferred: the v1.5 cohort matches the
    // project-wide posture (analyzeMoodText, sendCheerUpPush,
    // suggestQuote all leave enforceAppCheck unset / false because the
    // Flutter-web client has not yet wired
    // `firebase_app_check.activate(...)`). Re-enable site-wide in v1.6
    // alongside the web App Check init. See analyzeMoodText.ts:307-321
    // for the same precedent.
  },
  handleWipeUserData,
);
