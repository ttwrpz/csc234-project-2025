// 10-case test suite for analyzePatterns. Cases mirror ADR-0007 §"Test plan"
// and the Sprint 4 plan §"Server tests".
//
// Strategy: same harness shape as analyzeMoodText.test.ts —
//  - Mock `firebase-functions/logger` so we can assert log payloads.
//  - Mock `firebase-admin/firestore` with an in-memory rate-limiter store.
//  - Mock `firebase-functions/v2/https` so handler is callable directly.
//  - Mock `firebase-functions/params` so `defineSecret` is a no-op.
//
// We do NOT exercise `@google/genai` because S4 ships with Gemini
// supplementary calls disabled (geminiSkipped: true). The mock below
// is a structural stub so the SDK module resolves at import time;
// real Gemini-mode tests land in the follow-up patch that wires the
// supplementary call.

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Mocks
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

jest.unstable_mockModule('firebase-functions/params', () => ({
  defineSecret: (name: string) => ({ name, value: () => 'TEST-API-KEY' }),
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

type RLDoc = { windowStartMs: number; count: number; expireAt: number };
const rateLimitStore = new Map<string, RLDoc>();
let txChain: Promise<unknown> = Promise.resolve();
const firestoreMock = {
  doc(path: string) {
    return {
      _path: path,
      get _key() {
        return path;
      },
    };
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

jest.unstable_mockModule('@google/genai', () => ({
  GoogleGenAI: jest.fn(),
  Type: { OBJECT: 'OBJECT', STRING: 'STRING', NUMBER: 'NUMBER' },
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let handleAnalyzePatterns: typeof import('../analyzePatterns.js').handleAnalyzePatterns;

beforeAll(async () => {
  const mod = await import('../analyzePatterns.js');
  handleAnalyzePatterns = mod.handleAnalyzePatterns;
});

beforeEach(() => {
  loggerCalls.length = 0;
  rateLimitStore.clear();
  txChain = Promise.resolve();
});

interface CallableLike {
  auth: { uid: string } | null;
  data: unknown;
}
function makeRequest(uid: string | null, data: unknown): CallableLike {
  return {
    auth: uid === null ? null : { uid },
    data,
  };
}

interface HistoryItem {
  date: string;
  moodCode: 'happy' | 'calm' | 'okay' | 'sad' | 'angry' | 'anxious';
  intensity: number;
}
function makeRequestData(
  history: HistoryItem[],
  overrides: Partial<{ requestId: string; v: 1; windowDays: number }> = {},
): Record<string, unknown> {
  return {
    requestId:
      overrides.requestId ?? '11111111-2222-3333-4444-555555555555',
    v: overrides.v ?? 1,
    windowDays: overrides.windowDays ?? 90,
    history,
  };
}

/** Build a strong-Monday-bias 90-day history. */
function strongMondayHistory(): HistoryItem[] {
  // Build 60 negative entries: 30 Monday (intensity 5), 30 spread across
  // other weekdays (intensity 1).
  const out: HistoryItem[] = [];
  const start = new Date('2026-01-01T00:00:00Z'); // Thursday
  for (let i = 0; i < 90; i += 1) {
    const d = new Date(start);
    d.setUTCDate(d.getUTCDate() + i);
    const iso = d.toISOString().slice(0, 10);
    if (d.getUTCDay() === 1) {
      out.push({ date: iso, moodCode: 'sad', intensity: 5 });
    } else if (d.getUTCDay() === 4 || d.getUTCDay() === 5) {
      out.push({ date: iso, moodCode: 'sad', intensity: 1 });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('analyzePatterns handler', () => {
  test('1. unauth → HttpsError(unauthenticated)', async () => {
    await expect(
      handleAnalyzePatterns(
        makeRequest(null, makeRequestData([])) as unknown as Parameters<
          typeof handleAnalyzePatterns
        >[0],
      ),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  test('2. Zod-strict reject of `text` field at any nesting → invalid_input', async () => {
    const data = {
      ...makeRequestData([]),
      text: 'leaked PII',
    };
    const res = await handleAnalyzePatterns(
      makeRequest('uid-1', data) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: false, code: 'invalid_input' });
  });

  test('2b. Zod-strict reject of `text` inside a history entry → invalid_input', async () => {
    const data: Record<string, unknown> = {
      requestId: '11111111-2222-3333-4444-555555555555',
      v: 1,
      windowDays: 90,
      history: [
        {
          date: '2026-04-01',
          moodCode: 'sad',
          intensity: 3,
          text: 'sneaky text', // forbidden — must be rejected by .strict()
        },
      ],
    };
    const res = await handleAnalyzePatterns(
      makeRequest('uid-1', data) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: false, code: 'invalid_input' });
  });

  test('3. rate-limit exceeded → second call within 30s returns rate_limited with retryAfterSec', async () => {
    const req = makeRequest('uid-rate', makeRequestData([])) as unknown as Parameters<
      typeof handleAnalyzePatterns
    >[0];
    const first = await handleAnalyzePatterns(req);
    expect(first).toMatchObject({ ok: true });

    const second = await handleAnalyzePatterns(req);
    expect(second).toMatchObject({
      ok: false,
      code: 'rate_limited',
    });
    if (second.ok === false) {
      expect(second.retryAfterSec).toBeGreaterThanOrEqual(1);
      expect(second.retryAfterSec).toBeLessThanOrEqual(30);
    }
  });

  test('4. statistical happy path — strong Monday bias yields a weekday insight, geminiSkipped: flag_disabled', async () => {
    const res = await handleAnalyzePatterns(
      makeRequest('uid-stat', makeRequestData(strongMondayHistory())) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;

    expect(res.insights.length).toBeGreaterThanOrEqual(1);
    const wkd = res.insights.find((i) => i.kind === 'weekday');
    expect(wkd).toBeTruthy();
    expect(wkd!.text).toContain('Monday');
    expect(wkd!.confidence).toBeGreaterThan(0);
    expect(wkd!.confidence).toBeLessThanOrEqual(1);
    expect(wkd!.sampleSize).toBeGreaterThanOrEqual(10);

    expect(res.modelVersion).toBeNull();

    const successLog = loggerCalls.find(
      (c) =>
        typeof c.payload === 'object' &&
        c.payload !== null &&
        'event' in c.payload &&
        (c.payload as { event: string }).event === 'analyzePatterns' &&
        'outcome' in c.payload &&
        (c.payload as { outcome: string }).outcome === 'success',
    );
    expect(successLog).toBeTruthy();
    expect((successLog!.payload as { geminiSkipped: boolean }).geminiSkipped).toBe(true);
    expect((successLog!.payload as { geminiSkipReason: string }).geminiSkipReason).toBe(
      'flag_disabled',
    );
  });

  test('5. sample-size floor — weekday with n < 10 yields no weekday insight', async () => {
    // Only 5 sad-intensity-5 Mondays in a 60-day window → floor blocks it.
    const start = new Date('2026-01-01T00:00:00Z');
    const history: HistoryItem[] = [];
    let mondays = 0;
    for (let i = 0; i < 60 && mondays < 5; i += 1) {
      const d = new Date(start);
      d.setUTCDate(d.getUTCDate() + i);
      if (d.getUTCDay() === 1) {
        history.push({
          date: d.toISOString().slice(0, 10),
          moodCode: 'sad',
          intensity: 5,
        });
        mondays += 1;
      } else if (d.getUTCDay() === 4) {
        history.push({
          date: d.toISOString().slice(0, 10),
          moodCode: 'sad',
          intensity: 1,
        });
      }
    }

    const res = await handleAnalyzePatterns(
      makeRequest('uid-floor', makeRequestData(history)) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;
    expect(res.insights.find((i) => i.kind === 'weekday')).toBeUndefined();
  });

  test('6. 3-day streak insight fires for ≥3 consecutive heavy negative days', async () => {
    const history: HistoryItem[] = [
      { date: '2026-04-25', moodCode: 'angry', intensity: 5 },
      { date: '2026-04-26', moodCode: 'anxious', intensity: 4 },
      { date: '2026-04-27', moodCode: 'sad', intensity: 5 },
      { date: '2026-04-28', moodCode: 'angry', intensity: 4 },
    ];
    const res = await handleAnalyzePatterns(
      makeRequest('uid-streak', makeRequestData(history)) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;

    const streak = res.insights.find((i) => i.kind === 'streak');
    expect(streak).toBeTruthy();
    expect(streak!.text).toContain('three or more heavy days');
    expect(streak!.sampleSize).toBeGreaterThanOrEqual(3);
  });

  test('7. trend insight requires n ≥ 14 distinct days; below threshold returns nothing', async () => {
    const history: HistoryItem[] = [
      { date: '2026-04-01', moodCode: 'sad', intensity: 1 },
      { date: '2026-04-05', moodCode: 'sad', intensity: 2 },
      { date: '2026-04-10', moodCode: 'sad', intensity: 3 },
      { date: '2026-04-15', moodCode: 'sad', intensity: 4 },
      { date: '2026-04-20', moodCode: 'sad', intensity: 5 },
    ];
    const res = await handleAnalyzePatterns(
      makeRequest('uid-trend-low', makeRequestData(history)) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;
    expect(res.insights.find((i) => i.kind === 'trend')).toBeUndefined();
  });

  test('8. trend insight emerges when slope crosses threshold over ≥14 days', async () => {
    // 20 days, intensity climbing from 1 to ~5 → slope ≈ 4/19 ≈ 0.21 > 0.05.
    const start = new Date('2026-04-01T00:00:00Z');
    const history: HistoryItem[] = [];
    for (let i = 0; i < 20; i += 1) {
      const d = new Date(start);
      d.setUTCDate(d.getUTCDate() + i);
      history.push({
        date: d.toISOString().slice(0, 10),
        moodCode: 'sad',
        intensity: Math.min(5, 1 + Math.floor(i / 5)),
      });
    }
    const res = await handleAnalyzePatterns(
      makeRequest('uid-trend-up', makeRequestData(history)) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;
    const trend = res.insights.find((i) => i.kind === 'trend');
    expect(trend).toBeTruthy();
    expect(trend!.text).toContain('trending up');
    expect(trend!.sampleSize).toBeGreaterThanOrEqual(14);
  });

  test('9. empty history → 0 insights, success envelope, no Gemini call', async () => {
    const res = await handleAnalyzePatterns(
      makeRequest('uid-empty', makeRequestData([])) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );
    expect(res).toMatchObject({ ok: true });
    if (res.ok === false) return;
    expect(res.insights).toEqual([]);
    expect(res.modelVersion).toBeNull();
  });

  test('10. PII canary — no payload contains a date string from history or insight body text', async () => {
    const history: HistoryItem[] = [
      { date: '2026-03-15', moodCode: 'sad', intensity: 5 },
      { date: '2026-03-16', moodCode: 'sad', intensity: 5 },
      { date: '2026-03-17', moodCode: 'sad', intensity: 5 },
    ];
    await handleAnalyzePatterns(
      makeRequest('uid-pii', makeRequestData(history)) as unknown as Parameters<
        typeof handleAnalyzePatterns
      >[0],
    );

    for (const call of loggerCalls) {
      const serialised = JSON.stringify(call.payload);
      // Date prefixes — would indicate `history[].date` leaked.
      expect(serialised).not.toContain('2026-03-15');
      expect(serialised).not.toContain('2026-03-16');
      expect(serialised).not.toContain('2026-03-17');
      // Insight body strings.
      expect(serialised).not.toContain('three or more heavy days');
      expect(serialised).not.toContain('averages');
      expect(serialised).not.toContain('trending');
      // Forbidden field names (sanity check on the log allowlist).
      expect(serialised).not.toContain('"history"');
      expect(serialised).not.toContain('"text"');
      expect(serialised).not.toContain('"mediaRefs"');
    }
  });
});
