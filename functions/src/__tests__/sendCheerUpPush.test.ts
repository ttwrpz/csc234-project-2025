// 7-case test suite for sendCheerUpPush. Cases mirror HB-003 §5.5b
// "Tests to write" exactly:
//   1. happy-path
//   2. opted_out
//   3. no_tokens
//   4. rate_limited
//   5. dead-token pruning
//   6. PII canary
//   7. channel-id literal
//
// Strategy (mirrors analyzePatterns.test.ts):
//   - Mock firebase-functions/logger so we capture log payloads.
//   - Mock firebase-admin/firestore with an in-memory store that
//     supports BOTH the rate-limit transaction shape AND the
//     `db.doc(path).get()` + `.update()` path the CF uses for the
//     settings doc.
//   - Mock firebase-admin/messaging so we observe sendEachForMulticast
//     payloads + can stub per-token responses for the dead-token case.
//   - Mock firebase-functions/v2/firestore so the handler fn is
//     callable directly (no real Firestore listener wiring).

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Mocks (must be set up before importing the module under test)
// ---------------------------------------------------------------------------

const loggerCalls: { level: string; payload: unknown }[] = [];
jest.unstable_mockModule('firebase-functions/logger', () => ({
  info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
  warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
  error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
}));
jest.unstable_mockModule('firebase-functions', () => ({
  logger: {
    info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
    warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
    error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
  },
}));

// Pass-through wrappers for the v2 callable registration.
// `onCall(opts, handler)` → returns the handler fn unchanged so the
// test can call it directly. `HttpsError` is imported by the handler
// for the unauthenticated branch; we expose a minimal class for tests.
class FakeHttpsError extends Error {
  constructor(public readonly code: string, message: string) {
    super(message);
  }
}
jest.unstable_mockModule('firebase-functions/v2/https', () => ({
  onCall: (_opts: unknown, handler: unknown) => handler,
  HttpsError: FakeHttpsError,
}));

// ---------------------------------------------------------------------------
// In-memory Firestore mock — wide enough for both the rate-limit TX
// (analyzeMoodText shape) AND the .doc(path).get()/.update() path the
// CF uses against `users/{uid}/settings/notifications`.
// ---------------------------------------------------------------------------

type RLDoc = { windowStartMs: number; count: number; expireAt: number };
const rateLimitStore = new Map<string, RLDoc>();
const docStore = new Map<string, Record<string, unknown>>();

interface DocRefMock {
  _path: string;
  _key: string;
  get: () => Promise<{
    exists: boolean;
    data: () => Record<string, unknown> | undefined;
    ref: DocRefMock;
  }>;
  update: (patch: Record<string, unknown>) => Promise<void>;
}

let txChain: Promise<unknown> = Promise.resolve();

// Test-only escape hatch — when set, the next runTransaction call
// rejects with this error and the flag is consumed. Used by the
// `internal/rate_limit_tx_failed` PII canary case (PR #35 audit
// R-004) to drive the CF's catch branch.
let txThrowOnNextCall: Error | null = null;

function makeDocRef(path: string): DocRefMock {
  const ref: DocRefMock = {
    _path: path,
    _key: path,
    get: () => {
      const existing = docStore.get(path);
      const refClosure = ref;
      return Promise.resolve({
        exists: existing !== undefined,
        data: () => (existing ? { ...existing } : undefined),
        ref: refClosure,
      });
    },
    update: (patch) => {
      const base = docStore.get(path) ?? {};
      docStore.set(path, { ...base, ...patch });
      return Promise.resolve();
    },
  };
  return ref;
}

const firestoreMock = {
  doc(path: string): DocRefMock {
    return makeDocRef(path);
  },
  runTransaction<T>(
    fn: (tx: {
      get: (ref: { _key: string }) => Promise<{
        exists: boolean;
        data: () => RLDoc | undefined;
      }>;
      set: (ref: { _key: string }, data: RLDoc) => void;
      update: (ref: { _key: string }, patch: Partial<RLDoc>) => void;
    }) => Promise<T>,
  ): Promise<T> {
    if (txThrowOnNextCall) {
      const err = txThrowOnNextCall;
      txThrowOnNextCall = null;
      return Promise.reject(err);
    }
    const next = txChain.then(async (): Promise<T> => {
      const writes = new Map<string, RLDoc>();
      const tx = {
        get: (ref: { _key: string }) => {
          const existing = rateLimitStore.get(ref._key);
          return Promise.resolve({
            exists: existing !== undefined,
            data: () => (existing ? { ...existing } : undefined),
          });
        },
        set: (ref: { _key: string }, data: RLDoc) => {
          writes.set(ref._key, { ...data });
        },
        update: (ref: { _key: string }, patch: Partial<RLDoc>) => {
          const base = writes.get(ref._key) ?? rateLimitStore.get(ref._key);
          if (!base) throw new Error('update on missing doc');
          writes.set(ref._key, { ...base, ...patch });
        },
      };
      const result = await fn(tx);
      for (const [k, v] of writes) rateLimitStore.set(k, v);
      return result;
    });
    txChain = next.catch(() => undefined);
    return next;
  },
};

jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
}));

// ---------------------------------------------------------------------------
// Messaging mock — settable per-test response shape so we can stub
// per-token success / dead-token errors.
// ---------------------------------------------------------------------------

interface MulticastMessage {
  tokens: string[];
  notification?: { title?: string; body?: string };
  android?: { notification?: { channelId?: string; priority?: string } };
}

interface PerTokenResponse {
  success: boolean;
  error?: { code: string };
}

interface MulticastResponse {
  successCount: number;
  failureCount: number;
  responses: PerTokenResponse[];
}

let nextMulticastResponse: ((msg: MulticastMessage) => MulticastResponse) | null =
  null;
const sentMulticasts: MulticastMessage[] = [];

const sendEachForMulticastMock = jest.fn(
  (msg: MulticastMessage): Promise<MulticastResponse> => {
    sentMulticasts.push(msg);
    if (nextMulticastResponse) return Promise.resolve(nextMulticastResponse(msg));
    return Promise.resolve({
      successCount: msg.tokens.length,
      failureCount: 0,
      responses: msg.tokens.map(() => ({ success: true })),
    });
  },
);

jest.unstable_mockModule('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast: sendEachForMulticastMock }),
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let sendCheerUpPush: typeof import('../sendCheerUpPush.js').sendCheerUpPush;

beforeAll(async () => {
  const mod = await import('../sendCheerUpPush.js');
  sendCheerUpPush = mod.sendCheerUpPush;
});

beforeEach(() => {
  loggerCalls.length = 0;
  rateLimitStore.clear();
  docStore.clear();
  sentMulticasts.length = 0;
  txChain = Promise.resolve();
  sendEachForMulticastMock.mockClear();
  nextMulticastResponse = null;
});

interface FakeCallableRequest {
  auth: { uid: string } | undefined;
  data: { requestId?: string };
}

function makeRequest(
  uid: string,
  requestId: string = '2026-05-13-5_of_7_negative',
): FakeCallableRequest {
  return {
    auth: { uid },
    data: { requestId },
  };
}

function seedSettings(uid: string, data: Record<string, unknown>): void {
  docStore.set(`users/${uid}/settings/notifications`, data);
}

async function invoke(
  uid: string,
  requestId: string = '2026-05-13-5_of_7_negative',
): Promise<void> {
  // The mocked `onCall` returns the handler unchanged. v1.0 polish
  // (2026-05-10): the function used to be a Firestore document
  // trigger but moved to onCall because the project's Firestore is
  // in `asia-southeast3` (Bangkok), which Firestore-trigger Eventarc
  // does not yet allowlist. Tests now pass a `CallableRequest`
  // shape; everything else is unchanged.
  const handler = sendCheerUpPush as unknown as (
    req: FakeCallableRequest,
  ) => Promise<unknown>;
  await handler(makeRequest(uid, requestId));
}

function lastLog(): { level: string; payload: unknown } | undefined {
  return loggerCalls[loggerCalls.length - 1];
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('sendCheerUpPush trigger', () => {
  test('1. happy-path — 2 tokens, fresh rate limit → multicast sent with locked payload', async () => {
    seedSettings('uid-happy', {
      cheerUpEnabled: true,
      tokens: [
        { token: 'tok-A', platform: 'android' },
        { token: 'tok-B', platform: 'web' },
      ],
    });

    await invoke('uid-happy');

    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);
    const msg = sentMulticasts[0];
    if (!msg) throw new Error('expected a multicast');
    expect(msg.tokens).toEqual(['tok-A', 'tok-B']);
    expect(msg.notification?.title).toBe('A gentle check-in');
    expect(msg.notification?.body).toBe(
      "Noticing you've had a rough stretch. We're here.",
    );
    expect(msg.android?.notification?.channelId).toBe('cheer_up');

    const log = lastLog();
    expect(log?.level).toBe('info');
    expect(log?.payload).toMatchObject({
      event: 'cheerUpPush',
      outcome: 'sent',
      tokenCount: 2,
      deliveredCount: 2,
      failedCount: 0,
      prunedCount: 0,
    });
  });

  test('2. opted_out — cheerUpEnabled=false → no FCM call, no rate-limit consumption', async () => {
    seedSettings('uid-opt', {
      cheerUpEnabled: false,
      tokens: [{ token: 'tok-X', platform: 'android' }],
    });

    await invoke('uid-opt');

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0); // rate-limit doc never touched
    const log = lastLog();
    expect(log?.payload).toMatchObject({
      event: 'cheerUpPush',
      outcome: 'opted_out',
    });
  });

  test('2b. opted_out — settings doc missing entirely → no FCM call, no rate-limit consumption', async () => {
    // No seed — docStore is empty. Doc snapshot exists=false; the CF
    // must treat this identically to cheerUpEnabled !== true.
    await invoke('uid-no-doc');

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'opted_out' });
  });

  test('3. no_tokens — cheerUpEnabled=true with empty token list', async () => {
    seedSettings('uid-empty', { cheerUpEnabled: true, tokens: [] });

    await invoke('uid-empty');

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    // Rate-limit MUST not be consumed when there's nothing to send —
    // otherwise the user's daily budget could be exhausted by
    // misconfigured devices.
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({
      event: 'cheerUpPush',
      outcome: 'no_tokens',
    });
  });

  test('4. rate_limited — second invocation within 24h returns rate_limited with retryAfterSec', async () => {
    seedSettings('uid-rate', {
      cheerUpEnabled: true,
      tokens: [{ token: 'tok-1', platform: 'android' }],
    });

    await invoke('uid-rate');
    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);

    // Re-invoke — the consumeToken store still has the slot consumed.
    await invoke('uid-rate', '2026-05-13-3_consecutive_high_intensity');

    // Still only ONE FCM call across the two invocations.
    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);

    const log = lastLog();
    expect(log?.payload).toMatchObject({
      event: 'cheerUpPush',
      outcome: 'rate_limited',
    });
    const payload = log?.payload as {
      rateLimit?: { retryAfterSec?: number };
    };
    expect(payload.rateLimit?.retryAfterSec).toBeGreaterThanOrEqual(1);
  });

  test('5. dead-token pruning — one of two tokens returns registration-token-not-registered', async () => {
    seedSettings('uid-prune', {
      cheerUpEnabled: true,
      tokens: [
        { token: 'tok-LIVE', platform: 'android' },
        { token: 'tok-DEAD', platform: 'web' },
      ],
    });

    nextMulticastResponse = (msg) => ({
      successCount: 1,
      failureCount: 1,
      responses: msg.tokens.map((t) =>
        t === 'tok-DEAD'
          ? {
              success: false,
              error: { code: 'messaging/registration-token-not-registered' },
            }
          : { success: true },
      ),
    });

    await invoke('uid-prune');

    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);

    // Settings doc now drops the dead token but keeps the live one.
    const settings = docStore.get('users/uid-prune/settings/notifications') as
      | { tokens?: Array<{ token: string }> }
      | undefined;
    expect(settings?.tokens).toEqual([
      { token: 'tok-LIVE', platform: 'android' },
    ]);

    expect(lastLog()?.payload).toMatchObject({
      outcome: 'sent',
      tokenCount: 2,
      deliveredCount: 1,
      failedCount: 1,
      prunedCount: 1,
    });
  });

  test('6. PII canary — across all cases, no log payload contains token strings, BODY, or TITLE', async () => {
    // Drive each branch once: opted_out, no_tokens, sent,
    // rate_limited, AND internal/rate_limit_tx_failed (PR #35 audit
    // R-004 — the catch branch around consumeToken logs at level
    // `error` with `cause: e.name`, must still respect the allowlist).
    seedSettings('uid-A', {
      cheerUpEnabled: false,
      tokens: [{ token: 'tok-A1', platform: 'android' }],
    });
    await invoke('uid-A');

    seedSettings('uid-B', { cheerUpEnabled: true, tokens: [] });
    await invoke('uid-B');

    seedSettings('uid-C', {
      cheerUpEnabled: true,
      tokens: [{ token: 'tok-C1', platform: 'android' }],
    });
    await invoke('uid-C');

    // Re-invoke uid-C → rate_limited path.
    await invoke('uid-C', '2026-05-13-3_consecutive_high_intensity');

    // R-004: drive the internal/rate_limit_tx_failed branch by
    // forcing the next runTransaction call to reject. The CF's catch
    // logs `outcome: 'internal'` + `errorReason: 'rate_limit_tx_failed'`
    // + `cause: e.name`. None of those should ever leak a token, the
    // BODY, or the TITLE.
    seedSettings('uid-D', {
      cheerUpEnabled: true,
      tokens: [{ token: 'tok-D1', platform: 'android' }],
    });
    txThrowOnNextCall = new Error(
      // The error MESSAGE should never reach the log payload — only
      // the error NAME does — but include the forbidden strings here
      // so we'd catch a regression that started logging `e.message`.
      "tok-D1 leaked: Noticing you've had a rough stretch. We're here.",
    );
    txThrowOnNextCall.name = 'FakeFirestoreError';
    await invoke('uid-D');

    const FORBIDDEN = [
      'tok-A1',
      'tok-C1',
      'tok-D1',
      "Noticing you've had a rough stretch. We're here.",
      'A gentle check-in',
    ];
    for (const call of loggerCalls) {
      const dump = JSON.stringify(call.payload);
      for (const needle of FORBIDDEN) {
        expect(dump).not.toContain(needle);
      }
    }

    // Defense-in-depth: confirm the internal branch actually fired —
    // a regression that turned the catch into a no-op would silently
    // make the PII canary above vacuous on the new uid.
    const internalErrors = loggerCalls.filter(
      (c) =>
        c.level === 'error' &&
        typeof c.payload === 'object' &&
        c.payload !== null &&
        (c.payload as { outcome?: string }).outcome === 'internal' &&
        (c.payload as { errorReason?: string }).errorReason ===
          'rate_limit_tx_failed',
    );
    expect(internalErrors).toHaveLength(1);
  });

  test('7. channel-id literal — multicast payload always uses cheer_up exactly', async () => {
    seedSettings('uid-channel', {
      cheerUpEnabled: true,
      tokens: [{ token: 'tok-Z', platform: 'android' }],
    });

    await invoke('uid-channel');

    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);
    const msg = sentMulticasts[0];
    if (!msg) throw new Error('expected a multicast');
    // Defense against typos like 'cheerUp' or 'cheer-up' that would
    // collapse the whole pipeline silently — the manifest declares
    // `cheer_up` and the Dart channel registration uses `cheer_up`,
    // so this MUST match byte-for-byte.
    expect(msg.android?.notification?.channelId).toBe('cheer_up');
  });
});
