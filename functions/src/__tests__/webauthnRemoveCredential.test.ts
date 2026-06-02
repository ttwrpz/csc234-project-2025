// webauthnRemoveCredential - Cloud Function tests.
//
// Coverage:
//   1. Happy path - an existing credential is deleted; response reports
//      { ok: true, removed: 1 } and the doc is gone from the store.
//   2. Idempotent - removing when no credential exists returns
//      { ok: true, removed: 0 } and never opens a batch.
//   3. Unauthenticated request throws HttpsError('unauthenticated').
//   4. PII canary - no logger payload carries the credentialId; the
//      success line carries uid + removed + latencyMs only.
//
// Mock strategy mirrors webauthnRegisterFinish.test.ts: the
// firebase-functions logger, firebase-functions/v2/https, and
// firebase-admin/firestore seams are replaced with in-memory fakes.

import { jest } from '@jest/globals';

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
// In-memory Firestore mock supporting collection().get() + batch().delete().
// Documents are keyed by full path; a collection get() returns the docs whose
// path is `<collectionPath>/<id>` (one path segment below the collection).
// ---------------------------------------------------------------------------

const docStore = new Map<string, Record<string, unknown>>();
const deletedPaths: string[] = [];

interface FakeDocSnap {
  id: string;
  ref: { _path: string };
}

function makeBatch() {
  const pending: string[] = [];
  return {
    delete(ref: { _path: string }) {
      pending.push(ref._path);
    },
    commit() {
      for (const path of pending) {
        deletedPaths.push(path);
        docStore.delete(path);
      }
      return Promise.resolve();
    },
  };
}

const firestoreMock = {
  collection(path: string) {
    return {
      _path: path,
      get() {
        const prefix = `${path}/`;
        const docs: FakeDocSnap[] = [];
        for (const key of docStore.keys()) {
          if (key.startsWith(prefix) && !key.slice(prefix.length).includes('/')) {
            docs.push({ id: key.slice(prefix.length), ref: { _path: key } });
          }
        }
        return Promise.resolve({ empty: docs.length === 0, size: docs.length, docs });
      },
      doc(id: string) {
        const full = `${path}/${id}`;
        return {
          _path: full,
          set: (data: Record<string, unknown>) => {
            docStore.set(full, { ...data });
            return Promise.resolve();
          },
        };
      },
    };
  },
  batch: makeBatch,
};

jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
}));

// ---------------------------------------------------------------------------

let handleWebauthnRemoveCredential: typeof import('../webauthnRemoveCredential.js').handleWebauthnRemoveCredential;

beforeAll(async () => {
  const mod = await import('../webauthnRemoveCredential.js');
  handleWebauthnRemoveCredential = mod.handleWebauthnRemoveCredential;
});

beforeEach(() => {
  loggerCalls.length = 0;
  docStore.clear();
  deletedPaths.length = 0;
});

interface CallableLike {
  auth?: { uid: string };
  data: unknown;
}
function call(uid: string | null, data: unknown = { v: 1 }): CallableLike {
  return uid ? { auth: { uid }, data } : { data };
}

function seedCredential(uid: string, credentialId: string): void {
  docStore.set(`users/${uid}/webauthn/${credentialId}`, {
    credentialId,
    publicKeyBase64: 'AAAA',
    counter: 3,
  });
}

describe('webauthnRemoveCredential handler', () => {
  test('happy path deletes the credential + reports removed: 1', async () => {
    const uid = 'uid-remove-1';
    const credentialId = 'cred-abc';
    seedCredential(uid, credentialId);

    const result = await handleWebauthnRemoveCredential(call(uid) as never);

    expect(result).toEqual({ ok: true, removed: 1 });
    expect(deletedPaths).toContain(`users/${uid}/webauthn/${credentialId}`);
    expect(docStore.has(`users/${uid}/webauthn/${credentialId}`)).toBe(false);
  });

  test('idempotent - no credential returns removed: 0', async () => {
    const uid = 'uid-empty-1';
    const result = await handleWebauthnRemoveCredential(call(uid) as never);
    expect(result).toEqual({ ok: true, removed: 0 });
    expect(deletedPaths).toEqual([]);
  });

  test("only the caller's credentials are deleted", async () => {
    seedCredential('uid-mine', 'mine');
    seedCredential('uid-other', 'theirs');

    const result = await handleWebauthnRemoveCredential(
      call('uid-mine') as never,
    );

    expect(result).toEqual({ ok: true, removed: 1 });
    expect(docStore.has('users/uid-other/webauthn/theirs')).toBe(true);
  });

  test('unauthenticated request throws HttpsError', async () => {
    await expect(
      handleWebauthnRemoveCredential(call(null) as never),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  test('PII canary - logs never carry the credentialId', async () => {
    const uid = 'uid-pii-1';
    const credentialId = 'cred-SECRET-id-value';
    seedCredential(uid, credentialId);

    await handleWebauthnRemoveCredential(call(uid) as never);

    const dump = JSON.stringify(loggerCalls);
    expect(dump).not.toContain(credentialId);
    expect(dump).toContain(uid);
    expect(dump).toContain('latencyMs');
    expect(dump).toContain('webauthnRemoveCredential');
  });
});
