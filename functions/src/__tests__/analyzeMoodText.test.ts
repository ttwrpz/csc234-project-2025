// 14-case test suite for analyzeMoodText. Cases mirror ADR-0003 §"Test plan".
//
// Strategy:
//  - Mock `@google/generative-ai` so we control Gemini's reply (and timing).
//  - Mock `firebase-admin/firestore` so the rate-limit transaction is in-memory
//    and deterministic (no emulator needed for these unit tests).
//  - Spy `firebase-functions/logger.*` so we can assert log payloads.
//  - Spy `process.env` access so case #14 can prove we never read
//    `GEMINI_API_KEY` from the environment directly.

import { jest } from '@jest/globals';

// ---------------------------------------------------------------------------
// Mocks (must be set up before importing the module under test)
// ---------------------------------------------------------------------------

// Capture logger calls for assertions.
const loggerCalls: { level: string; payload: unknown }[] = [];
jest.unstable_mockModule('firebase-functions/logger', () => ({
  info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
  warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
  error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
  debug: (payload: unknown) => loggerCalls.push({ level: 'debug', payload }),
  log: (payload: unknown) => loggerCalls.push({ level: 'log', payload }),
}));

// `firebase-functions` re-exports `logger` from a barrel; mock it too.
jest.unstable_mockModule('firebase-functions', () => ({
  logger: {
    info: (payload: unknown) => loggerCalls.push({ level: 'info', payload }),
    warn: (payload: unknown) => loggerCalls.push({ level: 'warn', payload }),
    error: (payload: unknown) => loggerCalls.push({ level: 'error', payload }),
    debug: (payload: unknown) => loggerCalls.push({ level: 'debug', payload }),
    log: (payload: unknown) => loggerCalls.push({ level: 'log', payload }),
  },
}));

// Stub `defineSecret` so .value() returns a fixed test key without process.env.
const secretValueAccesses: string[] = [];
jest.unstable_mockModule('firebase-functions/params', () => ({
  defineSecret: (name: string) => ({
    name,
    value: () => {
      secretValueAccesses.push(name);
      return 'TEST-API-KEY';
    },
  }),
}));

// HttpsError + onCall stubs from firebase-functions/v2/https.
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
  // Pass through to the handler - we exercise handleAnalyzeMoodText directly.
  onCall: (_opts: unknown, handler: unknown) => handler,
}));

// In-memory Firestore mock for the rate-limit transaction.
// We serialise runTransaction calls behind a mutex chain to mirror Firestore's
// effective serializable behavior (optimistic concurrency + retry collapses to
// "one transaction commits at a time per contended doc set"). Without this,
// concurrent calls would all read the same baseline and all succeed,
// invalidating case #6.
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
      get: (ref: { _key: string }) => Promise<{ exists: boolean; data: () => RLDoc | undefined }>;
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
          if (!base) {
            throw new Error('update on missing doc');
          }
          writes.set(ref._key, { ...base, ...patch });
        },
      };
      const result = await fn(tx);
      for (const [k, v] of writes) {
        rateLimitStore.set(k, v);
      }
      return result;
    });
    txChain = next.catch(() => undefined);
    return next;
  },
};
jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
}));

// `@google/genai` mock with a settable next-response. The new SDK shape:
// `ai.models.generateContent({ model, contents, config })` returns
// `GenerateContentResponse` with a `.text` getter (string, not method)
// and `.usageMetadata`. The abort signal lives at `config.abortSignal`
// instead of the legacy second-arg `options.signal`.
type NextResponseMode =
  | { kind: 'json'; payload: unknown; latencyMs?: number }
  | { kind: 'syntaxError' }
  | { kind: 'reject'; cause: Error }
  | { kind: 'delay'; ms: number; payload: unknown };
let nextResponse: NextResponseMode = {
  kind: 'json',
  payload: {
    mood: 'happy',
    confidence: 0.9,
    alternative: null,
    rationale: 'Default test rationale.',
    flag: null,
  },
};

interface GenerateContentInput {
  model: string;
  contents: unknown;
  config?: { abortSignal?: AbortSignal };
}
interface GenerateContentMockResponse {
  text: string;
  usageMetadata: { promptTokenCount: number; candidatesTokenCount: number };
}

const generateContentMock = jest.fn(
  async (input: GenerateContentInput): Promise<GenerateContentMockResponse> => {
    const mode = nextResponse;
    const signal = input.config?.abortSignal;
    if (mode.kind === 'syntaxError') {
      // Simulate the SDK successfully returning text but text is not JSON.
      return {
        text: 'this is not json {{{',
        usageMetadata: { promptTokenCount: 50, candidatesTokenCount: 30 },
      };
    }
    if (mode.kind === 'reject') {
      throw mode.cause;
    }
    if (mode.kind === 'delay') {
      await new Promise<void>((resolve, reject) => {
        const t = setTimeout(() => resolve(), mode.ms);
        signal?.addEventListener('abort', () => {
          clearTimeout(t);
          reject(new Error('aborted'));
        });
      });
      return {
        text: JSON.stringify(mode.payload),
        usageMetadata: { promptTokenCount: 50, candidatesTokenCount: 30 },
      };
    }
    if (mode.latencyMs !== undefined) {
      await new Promise<void>((resolve) => setTimeout(resolve, mode.latencyMs));
    }
    return {
      text: JSON.stringify(mode.payload),
      usageMetadata: { promptTokenCount: 50, candidatesTokenCount: 30 },
    };
  },
);

jest.unstable_mockModule('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: {
      generateContent: generateContentMock,
    },
  })),
  Type: {
    OBJECT: 'OBJECT',
    STRING: 'STRING',
    NUMBER: 'NUMBER',
  },
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let handleAnalyzeMoodText: typeof import('../analyzeMoodText.js').handleAnalyzeMoodText;

beforeAll(async () => {
  // Import AFTER mocks so the module-under-test wires to the mocks.
  const mod = await import('../analyzeMoodText.js');
  handleAnalyzeMoodText = mod.handleAnalyzeMoodText;
});

beforeEach(() => {
  loggerCalls.length = 0;
  secretValueAccesses.length = 0;
  rateLimitStore.clear();
  txChain = Promise.resolve();
  generateContentMock.mockClear();
  nextResponse = {
    kind: 'json',
    payload: {
      mood: 'happy',
      confidence: 0.9,
      alternative: null,
      rationale: 'Default test rationale.',
      flag: null,
    },
  };
});

interface CallableLike {
  auth?: { uid: string };
  data: unknown;
}

function call(uid: string | null, data: unknown): CallableLike {
  return uid ? { auth: { uid }, data } : { data };
}

function uuid(): string {
  // RFC 4122 v4-shape literal - Zod only needs format, not entropy.
  return '00000000-0000-4000-8000-000000000000';
}

function validBody(text: string): { text: string; requestId: string; v: 1 } {
  return { text, requestId: uuid(), v: 1 };
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('analyzeMoodText handler', () => {
  // 1. unauth → throws HttpsError('unauthenticated').
  test('1. unauth → HttpsError(unauthenticated)', async () => {
    await expect(
      handleAnalyzeMoodText(call(null, validBody('hello')) as never),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  // 2. Schema invalid (missing text) → invalid_input.
  test('2. missing text → invalid_input', async () => {
    const res = await handleAnalyzeMoodText(
      call('u1', { requestId: uuid(), v: 1 }) as never,
    );
    expect(res).toMatchObject({ ok: false, code: 'invalid_input' });
  });

  // 3a. length 0 → invalid_input. 3b. length 501 → invalid_input. 3c. length 500 → success.
  test('3a. length 0 → invalid_input', async () => {
    const res = await handleAnalyzeMoodText(call('u1', validBody('')) as never);
    expect(res).toMatchObject({ ok: false, code: 'invalid_input' });
  });

  test('3b. length 501 → invalid_input', async () => {
    const res = await handleAnalyzeMoodText(
      call('u1', validBody('a'.repeat(501))) as never,
    );
    expect(res).toMatchObject({ ok: false, code: 'invalid_input' });
  });

  test('3c. length 500 → success', async () => {
    const res = await handleAnalyzeMoodText(
      call('u1', validBody('a'.repeat(500))) as never,
    );
    expect(res).toMatchObject({ ok: true, mood: 'happy' });
  });

  // 4. 11th call in 60s → rate_limited with retryAfterSec ∈ [1, 60].
  test('4. 11th call → rate_limited with retryAfterSec in [1,60]', async () => {
    for (let i = 0; i < 10; i++) {
      const ok = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
      expect((ok as { ok: boolean }).ok).toBe(true);
    }
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: false, code: 'rate_limited' });
    const retry = (res as { retryAfterSec?: number }).retryAfterSec ?? 0;
    expect(retry).toBeGreaterThanOrEqual(1);
    expect(retry).toBeLessThanOrEqual(60);
  });

  // 5. Window rollover → next call succeeds.
  test('5. window rollover → next call succeeds', async () => {
    for (let i = 0; i < 10; i++) {
      await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    }
    // Force the rate-limit doc's window into the past.
    const doc = rateLimitStore.get('rateLimits/u1');
    expect(doc).toBeDefined();
    if (doc) {
      doc.windowStartMs = Date.now() - 61_000;
      rateLimitStore.set('rateLimits/u1', doc);
    }
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: true });
  });

  // 6. 15 concurrent calls → exactly 10 succeed.
  test('6. 15 concurrent calls → exactly 10 succeed', async () => {
    const calls = Array.from({ length: 15 }, () =>
      handleAnalyzeMoodText(call('u1', validBody('concurrent')) as never),
    );
    const results = await Promise.all(calls);
    const successes = results.filter((r) => (r as { ok: boolean }).ok).length;
    const limited = results.filter(
      (r) => (r as { ok: boolean; code?: string }).ok === false &&
        (r as { code?: string }).code === 'rate_limited',
    ).length;
    expect(successes).toBe(10);
    expect(limited).toBe(5);
  });

  // 7. Happy path → success shape; latencyGeminiMs set on the success log.
  test('7. happy path → success envelope + latencyGeminiMs logged', async () => {
    nextResponse = {
      kind: 'json',
      latencyMs: 5,
      payload: {
        mood: 'calm',
        confidence: 0.7,
        alternative: { mood: 'happy', confidence: 0.4 },
        rationale: 'Themes of rest.',
        flag: null,
      },
    };
    const res = await handleAnalyzeMoodText(
      call('u1', validBody('went for a walk and felt calm')) as never,
    );
    expect(res).toMatchObject({
      ok: true,
      v: 1,
      mood: 'calm',
      confidence: 0.7,
      alternative: { mood: 'happy', confidence: 0.4 },
      rationale: 'Themes of rest.',
      modelVersion: 'gemini-2.5-flash',
    });
    const successLog = loggerCalls.find(
      (c) => (c.payload as { outcome?: string }).outcome === 'success',
    );
    expect(successLog).toBeDefined();
    expect((successLog!.payload as { latencyGeminiMs?: number }).latencyGeminiMs).toBeGreaterThanOrEqual(0);
  });

  // 8. Gemini hallucinates mood → parse_error.
  test('8. hallucinated mood → parse_error', async () => {
    nextResponse = {
      kind: 'json',
      payload: {
        mood: 'melancholy', // not in enum
        confidence: 0.8,
        alternative: null,
        rationale: 'x',
        flag: null,
      },
    };
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: false, code: 'parse_error' });
  });

  // 9. Confidence 1.4 → clamped to 1.0; log emits confidence_clamped.
  test('9. confidence 1.4 → clamped to 1.0 + confidence_clamped logged', async () => {
    nextResponse = {
      kind: 'json',
      payload: {
        mood: 'happy',
        confidence: 1.4,
        alternative: null,
        rationale: 'x',
        flag: null,
      },
    };
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: true, confidence: 1.0 });
    const successLog = loggerCalls.find(
      (c) => (c.payload as { outcome?: string }).outcome === 'success',
    );
    expect(successLog).toBeDefined();
    expect((successLog!.payload as { confidence_clamped?: boolean }).confidence_clamped).toBe(true);
  });

  // 10. Gemini SyntaxError → parse_error.
  test('10. JSON syntax error from model → parse_error', async () => {
    nextResponse = { kind: 'syntaxError' };
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: false, code: 'parse_error' });
  });

  // 11. Gemini 6s delay → aborts at 5s → gemini_unavailable.
  test('11. 6s gemini → abort at 5s → gemini_unavailable', async () => {
    nextResponse = {
      kind: 'delay',
      ms: 6_000,
      payload: {
        mood: 'happy',
        confidence: 0.5,
        alternative: null,
        rationale: 'x',
        flag: null,
      },
    };
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({ ok: false, code: 'gemini_unavailable' });
  }, 12_000);

  // 12. Self-harm flag passthrough.
  test('12. self_harm_safety flag passthrough', async () => {
    nextResponse = {
      kind: 'json',
      payload: {
        mood: 'okay',
        confidence: 0.2,
        alternative: null,
        rationale: 'Themes of self-harm risk.',
        flag: 'self_harm_safety',
      },
    };
    const res = await handleAnalyzeMoodText(call('u1', validBody('hi')) as never);
    expect(res).toMatchObject({
      ok: true,
      mood: 'okay',
      flag: 'self_harm_safety',
    });
  });

  // 13. PII canary - input contains "PII-CANARY-12345"; assert no logger.* call's
  //     serialized payload contains the canary.
  test('13. PII canary never appears in any logger payload', async () => {
    const canary = 'PII-CANARY-12345';
    nextResponse = {
      kind: 'json',
      payload: {
        mood: 'sad',
        confidence: 0.8,
        alternative: null,
        // The model's rationale must NOT be logged either; include canary here too
        // to assert the rationale field is dropped from the structured log.
        rationale: `themes including ${canary}`,
        flag: null,
      },
    };
    await handleAnalyzeMoodText(
      call('u1', validBody(`I felt awful today, ${canary}`)) as never,
    );
    for (const c of loggerCalls) {
      const serialized = JSON.stringify(c.payload);
      expect(serialized).not.toContain(canary);
    }
  });

  // 14. Secret loaded via defineSecret(...).value(), never process.env direct read.
  test('14. secret loaded via defineSecret, never via process.env', async () => {
    // Monitor any direct read of GEMINI_API_KEY from process.env.
    const originalEnv = process.env;
    const accesses: string[] = [];
    const proxied = new Proxy(originalEnv, {
      get(target, prop, receiver) {
        if (prop === 'GEMINI_API_KEY') {
          accesses.push(String(prop));
        }
        return Reflect.get(target, prop, receiver);
      },
    });
    Object.defineProperty(process, 'env', { value: proxied, configurable: true });
    try {
      await handleAnalyzeMoodText(call('u1', validBody('hello')) as never);
      expect(accesses).toEqual([]);
      expect(secretValueAccesses).toContain('GEMINI_API_KEY');
    } finally {
      Object.defineProperty(process, 'env', { value: originalEnv, configurable: true });
    }
  });
});
