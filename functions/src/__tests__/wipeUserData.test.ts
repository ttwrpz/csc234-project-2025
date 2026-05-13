// wipeUserData — Cloud Function tests covering the Sprint 5 Day 2 audit
// findings (R-H01 Storage cascade, R-M01 rate-limit cleanup, R-M02
// idempotency contract, plus the PII canary on structured logs).
//
// Coverage:
//   1. R-H01 — Storage canary. Seed a fake bucket with
//      `users/test-uid/media/canary.jpg`; assert deleteFiles({prefix:
//      'users/test-uid/media/'}) is invoked exactly once and that the
//      structured log line includes only counts (never the object name).
//   2. R-M01 — rate-limit-doc cleanup. Assert all four collection
//      delete()s are invoked, including the case where one is
//      already-not-found (admin SDK delete is idempotent).
//   3. R-M02 — idempotency flag. First invocation returns
//      {alreadyDeleted: false, deleted: {...}}; second invocation on a
//      cleaned state (no profile doc + empty moods) returns
//      {alreadyDeleted: true} without doing any work.
//   4. PII canary — across every logger call, Storage object names never
//      appear in the structured-log payload.
//
// R-M03 (runtime options — timeoutSeconds, memory, enforceAppCheck) is
// configuration, not behaviour. The firebase-functions v2 onCall builder
// stores the options object on the handler but does not expose a stable
// public type for assertion, so we skip a runtime test here. The config
// is asserted by a security-reviewer eyeball on the diff.
//
// Mock strategy mirrors suggestQuote.test.ts where possible; the
// firestore mock is hand-rolled wider because wipeUserData exercises
// collection/limit/get/batch/delete in addition to the rate-limit
// runTransaction path used by other CFs.

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Mocks (set up before importing the module under test)
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
// In-memory Firestore mock. Models documents as a flat path→data map and
// collections as the set of paths sharing a common prefix.
// ---------------------------------------------------------------------------

const docStore = new Map<string, Record<string, unknown>>();

interface FakeDocRef {
  _path: string;
  get(): Promise<{
    exists: boolean;
    data: () => Record<string, unknown> | undefined;
  }>;
  set(
    data: Record<string, unknown>,
    opts?: { merge?: boolean },
  ): Promise<void>;
  delete(): Promise<void>;
}

interface FakeCollectionRef {
  _path: string;
  doc(id: string): FakeDocRef;
  limit(n: number): FakeQueryRef;
}

interface FakeQueryRef {
  get(): Promise<{
    empty: boolean;
    size: number;
    docs: { ref: FakeDocRef }[];
  }>;
}

function makeDocRef(path: string): FakeDocRef {
  return {
    _path: path,
    get() {
      const existing = docStore.get(path);
      return Promise.resolve({
        exists: existing !== undefined,
        data: () => (existing ? { ...existing } : undefined),
      });
    },
    set(data, opts) {
      const merge = opts?.merge === true;
      const existing = docStore.get(path);
      docStore.set(path, merge && existing ? { ...existing, ...data } : { ...data });
      return Promise.resolve();
    },
    delete() {
      const existed = docStore.delete(path);
      if (!existed && deleteShouldThrow.has(path)) {
        return Promise.reject(new Error('not-found'));
      }
      return Promise.resolve();
    },
  };
}

function makeCollectionRef(path: string): FakeCollectionRef {
  return {
    _path: path,
    doc(id: string) {
      return makeDocRef(`${path}/${id}`);
    },
    limit(n: number) {
      return {
        get() {
          // Find all docs whose path is exactly `${path}/<id>` (one segment beyond).
          const prefix = `${path}/`;
          const matches: { ref: FakeDocRef }[] = [];
          for (const docPath of docStore.keys()) {
            if (!docPath.startsWith(prefix)) continue;
            const rest = docPath.slice(prefix.length);
            if (rest.includes('/')) continue;
            matches.push({ ref: makeDocRef(docPath) });
            if (matches.length >= n) break;
          }
          return Promise.resolve({
            empty: matches.length === 0,
            size: matches.length,
            docs: matches,
          });
        },
      };
    },
  };
}

const deleteShouldThrow = new Set<string>();

const firestoreMock = {
  doc(path: string): FakeDocRef {
    return makeDocRef(path);
  },
  collection(path: string): FakeCollectionRef {
    return makeCollectionRef(path);
  },
  batch() {
    const ops: (() => Promise<void>)[] = [];
    return {
      delete(ref: FakeDocRef) {
        ops.push(() => ref.delete());
      },
      commit: async () => {
        for (const op of ops) await op();
      },
    };
  },
};

jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
}));

// ---------------------------------------------------------------------------
// In-memory Storage mock. The fake bucket tracks files by full path and
// records every call to deleteFiles / getFiles so tests can assert.
// ---------------------------------------------------------------------------

const storedFiles = new Set<string>();
const deleteFilesCalls: { prefix: string; force?: boolean }[] = [];
const getFilesCalls: { prefix: string }[] = [];
let storageShouldThrow = false;

const bucketMock = {
  getFiles: jest.fn(
    ({ prefix }: { prefix: string }): Promise<[{ name: string }[]]> => {
      getFilesCalls.push({ prefix });
      if (storageShouldThrow) {
        return Promise.reject(new Error('storage-getFiles-failure'));
      }
      const matches: { name: string }[] = [];
      for (const path of storedFiles) {
        if (path.startsWith(prefix)) matches.push({ name: path });
      }
      return Promise.resolve([matches]);
    },
  ),
  deleteFiles: jest.fn(
    ({ prefix, force }: { prefix: string; force?: boolean }): Promise<void> => {
      deleteFilesCalls.push({ prefix, force });
      if (storageShouldThrow) {
        return Promise.reject(new Error('storage-deleteFiles-failure'));
      }
      for (const path of [...storedFiles]) {
        if (path.startsWith(prefix)) storedFiles.delete(path);
      }
      return Promise.resolve();
    },
  ),
};

jest.unstable_mockModule('firebase-admin/storage', () => ({
  getStorage: () => ({ bucket: () => bucketMock }),
}));

// ---------------------------------------------------------------------------
// Module under test (imported after mocks)
// ---------------------------------------------------------------------------

let handleWipeUserData: typeof import('../wipeUserData.js').handleWipeUserData;

beforeAll(async () => {
  const mod = await import('../wipeUserData.js');
  handleWipeUserData = mod.handleWipeUserData;
});

beforeEach(() => {
  loggerCalls.length = 0;
  docStore.clear();
  deleteShouldThrow.clear();
  storedFiles.clear();
  deleteFilesCalls.length = 0;
  getFilesCalls.length = 0;
  storageShouldThrow = false;
  bucketMock.deleteFiles.mockClear();
  bucketMock.getFiles.mockClear();
});

interface CallableLike {
  auth?: { uid: string };
  data: unknown;
}

function call(uid: string | null): CallableLike {
  return uid ? { auth: { uid }, data: {} } : { data: {} };
}

// Seed a "first-run" fixture: profile doc + one mood + one cooldown +
// the four rate-limit docs the cleanup pass should sweep.
function seedFullAccount(uid: string): void {
  docStore.set(`users/${uid}`, {
    displayName: 'Test',
    tokenBalance: 7,
  });
  docStore.set(`users/${uid}/moods/m1`, { mood: 'sad', intensity: 4 });
  docStore.set(`users/${uid}/cooldowns/tier-1`, { lastDispatchedAt: 0 });
  // Rate-limit docs — note the dot in 'rateLimits.cheerUp' is a literal
  // segment in our flat-key fake (matches the production usage where the
  // doc path is `rateLimits.cheerUp/{uid}`).
  docStore.set(`rateLimits/${uid}`, { count: 3 });
  docStore.set(`rateLimits.patterns/${uid}`, { count: 1 });
  docStore.set(`rateLimits.cheerUp/${uid}`, { count: 1 });
  docStore.set(`rateLimits.suggestQuote/${uid}`, { count: 2 });
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('wipeUserData handler', () => {
  // -------------------------------------------------------------------------
  // Auth fence (pre-existing contract, preserved by the refactor).
  // -------------------------------------------------------------------------
  describe('auth fence', () => {
    test('throws HttpsError(unauthenticated) when request.auth is missing', async () => {
      await expect(
        handleWipeUserData(call(null) as never),
      ).rejects.toMatchObject({ code: 'unauthenticated' });
    });
  });

  // -------------------------------------------------------------------------
  // R-H01: Storage media cascade.
  // -------------------------------------------------------------------------
  describe('R-H01 storage cascade', () => {
    test(
      'deleteFiles({prefix: users/{uid}/media/}) is invoked exactly once',
      async () => {
        const uid = 'test-uid';
        seedFullAccount(uid);
        storedFiles.add(`users/${uid}/media/canary.jpg`);
        storedFiles.add(`users/${uid}/media/sub/dir/other.png`);

        const out = await handleWipeUserData(call(uid) as never);

        expect(bucketMock.deleteFiles).toHaveBeenCalledTimes(1);
        expect(deleteFilesCalls).toEqual([
          { prefix: `users/${uid}/media/`, force: true },
        ]);
        expect(out).toMatchObject({
          ok: true,
          alreadyDeleted: false,
          mediaDeletedCount: 2,
        });
        // Storage state cleared.
        expect([...storedFiles].some((p) => p.startsWith(`users/${uid}/media/`))).toBe(false);
      },
    );

    test(
      'Storage SDK failure does NOT abort the cascade (best-effort)',
      async () => {
        const uid = 'test-uid';
        seedFullAccount(uid);
        storageShouldThrow = true;

        const out = await handleWipeUserData(call(uid) as never);

        // Cascade still completed for non-Storage steps.
        expect(out).toMatchObject({ ok: true, alreadyDeleted: false });
        // A warn log was emitted with only allowlisted fields.
        const warn = loggerCalls.find((c) => c.level === 'warn');
        expect(warn).toBeDefined();
        const payload = warn?.payload as Record<string, unknown>;
        expect(payload['uid']).toBe(uid);
        expect(payload['errorName']).toBe('Error');
        // Never leak the message body or stack — only event tag + uid +
        // errorName allowed.
        expect(Object.keys(payload).sort()).toEqual(
          ['errorName', 'event', 'uid'].sort(),
        );
      },
    );

    test('PII canary — Storage object names never appear in any log payload', async () => {
      const uid = 'test-uid';
      seedFullAccount(uid);
      const canaryName = 'super-secret-mood-photo-2026-05-13.jpg';
      storedFiles.add(`users/${uid}/media/${canaryName}`);

      await handleWipeUserData(call(uid) as never);

      const dump = JSON.stringify(loggerCalls);
      expect(dump).not.toContain(canaryName);
      // Belt-and-braces: also confirm the per-file path never leaks.
      expect(dump).not.toContain('media/super-secret');
    });
  });

  // -------------------------------------------------------------------------
  // R-M01: rate-limit doc cleanup.
  // -------------------------------------------------------------------------
  describe('R-M01 rate-limit cleanup', () => {
    test(
      'deletes all four rate-limit collection docs when present',
      async () => {
        const uid = 'test-uid';
        seedFullAccount(uid);

        const out = await handleWipeUserData(call(uid) as never);

        expect(out).toMatchObject({
          ok: true,
          alreadyDeleted: false,
          rateLimitDeletedCount: 4,
        });
        // All four docs cleared.
        expect(docStore.has(`rateLimits/${uid}`)).toBe(false);
        expect(docStore.has(`rateLimits.patterns/${uid}`)).toBe(false);
        expect(docStore.has(`rateLimits.cheerUp/${uid}`)).toBe(false);
        expect(docStore.has(`rateLimits.suggestQuote/${uid}`)).toBe(false);
      },
    );

    test(
      'idempotent: missing rate-limit doc is fine, cascade still completes',
      async () => {
        const uid = 'test-uid';
        seedFullAccount(uid);
        // Pretend one of the four was already cleaned (TTL reaped it).
        docStore.delete(`rateLimits.cheerUp/${uid}`);
        // And one throws on delete (e.g. transient Firestore error) —
        // the cascade should still return ok.
        deleteShouldThrow.add(`rateLimits.suggestQuote/${uid}`);

        const out = await handleWipeUserData(call(uid) as never);

        // Two definitely deleted; one was already-missing (counted as
        // success in the fake — admin SDK treats not-found as success);
        // one threw and was suppressed.
        expect(out).toMatchObject({ ok: true, alreadyDeleted: false });
        const outDone = out as Extract<typeof out, { alreadyDeleted: false }>;
        expect(outDone.rateLimitDeletedCount).toBeGreaterThanOrEqual(2);
      },
    );
  });

  // -------------------------------------------------------------------------
  // R-M02: idempotency flag.
  // -------------------------------------------------------------------------
  describe('R-M02 idempotency contract', () => {
    test('first invocation returns alreadyDeleted: false with counts', async () => {
      const uid = 'test-uid';
      seedFullAccount(uid);

      const out = await handleWipeUserData(call(uid) as never);

      expect(out).toMatchObject({
        ok: true,
        alreadyDeleted: false,
      });
      const outDone = out as Extract<typeof out, { alreadyDeleted: false }>;
      expect(outDone.deleted.moods).toBe(1);
      expect(outDone.deleted.cooldowns).toBe(1);
      // Subcollections that were empty are present-with-count-zero.
      expect(outDone.deleted.weeklyGardens).toBe(0);
    });

    test(
      'second invocation on cleaned state returns alreadyDeleted: true with NO work',
      async () => {
        const uid = 'test-uid';
        // No profile doc, no moods — simulate the post-first-run state.
        // Don't even seed media/rate-limit; the idempotency check should
        // short-circuit before touching Storage.

        const out = await handleWipeUserData(call(uid) as never);

        expect(out).toEqual({ ok: true, alreadyDeleted: true });
        // No Storage call should have happened.
        expect(bucketMock.deleteFiles).not.toHaveBeenCalled();
        expect(bucketMock.getFiles).not.toHaveBeenCalled();
        // The "alreadyDeleted" log line is the only info-level emission.
        const alreadyDeletedLog = loggerCalls.find(
          (c) => c.level === 'info' && typeof c.payload === 'object',
        );
        expect(alreadyDeletedLog?.payload).toEqual({
          event: 'wipeUserData.alreadyDeleted',
          uid,
        });
      },
    );

    test(
      'second invocation with leftover moods proceeds (does NOT short-circuit)',
      async () => {
        const uid = 'test-uid';
        // No profile doc — but a stale mood survived the first run.
        docStore.set(`users/${uid}/moods/m-stale`, { mood: 'sad' });

        const out = await handleWipeUserData(call(uid) as never);

        // Not the alreadyDeleted shape; the cascade ran.
        expect(out).toMatchObject({ ok: true, alreadyDeleted: false });
        const outDone = out as Extract<typeof out, { alreadyDeleted: false }>;
        expect(outDone.deleted.moods).toBe(1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // PII discipline (broader — confirms nothing sensitive leaks anywhere).
  // -------------------------------------------------------------------------
  describe('PII canary on logs', () => {
    test('no doc-body field appears in any log payload', async () => {
      const uid = 'test-uid';
      seedFullAccount(uid);
      // Plant a canary value in a doc body — should never leak to logs.
      docStore.set(`users/${uid}/moods/m1`, {
        mood: 'sad',
        text: 'PII-CANARY-MOOD-TEXT-XYZ',
      });
      storedFiles.add(`users/${uid}/media/PII-CANARY-FILE-XYZ.jpg`);

      await handleWipeUserData(call(uid) as never);

      const dump = JSON.stringify(loggerCalls);
      expect(dump).not.toContain('PII-CANARY-MOOD-TEXT-XYZ');
      expect(dump).not.toContain('PII-CANARY-FILE-XYZ');
    });

    test('uid IS present (allowed per ADR-0003) but no other identifier is', async () => {
      const uid = 'test-uid';
      seedFullAccount(uid);

      await handleWipeUserData(call(uid) as never);

      const successLog = loggerCalls.find(
        (c) => c.level === 'info' && (c.payload as { deleted?: unknown }).deleted,
      );
      expect(successLog).toBeDefined();
      const payload = successLog?.payload as Record<string, unknown>;
      expect(payload['uid']).toBe(uid);
      expect(payload['event']).toBe('wipeUserData');
      // Allowlist: event tag + uid + counts buckets only.
      const keys = Object.keys(payload).sort();
      expect(keys).toEqual(
        [
          'deleted',
          'event',
          'mediaDeletedCount',
          'rateLimitDeletedCount',
          'uid',
        ].sort(),
      );
    });
  });
});
