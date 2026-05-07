// 5-case test suite for the deleteAccount handler — covers the
// HB-004 §"Tests" matrix:
//   1. unauth → HttpsError('unauthenticated')
//   2. happy path → cascade runs, ok+alreadyDeleted=false, all paths empty
//   3. idempotent re-run → ok+alreadyDeleted=true, no exception
//   4. partial-state recovery → auth user pre-deleted; Firestore + Storage
//      still cleaned; auth/user-not-found is caught.
//   5. PII canary → no log payload contains mood/text/Storage paths
//      beyond the users/{uid}/media/ prefix or any token string.
//
// Strategy mirrors analyzeMoodText.test.ts:
//  - Mock firebase-functions/logger so payloads are captured for
//    assertions.
//  - Mock firebase-admin/firestore with an in-memory doc store that
//    supports recursiveDelete + plain doc delete.
//  - Mock firebase-admin/storage with a deleteFiles({prefix}) method.
//  - Mock firebase-admin/auth with getUser/deleteUser stubs whose
//    behaviour each test case parameterises.

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Logger capture
// ---------------------------------------------------------------------------

const loggerCalls: { level: string; payload: unknown }[] = [];
jest.unstable_mockModule('firebase-functions/logger', () => ({
  info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
  warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
  error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
  debug: (payload: unknown) => loggerCalls.push({ level: 'debug', payload }),
  log: (payload: unknown) => loggerCalls.push({ level: 'log', payload }),
}));

jest.unstable_mockModule('firebase-functions', () => ({
  logger: {
    info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
    warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
    error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
    debug: (payload: unknown) => loggerCalls.push({ level: 'debug', payload }),
    log: (payload: unknown) => loggerCalls.push({ level: 'log', payload }),
  },
}));

// ---------------------------------------------------------------------------
// HttpsError stub
// ---------------------------------------------------------------------------

class FakeHttpsError extends Error {
  code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
    this.name = 'HttpsError';
  }
}
jest.unstable_mockModule('firebase-functions/v2/https', () => ({
  HttpsError: FakeHttpsError,
  onCall: (_opts: unknown, handler: unknown) => handler,
}));

// ---------------------------------------------------------------------------
// Firestore mock — supports doc().get/.delete and recursiveDelete(rootRef).
// Also supports doc().set for seeding.
// ---------------------------------------------------------------------------

interface DocPayload { [k: string]: unknown }

type Store = Map<string, DocPayload>;
const firestoreStore: Store = new Map();

interface DocRef {
  _path: string;
  get(): Promise<{ exists: boolean; data: () => DocPayload | undefined }>;
  delete(): Promise<void>;
  set(data: DocPayload): Promise<void>;
}

function makeDocRef(path: string): DocRef {
  return {
    _path: path,
    get(): Promise<{ exists: boolean; data: () => DocPayload | undefined }> {
      const data = firestoreStore.get(path);
      return Promise.resolve({ exists: data !== undefined, data: () => data });
    },
    delete(): Promise<void> {
      firestoreStore.delete(path);
      return Promise.resolve();
    },
    set(data: DocPayload): Promise<void> {
      firestoreStore.set(path, data);
      return Promise.resolve();
    },
  };
}

const firestoreMock = {
  doc(path: string): DocRef {
    return makeDocRef(path);
  },
  // Mimic admin-SDK recursiveDelete: removes all docs whose path starts
  // with `${root._path}/` AND the root itself.
  recursiveDelete(root: DocRef): Promise<void> {
    const prefix = `${root._path}/`;
    for (const key of Array.from(firestoreStore.keys())) {
      if (key === root._path || key.startsWith(prefix)) {
        firestoreStore.delete(key);
      }
    }
    return Promise.resolve();
  },
};

jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
}));

// ---------------------------------------------------------------------------
// Storage mock — bucket.deleteFiles({prefix}) removes any keys beginning
// with the prefix.
// ---------------------------------------------------------------------------

const storageStore: Set<string> = new Set();
const deleteFilesCalls: { prefix: string }[] = [];

const bucketMock = {
  deleteFiles(opts: { prefix: string }): Promise<void> {
    deleteFilesCalls.push({ prefix: opts.prefix });
    for (const key of Array.from(storageStore)) {
      if (key.startsWith(opts.prefix)) {
        storageStore.delete(key);
      }
    }
    return Promise.resolve();
  },
};

jest.unstable_mockModule('firebase-admin/storage', () => ({
  getStorage: () => ({ bucket: () => bucketMock }),
}));

// ---------------------------------------------------------------------------
// Auth mock — getUser/deleteUser. Behaviour parameterised per case.
// ---------------------------------------------------------------------------

const authUsers: Set<string> = new Set();
const getUserCalls: string[] = [];
const deleteUserCalls: string[] = [];

// Optional override hooks the tests can install per-case.
let getUserOverride: ((uid: string) => Promise<void>) | null = null;
let deleteUserOverride: ((uid: string) => Promise<void>) | null = null;

const authMock = {
  async getUser(uid: string): Promise<{ uid: string }> {
    getUserCalls.push(uid);
    if (getUserOverride) {
      await getUserOverride(uid);
      return { uid };
    }
    if (!authUsers.has(uid)) {
      const err = new Error('user not found') as Error & { code: string };
      err.code = 'auth/user-not-found';
      throw err;
    }
    return { uid };
  },
  async deleteUser(uid: string): Promise<void> {
    deleteUserCalls.push(uid);
    if (deleteUserOverride) {
      await deleteUserOverride(uid);
      return;
    }
    if (!authUsers.has(uid)) {
      const err = new Error('user not found') as Error & { code: string };
      err.code = 'auth/user-not-found';
      throw err;
    }
    authUsers.delete(uid);
  },
};

jest.unstable_mockModule('firebase-admin/auth', () => ({
  getAuth: () => authMock,
}));

// ---------------------------------------------------------------------------
// Module under test — must import AFTER mocks.
// ---------------------------------------------------------------------------

let handleDeleteAccount: typeof import('../deleteAccount.js').handleDeleteAccount;

beforeAll(async () => {
  const mod = await import('../deleteAccount.js');
  handleDeleteAccount = mod.handleDeleteAccount;
});

beforeEach(() => {
  loggerCalls.length = 0;
  firestoreStore.clear();
  storageStore.clear();
  deleteFilesCalls.length = 0;
  authUsers.clear();
  getUserCalls.length = 0;
  deleteUserCalls.length = 0;
  getUserOverride = null;
  deleteUserOverride = null;
});

interface CallableLike {
  auth?: { uid: string };
  data: unknown;
}

function call(uid: string | null, data: unknown = { requestId: 'req-test' }): CallableLike {
  return uid ? { auth: { uid }, data } : { data };
}

function seedFullUserState(uid: string): void {
  // Firestore — mirrors the v1.5 schema layout exhaustively enough to
  // exercise every recursiveDelete branch.
  firestoreStore.set(`users/${uid}`, { displayName: 'Test User' });
  firestoreStore.set(`users/${uid}/moods/m1`, {
    mood: 'happy',
    text: 'PII-MOOD-TEXT-DO-NOT-LOG',
    intensity: 4,
  });
  firestoreStore.set(`users/${uid}/moods/m2`, {
    mood: 'sad',
    text: 'PII-MOOD-TEXT-2',
    intensity: 2,
  });
  firestoreStore.set(`users/${uid}/insights/i1`, { text: 'PII-INSIGHT' });
  firestoreStore.set(`users/${uid}/cheerUpEvents/e1`, { reason: '5_of_7_negative' });
  firestoreStore.set(`users/${uid}/interventionState/state`, { count: 3 });
  firestoreStore.set(`users/${uid}/settings/notifications`, {
    tokens: ['PII-FCM-TOKEN-1234567890', 'PII-FCM-TOKEN-OTHER'],
  });
  firestoreStore.set(`rateLimits/${uid}`, { windowStartMs: 0, count: 0 });
  firestoreStore.set(`rateLimits/cheerUp/${uid}`, { count: 0 });
  firestoreStore.set(`rateLimits.patterns/${uid}`, { count: 0 });

  // Storage — three media objects under users/{uid}/media/.
  storageStore.add(`users/${uid}/media/photo1.jpg`);
  storageStore.add(`users/${uid}/media/photo2.jpg`);
  storageStore.add(`users/${uid}/media/photo3.jpg`);

  // Auth user
  authUsers.add(uid);
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('deleteAccount handler', () => {
  // 1. Auth missing
  test('1. unauth → HttpsError(unauthenticated)', async () => {
    await expect(
      handleDeleteAccount(call(null, { requestId: 'req-1' }) as never),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  // 2. Happy path
  test('2. happy path → cascade clears Firestore + Storage + Auth', async () => {
    const uid = 'user-happy';
    seedFullUserState(uid);

    const res = await handleDeleteAccount(call(uid, { requestId: 'req-2' }) as never);
    expect(res).toEqual({
      ok: true,
      alreadyDeleted: false,
      requestId: 'req-2',
      v: 1,
    });

    // Firestore: every users/{uid}/** doc gone, plus rate-limit docs.
    for (const key of Array.from(firestoreStore.keys())) {
      expect(key.startsWith(`users/${uid}`)).toBe(false);
    }
    expect(firestoreStore.has(`rateLimits/${uid}`)).toBe(false);
    expect(firestoreStore.has(`rateLimits/cheerUp/${uid}`)).toBe(false);
    expect(firestoreStore.has(`rateLimits.patterns/${uid}`)).toBe(false);

    // Storage: prefix passed in, files gone.
    expect(deleteFilesCalls).toEqual([{ prefix: `users/${uid}/media/` }]);
    expect(Array.from(storageStore).filter((k) => k.startsWith(`users/${uid}/`))).toEqual([]);

    // Auth user revoked.
    expect(authUsers.has(uid)).toBe(false);
    expect(deleteUserCalls).toEqual([uid]);

    // Success log
    const successLog = loggerCalls.find(
      (c) => (c.payload as { outcome?: string }).outcome === 'deleted',
    );
    expect(successLog).toBeDefined();
    expect((successLog!.payload as { uid?: string }).uid).toBe(uid);
  });

  // 3. Idempotent re-run
  test('3. idempotent re-run → alreadyDeleted=true, no exception', async () => {
    const uid = 'user-rerun';
    seedFullUserState(uid);

    // First run: cascade.
    const first = await handleDeleteAccount(call(uid, { requestId: 'req-3a' }) as never);
    expect(first.alreadyDeleted).toBe(false);

    // Second run: idempotent short-circuit.
    deleteFilesCalls.length = 0;
    deleteUserCalls.length = 0;
    const second = await handleDeleteAccount(call(uid, { requestId: 'req-3b' }) as never);
    expect(second).toEqual({
      ok: true,
      alreadyDeleted: true,
      requestId: 'req-3b',
      v: 1,
    });
    // No second cascade work
    expect(deleteFilesCalls).toEqual([]);
    expect(deleteUserCalls).toEqual([]);

    const alreadyLog = loggerCalls.find(
      (c) => (c.payload as { outcome?: string }).outcome === 'already_deleted',
    );
    expect(alreadyLog).toBeDefined();
  });

  // 4. Partial-state recovery — auth user pre-deleted, Firestore + Storage
  // intact. CF must catch user-not-found and finish the cascade.
  test('4. partial-state — auth user pre-deleted → cascade still runs + ok', async () => {
    const uid = 'user-partial';
    seedFullUserState(uid);
    // Simulate prior crash: auth user already gone, Firestore + Storage intact.
    authUsers.delete(uid);

    const res = await handleDeleteAccount(call(uid, { requestId: 'req-4' }) as never);
    expect(res).toEqual({
      ok: true,
      alreadyDeleted: false,
      requestId: 'req-4',
      v: 1,
    });

    // Firestore + Storage cleared even though auth was already gone.
    for (const key of Array.from(firestoreStore.keys())) {
      expect(key.startsWith(`users/${uid}`)).toBe(false);
    }
    expect(Array.from(storageStore).filter((k) => k.startsWith(`users/${uid}/`))).toEqual([]);
    // deleteUser was called and threw user-not-found, which the CF caught.
    expect(deleteUserCalls).toEqual([uid]);
  });

  // 5. PII canary — across every test logger payload, no user-document
  // field, no Storage object name beyond the prefix, no FCM token string
  // appears.
  test('5. PII canary — no mood text / token / per-object Storage path in logs', async () => {
    const uid = 'user-pii';
    seedFullUserState(uid);

    // Run all flows so logger picks up every emit pathway.
    await handleDeleteAccount(call(uid, { requestId: 'req-5a' }) as never);
    await handleDeleteAccount(call(uid, { requestId: 'req-5b' }) as never); // already_deleted

    // Provoke an internal error path on a fresh uid to capture the
    // error log too — not strictly required by HB-004 §"PII canary"
    // but exercising the error branch demonstrates the allowlist holds
    // there as well.
    const uidErr = 'user-pii-err';
    seedFullUserState(uidErr);
    deleteUserOverride = () => {
      const e = new Error('boom') as Error & { code: string };
      e.code = 'auth/internal-error';
      return Promise.reject(e);
    };
    await expect(
      handleDeleteAccount(call(uidErr, { requestId: 'req-5c' }) as never),
    ).rejects.toBeDefined();

    // Every payload must NOT contain any of the PII canaries.
    const forbidden = [
      'PII-MOOD-TEXT-DO-NOT-LOG',
      'PII-MOOD-TEXT-2',
      'PII-INSIGHT',
      'PII-FCM-TOKEN-1234567890',
      'PII-FCM-TOKEN-OTHER',
      'photo1.jpg',
      'photo2.jpg',
      'photo3.jpg',
    ];
    for (const c of loggerCalls) {
      const serialized = JSON.stringify(c.payload);
      for (const needle of forbidden) {
        expect(serialized).not.toContain(needle);
      }
    }

    // Positive assertion: every payload should include uid, event,
    // outcome — i.e. allowlist keys are emitted. (We don't enforce
    // requestId on every log because the unauth path throws before
    // we have a trustworthy correlation id; that path is covered by
    // case 1.)
    for (const c of loggerCalls) {
      const p = c.payload as { event?: string; uid?: string };
      expect(p.event).toBe('deleteAccount');
      expect(p.uid).toBeTruthy();
    }
  });
});
