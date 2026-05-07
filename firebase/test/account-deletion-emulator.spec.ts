/**
 * Account-deletion E2E — emulator-driven (HB-004 §"E2E").
 *
 * Boots against Firestore + Auth + Storage emulators (started by
 * `firebase emulators:exec`). Seeds a real Auth user, full Firestore
 * subtree, Storage media, and per-uid rate-limit docs; runs the
 * server cascade (mirroring `functions/src/deleteAccount.ts`); asserts
 * every byte of the user's data is gone afterwards.
 *
 * Why we mirror the cascade here rather than calling the deployed CF
 * via `httpsCallable`:
 *   - The Functions emulator is not part of the rules-test setup
 *     (`firebase/test/jest.config.js` runs Firestore + Storage only).
 *   - `enforceAppCheck: true` on the production CF would refuse a
 *     test client that has no App Check token, so a `httpsCallable`
 *     test would either need App Check disabled (which weakens the
 *     security posture under test) or a debug token plumbed through
 *     env (which adds CI complexity).
 *   - The handler-level wire path (auth gate, idempotency, error
 *     mapping, logger allowlist) is fully covered by
 *     `functions/src/__tests__/deleteAccount.test.ts`.
 *
 * What this E2E proves:
 *   - `db.recursiveDelete(users/{uid})` clears every sub-collection
 *     against a real Firestore emulator, including ones added by
 *     future sprints that aren't named here explicitly.
 *   - `bucket.deleteFiles({prefix})` against a real Storage emulator
 *     removes all media objects.
 *   - `getAuth().deleteUser(uid)` against a real Auth emulator removes
 *     the user; subsequent `getUser(uid)` throws `auth/user-not-found`.
 *   - The `Promise.allSettled` rate-limit cleanup wipes the three
 *     known rate-limit doc paths.
 *
 * Run locally:
 *   firebase emulators:exec --only firestore,storage,auth \
 *     "cd firebase/test && pnpm test"
 */

import * as admin from "firebase-admin";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const PROJECT_ID = "moodbloom-deletion-e2e";
const TEST_EMAIL = "deletion-target@example.com";
const TEST_PASSWORD = "test-password-1234";

// Emulator hosts (default firebase.json ports).
const FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const AUTH_EMULATOR_HOST = "127.0.0.1:9099";
const STORAGE_EMULATOR_HOST = "127.0.0.1:9199";

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

let app: admin.app.App;

beforeAll(() => {
  process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;
  process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
  // firebase-admin reads STORAGE_EMULATOR_HOST as a full URL.
  process.env.STORAGE_EMULATOR_HOST = `http://${STORAGE_EMULATOR_HOST}`;

  app = admin.initializeApp({
    projectId: PROJECT_ID,
    storageBucket: `${PROJECT_ID}.appspot.com`,
  });
});

afterAll(async () => {
  await app.delete();
});

beforeEach(async () => {
  // Wipe Firestore between cases — the rules-test suite does the
  // same. We do this with admin-SDK paths because we're not in a
  // RulesTestEnvironment here.
  const db = admin.firestore();
  // Clear known top-level collections we touch.
  for (const coll of ["users", "rateLimits"]) {
    const snap = await db.collection(coll).listDocuments();
    await Promise.all(snap.map((d) => db.recursiveDelete(d)));
  }
  // Clear the auth emulator (clean slate).
  const auth = admin.auth();
  // listUsers is paginated; for a test that creates at most one user
  // per case, a single page is fine.
  const list = await auth.listUsers();
  await Promise.all(list.users.map((u) => auth.deleteUser(u.uid)));

  // Clear Storage emulator media.
  try {
    await admin.storage().bucket().deleteFiles({ prefix: "users/" });
  } catch {
    // Bucket may not exist on first run — emulator auto-creates on first
    // upload below.
  }
});

// ---------------------------------------------------------------------------
// Cascade — direct mirror of functions/src/deleteAccount.ts core
// (handleDeleteAccount). Kept inline because cross-package ESM imports
// from this CommonJS test runner are non-trivial; the unit-test suite
// covers the handler wrapper, and this file proves the cascade
// against real emulators.
// ---------------------------------------------------------------------------

async function runDeletionCascade(uid: string): Promise<{ alreadyDeleted: boolean }> {
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  const rootRef = db.doc(`users/${uid}`);
  const rootSnap = await rootRef.get();
  let authUserExists = true;
  try {
    await admin.auth().getUser(uid);
  } catch {
    authUserExists = false;
  }
  if (!rootSnap.exists && !authUserExists) {
    return { alreadyDeleted: true };
  }

  await db.recursiveDelete(rootRef);
  await bucket.deleteFiles({ prefix: `users/${uid}/media/` });

  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code !== "auth/user-not-found") {
      throw e;
    }
  }

  await Promise.allSettled([
    db.doc(`rateLimits/${uid}`).delete(),
    db.doc(`rateLimits/cheerUp/${uid}`).delete(),
    db.doc(`rateLimits.patterns/${uid}`).delete(),
  ]);

  return { alreadyDeleted: false };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function seedFullUserState(): Promise<string> {
  // Real Auth user via the Auth emulator.
  const userRecord = await admin.auth().createUser({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });
  const uid = userRecord.uid;

  const db = admin.firestore();
  await db.doc(`users/${uid}`).set({
    displayName: "Deletion Target",
    photoUrl: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // Three mood docs.
  for (let i = 1; i <= 3; i++) {
    await db.doc(`users/${uid}/moods/m${i}`).set({
      mood: "happy",
      intensity: i,
      text: `entry ${i}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      mediaRefs: [],
    });
  }
  // One insights doc.
  await db.doc(`users/${uid}/insights/i1`).set({
    window: "30d",
    text: "test pattern",
    confidence: 0.7,
    sampleSize: 30,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // One cheerUpEvents doc.
  await db.doc(`users/${uid}/cheerUpEvents/e1`).set({
    reason: "5_of_7_negative",
    triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // Settings doc with two FCM tokens.
  await db.doc(`users/${uid}/settings/notifications`).set({
    tokens: ["token-aaaaa", "token-bbbbb"],
    enabled: true,
  });

  // Three Storage objects under users/{uid}/media/.
  const bucket = admin.storage().bucket();
  for (let i = 1; i <= 3; i++) {
    const file = bucket.file(`users/${uid}/media/photo${i}.jpg`);
    await file.save(Buffer.from("test-image-bytes"), {
      contentType: "image/jpeg",
    });
  }

  // Three rate-limit docs.
  await db.doc(`rateLimits/${uid}`).set({ windowStartMs: 0, count: 0 });
  await db.doc(`rateLimits/cheerUp/${uid}`).set({ count: 0 });
  await db.doc(`rateLimits.patterns/${uid}`).set({ count: 0 });

  return uid;
}

async function listUserDocs(uid: string): Promise<string[]> {
  // Recursively walk users/{uid} collecting every doc path. We can't
  // rely on a single recursive-list API in firebase-admin, so we do a
  // BFS on listCollections + listDocuments.
  const db = admin.firestore();
  const out: string[] = [];

  async function walk(parent: admin.firestore.DocumentReference): Promise<void> {
    const snap = await parent.get();
    if (snap.exists) out.push(parent.path);
    const colls = await parent.listCollections();
    for (const coll of colls) {
      const docs = await coll.listDocuments();
      for (const d of docs) {
        await walk(d);
      }
    }
  }

  await walk(db.doc(`users/${uid}`));
  return out;
}

async function listUserMedia(uid: string): Promise<string[]> {
  const [files] = await admin.storage().bucket().getFiles({ prefix: `users/${uid}/media/` });
  return files.map((f) => f.name);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("account deletion — emulator E2E (HB-004 case 13)", () => {
  it("seeds full user state, runs cascade, all paths empty + auth gone", async () => {
    const uid = await seedFullUserState();

    // Sanity check: seeding actually wrote everything we expect.
    const beforeDocs = await listUserDocs(uid);
    expect(beforeDocs.length).toBeGreaterThanOrEqual(7);
    const beforeMedia = await listUserMedia(uid);
    expect(beforeMedia.length).toBe(3);
    const userBefore = await admin.auth().getUser(uid);
    expect(userBefore.uid).toBe(uid);

    // Run the cascade.
    const result = await runDeletionCascade(uid);
    expect(result.alreadyDeleted).toBe(false);

    // Firestore — every doc under users/{uid} is gone.
    const afterDocs = await listUserDocs(uid);
    expect(afterDocs).toEqual([]);

    // Storage — no media objects under users/{uid}/media/.
    const afterMedia = await listUserMedia(uid);
    expect(afterMedia).toEqual([]);

    // Auth — getUser throws.
    let authThrew = false;
    try {
      await admin.auth().getUser(uid);
    } catch (e) {
      authThrew = true;
      expect((e as { code?: string }).code).toBe("auth/user-not-found");
    }
    expect(authThrew).toBe(true);

    // Rate-limit docs — all three known paths gone.
    const db = admin.firestore();
    expect((await db.doc(`rateLimits/${uid}`).get()).exists).toBe(false);
    expect((await db.doc(`rateLimits/cheerUp/${uid}`).get()).exists).toBe(false);
    expect((await db.doc(`rateLimits.patterns/${uid}`).get()).exists).toBe(false);
  });

  it("idempotent re-run on a fully-deleted uid returns alreadyDeleted=true", async () => {
    const uid = await seedFullUserState();
    await runDeletionCascade(uid);

    // Second run on the same uid — should short-circuit cleanly.
    const second = await runDeletionCascade(uid);
    expect(second.alreadyDeleted).toBe(true);
  });

  it("partial-state recovery — auth pre-deleted, Firestore + Storage still cleared", async () => {
    const uid = await seedFullUserState();

    // Simulate a prior crash: auth user already removed but Firestore +
    // Storage are intact.
    await admin.auth().deleteUser(uid);

    const result = await runDeletionCascade(uid);
    expect(result.alreadyDeleted).toBe(false);

    expect(await listUserDocs(uid)).toEqual([]);
    expect(await listUserMedia(uid)).toEqual([]);
  });
});
