// Test suite for the Tiered Intervention push CF (`dispatchIntervention`).
//
// Mock infrastructure mirrors sendCheerUpPush.test.ts exactly: in-memory
// Firestore + messaging mocks, pass-through onCall, allow-listed logger.
// Cases (numbered for retro traceability):
//   1.  happy-path Tier 1 - locked title/body for tier 'one'
//   2.  happy-path Tier 2 - locked title/body for tier 'two'
//   3.  happy-path Tier 3 - locked title/body for tier 'three' (Tier 3 FENCE)
//   4.  unauthenticated → throws HttpsError
//   5.  schema rejection - bad tier
//   6.  schema rejection - missing dispatchId
//   7.  dispatch_missing - no audit doc for that dispatchId
//   8.  dispatch_mismatch - audit doc tier ≠ request tier
//   9.  dispatch_opted_out - audit doc optedOut === true
//  10.  opted_out - per-tier flag false in settings doc
//  11.  no_tokens - settings present, tier enabled, but tokens empty
//  12.  rate_limited - second call within 24h returns rate_limited
//  13.  dead-token pruning - survivors written back, dead tokens dropped
//  14.  PII canary - no body, no token strings in any log payload
//  15.  channel-id literal - every multicast uses channelId='cheer_up'

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Logger / HttpsError / onCall mocks
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
// In-memory Firestore mock (matches sendCheerUpPush.test.ts shape)
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
// Messaging mock
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

let nextMulticastResponse:
  | ((msg: MulticastMessage) => MulticastResponse)
  | null = null;
const sentMulticasts: MulticastMessage[] = [];

const sendEachForMulticastMock = jest.fn(
  (msg: MulticastMessage): Promise<MulticastResponse> => {
    sentMulticasts.push(msg);
    if (nextMulticastResponse)
      return Promise.resolve(nextMulticastResponse(msg));
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

let dispatchIntervention: typeof import('../dispatchIntervention.js').dispatchIntervention;

beforeAll(async () => {
  const mod = await import('../dispatchIntervention.js');
  dispatchIntervention = mod.dispatchIntervention;
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

type TierWire = 'one' | 'two' | 'three';

interface FakeCallableRequest {
  auth: { uid: string } | undefined;
  data: { v?: number; tier?: unknown; dispatchId?: unknown; requestId?: unknown };
}

function makeRequest(
  uid: string,
  tier: TierWire,
  dispatchId: string,
): FakeCallableRequest {
  return { auth: { uid }, data: { v: 1, tier, dispatchId } };
}

function seedAudit(
  uid: string,
  dispatchId: string,
  tier: TierWire,
  optedOut = false,
): void {
  docStore.set(`users/${uid}/interventions/${dispatchId}`, {
    dispatchId,
    tier,
    optedOut,
    quoteId: 'q-test',
    body: 'IRRELEVANT - should never appear in any push body',
    dispatchedAt: new Date(),
    cooldownUntil: new Date(),
    schemaV: 1,
  });
}

function seedSettings(uid: string, data: Record<string, unknown>): void {
  docStore.set(`users/${uid}/settings/notifications`, data);
}

async function invoke(req: FakeCallableRequest): Promise<unknown> {
  const handler = dispatchIntervention as unknown as (
    r: FakeCallableRequest,
  ) => Promise<unknown>;
  return handler(req);
}

function lastLog(): { level: string; payload: unknown } | undefined {
  return loggerCalls[loggerCalls.length - 1];
}

const ENABLED_ALL_TIERS = {
  cheerUpEnabled: true,
  tier1Enabled: true,
  tier2Enabled: true,
  tier3Enabled: true,
  tokens: [{ token: 'tok-A', platform: 'android' }],
};

// Locked per-tier copy - duplicated here on purpose so a future edit to
// the CF must also update this test, locking the public surface.
const LOCKED_PAYLOADS = {
  one: {
    title: 'Take a breath?',
    body: "MoodBloom noticed your week. A 2-minute breathing exercise is here if you'd like.",
  },
  two: {
    title: 'A few quiet words?',
    body: "MoodBloom noticed your week. A short journaling prompt is here if you'd like.",
  },
  three: {
    title: "We're here",
    body: "MoodBloom noticed your week. Some resources are here if you'd like to look.",
  },
} as const;

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('dispatchIntervention', () => {
  test('1. happy-path Tier 1 → locked title/body, channel cheer_up', async () => {
    seedAudit('uid-1', 'd-1', 'one');
    seedSettings('uid-1', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-1', 'one', 'd-1'));

    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);
    const msg = sentMulticasts[0];
    if (!msg) throw new Error('expected multicast');
    expect(msg.notification?.title).toBe(LOCKED_PAYLOADS.one.title);
    expect(msg.notification?.body).toBe(LOCKED_PAYLOADS.one.body);
    expect(msg.android?.notification?.channelId).toBe('cheer_up');
    expect(lastLog()?.payload).toMatchObject({
      outcome: 'sent',
      tier: 'one',
      deliveredCount: 1,
    });
  });

  test('2. happy-path Tier 2 → locked title/body for tier two', async () => {
    seedAudit('uid-2', 'd-2', 'two');
    seedSettings('uid-2', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-2', 'two', 'd-2'));

    const msg = sentMulticasts[0];
    if (!msg) throw new Error('expected multicast');
    expect(msg.notification?.title).toBe(LOCKED_PAYLOADS.two.title);
    expect(msg.notification?.body).toBe(LOCKED_PAYLOADS.two.body);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'sent', tier: 'two' });
  });

  test('3. happy-path Tier 3 FENCE → locked title/body for tier three, audit body NEVER appears', async () => {
    seedAudit('uid-3', 'd-3', 'three');
    seedSettings('uid-3', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-3', 'three', 'd-3'));

    const msg = sentMulticasts[0];
    if (!msg) throw new Error('expected multicast');
    expect(msg.notification?.title).toBe(LOCKED_PAYLOADS.three.title);
    expect(msg.notification?.body).toBe(LOCKED_PAYLOADS.three.body);
    // The audit doc carries body 'IRRELEVANT - should never appear...'
    // Defense in depth: assert the leaked-doc text is NOT in the push.
    expect(msg.notification?.body).not.toContain('IRRELEVANT');
    // Tier 3 must not contain a hotline number in the push body
    // (Hotline 1323 is the in-app surface only).
    expect(msg.notification?.body).not.toContain('1323');
    expect(lastLog()?.payload).toMatchObject({ outcome: 'sent', tier: 'three' });
  });

  test('4. unauthenticated → throws HttpsError', async () => {
    await expect(
      invoke({
        auth: undefined,
        data: { v: 1, tier: 'one', dispatchId: 'd-x' },
      }),
    ).rejects.toBeInstanceOf(FakeHttpsError);
    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
  });

  test('5. schema rejection - bad tier value throws HttpsError', async () => {
    await expect(
      invoke({
        auth: { uid: 'u' },
        data: { v: 1, tier: 'four', dispatchId: 'd-x' },
      }),
    ).rejects.toBeInstanceOf(FakeHttpsError);
    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
  });

  test('6. schema rejection - missing dispatchId throws HttpsError', async () => {
    await expect(
      invoke({ auth: { uid: 'u' }, data: { v: 1, tier: 'one' } }),
    ).rejects.toBeInstanceOf(FakeHttpsError);
    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
  });

  test('7. dispatch_missing - no audit doc → outcome=dispatch_missing, no FCM', async () => {
    seedSettings('uid-m', ENABLED_ALL_TIERS);
    // No seedAudit on purpose.

    await invoke(makeRequest('uid-m', 'one', 'd-missing'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'dispatch_missing' });
  });

  test('8. dispatch_mismatch - audit tier ≠ request tier → no FCM', async () => {
    seedAudit('uid-mm', 'd-mm', 'one');
    seedSettings('uid-mm', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-mm', 'two', 'd-mm'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'dispatch_mismatch' });
  });

  test('9. dispatch_opted_out - audit optedOut=true → no FCM', async () => {
    seedAudit('uid-oo', 'd-oo', 'three', /* optedOut */ true);
    seedSettings('uid-oo', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-oo', 'three', 'd-oo'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'dispatch_opted_out' });
  });

  test('10. opted_out - tier1Enabled=false for Tier 1 request', async () => {
    seedAudit('uid-t1', 'd-t1', 'one');
    seedSettings('uid-t1', {
      ...ENABLED_ALL_TIERS,
      tier1Enabled: false,
    });

    await invoke(makeRequest('uid-t1', 'one', 'd-t1'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'opted_out' });
  });

  test('10b. opted_out - settings doc missing entirely → no FCM', async () => {
    seedAudit('uid-no', 'd-no', 'two');
    // No settings doc.

    await invoke(makeRequest('uid-no', 'two', 'd-no'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(lastLog()?.payload).toMatchObject({ outcome: 'opted_out' });
  });

  test('11. no_tokens - settings ok, tier enabled, but tokens empty', async () => {
    seedAudit('uid-nt', 'd-nt', 'one');
    seedSettings('uid-nt', { ...ENABLED_ALL_TIERS, tokens: [] });

    await invoke(makeRequest('uid-nt', 'one', 'd-nt'));

    expect(sendEachForMulticastMock).not.toHaveBeenCalled();
    expect(rateLimitStore.size).toBe(0);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'no_tokens' });
  });

  test('12. rate_limited - second call within 24h is rate-limited', async () => {
    seedAudit('uid-rl', 'd-rl-1', 'one');
    seedAudit('uid-rl', 'd-rl-2', 'one');
    seedSettings('uid-rl', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-rl', 'one', 'd-rl-1'));
    await invoke(makeRequest('uid-rl', 'one', 'd-rl-2'));

    expect(sendEachForMulticastMock).toHaveBeenCalledTimes(1);
    expect(lastLog()?.payload).toMatchObject({ outcome: 'rate_limited' });
  });

  test('13. dead-token pruning - survivors written back without dead token', async () => {
    seedAudit('uid-dp', 'd-dp', 'two');
    seedSettings('uid-dp', {
      ...ENABLED_ALL_TIERS,
      tokens: [
        { token: 'tok-good', platform: 'android' },
        { token: 'tok-dead', platform: 'web' },
      ],
    });
    nextMulticastResponse = (msg) => ({
      successCount: 1,
      failureCount: 1,
      responses: msg.tokens.map((t) =>
        t === 'tok-dead'
          ? {
              success: false,
              error: { code: 'messaging/registration-token-not-registered' },
            }
          : { success: true },
      ),
    });

    await invoke(makeRequest('uid-dp', 'two', 'd-dp'));

    const stored = docStore.get('users/uid-dp/settings/notifications') as
      | { tokens?: { token: string }[] }
      | undefined;
    expect(stored?.tokens?.map((t) => t.token)).toEqual(['tok-good']);
    expect(lastLog()?.payload).toMatchObject({
      outcome: 'sent',
      prunedCount: 1,
    });
  });

  test('14. PII canary - neither title, body, nor token strings appear in any log payload', async () => {
    seedAudit('uid-pii', 'd-pii', 'three');
    seedSettings('uid-pii', {
      ...ENABLED_ALL_TIERS,
      tokens: [{ token: 'TOKEN-CANARY-XYZ', platform: 'android' }],
    });

    await invoke(makeRequest('uid-pii', 'three', 'd-pii'));

    for (const c of loggerCalls) {
      const json = JSON.stringify(c.payload);
      expect(json).not.toContain('TOKEN-CANARY-XYZ');
      expect(json).not.toContain(LOCKED_PAYLOADS.three.title);
      expect(json).not.toContain(LOCKED_PAYLOADS.three.body);
      expect(json).not.toContain('IRRELEVANT');
    }
  });

  test('15. channel-id literal - every multicast uses channelId=cheer_up', async () => {
    seedAudit('uid-ch', 'd-ch', 'one');
    seedSettings('uid-ch', ENABLED_ALL_TIERS);

    await invoke(makeRequest('uid-ch', 'one', 'd-ch'));

    expect(sentMulticasts[0]?.android?.notification?.channelId).toBe(
      'cheer_up',
    );
  });
});
