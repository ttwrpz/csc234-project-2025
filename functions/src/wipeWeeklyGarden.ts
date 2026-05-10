// Debug-only Cloud Function that deletes a SINGLE
// `users/{uid}/weeklyGardens/{weekId}` archive doc. Surfaced via the
// Settings → Debug "Force harvest now" button so the demo can replay
// the harvest flow without first wiping every mood entry.
//
// Callable contract:
//   onCall({ weekId?: string }) → { ok: true, deleted: bool, weekId: string|null }
//   throws HttpsError('unauthenticated') if not signed in.
//
// When `weekId` is omitted, the function deletes the most recently
// archived week (by `archivedAt` desc). When `weekId` is provided,
// it deletes that exact doc (or no-ops if it doesn't exist).
//
// Why a Cloud Function (not client-side delete):
// `weeklyGardens/{weekId}` rules are `delete: if false` — the archive
// is meant to be immutable in production. The debug Force-Harvest
// flow needs to bypass that for replay. Admin SDK on the server
// bypasses rules cleanly; the client cannot.
//
// PII fence: the structured log emits only the uid + weekId. No
// entry ids, no mood text.

import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

type WipeRequest = { weekId?: string };

type WipeOutcome = {
  ok: true;
  deleted: boolean;
  weekId: string | null;
};

export const wipeWeeklyGarden = onCall<WipeRequest, Promise<WipeOutcome>>(
  { region: 'asia-southeast1' },
  async (request: CallableRequest<WipeRequest>): Promise<WipeOutcome> => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError(
        'unauthenticated',
        'Sign in before calling wipeWeeklyGarden.',
      );
    }
    const uid = auth.uid;
    const db = getFirestore();
    const colRef = db.collection(`users/${uid}/weeklyGardens`);

    const requestedWeekId = request.data?.weekId;
    let weekId: string | null = null;

    if (requestedWeekId && /^\d{4}-W\d{2}$/.test(requestedWeekId)) {
      weekId = requestedWeekId;
    } else {
      // No weekId provided → delete the most recently archived week.
      // The collection is indexed by `archivedAt` (used by
      // `watchHistory` already), so this single read is cheap.
      const snap = await colRef
        .orderBy('archivedAt', 'desc')
        .limit(1)
        .get();
      const top = snap.docs[0];
      if (top) {
        weekId = top.id;
      }
    }

    if (weekId == null) {
      logger.info('wipeWeeklyGarden', { uid, weekId: null, deleted: false });
      return { ok: true, deleted: false, weekId: null };
    }

    const docRef = colRef.doc(weekId);
    const existing = await docRef.get();
    if (!existing.exists) {
      logger.info('wipeWeeklyGarden', { uid, weekId, deleted: false });
      return { ok: true, deleted: false, weekId };
    }

    await docRef.delete();
    logger.info('wipeWeeklyGarden', { uid, weekId, deleted: true });
    return { ok: true, deleted: true, weekId };
  },
);
