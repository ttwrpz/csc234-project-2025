// Debug-only Cloud Function that wipes the caller's user-data
// subcollections + resets the user-profile-doc fields, while
// preserving the auth account itself (FirebaseAuth user stays
// signed in, displayName/email/photoUrl untouched). Surfaced via
// the Settings → Debug "Wipe all account data" tile (kDebugMode
// gated on the client) per the v1.0 polish round (2026-05-10).
//
// Callable contract:
//   onCall(request) → { ok: true, deleted: { moods: 12, ... } }
//   throws HttpsError('unauthenticated') if not signed in.
//
// Why a Cloud Function (not client-side Firestore deletes):
// most of the user's subcollection rules deny client deletes —
// `cheerUpEvents`, `interventionState`, `patterns`, `weeklyGardens`,
// `settings/notifications`, `interventions`, `cooldowns` are all
// `delete: if false`. Trying to wipe from the client would 403 on
// most of them. Admin SDK bypasses rules, so this function does
// the full sweep server-side.
//
// What this function does NOT do:
//  - It does NOT delete the FirebaseAuth user. The user stays
//    signed in. ADR-0009 owns the full account-deletion flow;
//    this is a debug reset only.
//  - It does NOT touch `users/{uid}.displayName`, `email`,
//    `photoUrl`, `createdAt`. Those identify the account and
//    survive the wipe.
//  - It does NOT clear the local Drift cache or SharedPreferences
//    on the calling device — that's the client's job, run after
//    this CF returns.
//
// PII fence: the structured log emits only the uid (allowed —
// audit trail) and the per-collection delete counts. No mood text,
// no entry ids, no doc payloads.

import { logger } from 'firebase-functions';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

/**
 * Subcollections under `users/{uid}/` that are wiped. The order is
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

type WipeOutcome = {
  ok: true;
  deleted: Record<(typeof SUBCOLLECTIONS)[number], number>;
};

export const wipeUserData = onCall<unknown, Promise<WipeOutcome>>(
  // Match the region used by the rest of the project's callables
  // (`firebaseFunctionsProvider` instantiates `FirebaseFunctions.instanceFor(
  // region: 'asia-southeast1')`). A mismatch surfaces to the client
  // as `not-found` because the SDK looks up the function in its
  // configured region only.
  { region: 'asia-southeast1' },
  async (request: CallableRequest): Promise<WipeOutcome> => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError(
        'unauthenticated',
        'Sign in before calling wipeUserData.',
      );
    }
    const uid = auth.uid;
    const db = getFirestore();

    const deleted: Record<string, number> = {};

    // Delete every doc under each known subcollection in batches of
    // 500 (Firestore batch hard limit). Empty subcollections fall
    // through cheaply. Errors abort the wipe and surface to the
    // client; the partial state is acceptable for a debug reset.
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

    // Reset the user-profile-doc fields the app populates as the
    // user logs moods. Keep displayName / email / photoUrl /
    // createdAt — those identify the account and survive the wipe.
    // `set(merge: true)` so we don't clobber any future fields the
    // schema may add.
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

    logger.info('wipeUserData', {
      uid,
      deleted,
    });

    return { ok: true, deleted: deleted as WipeOutcome['deleted'] };
  },
);
