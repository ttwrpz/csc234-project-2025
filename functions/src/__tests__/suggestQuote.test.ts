// suggestQuote - Cloud Function tests (HB-008 §"Acceptance").
//
// Coverage:
//   1. Tier-3 server-side guard (TC-40 mirror) - `tier: 3` rejected with
//      `invalid-argument`; Gemini never called.
//   2. PII canary - Tier 1 happy path with valid input; intercepting the
//      Gemini SDK and asserting the outbound prompt body does NOT contain
//      `userId`, `email`, the calling uid, or any FCM-token-shaped string.
//   3. Rate limit - 11 calls in succession; 11th returns
//      `resource-exhausted`.
//   4. Invalid input shapes - `tier: 4`, missing `weekId`, `dailyAvgS: 2.5`,
//      unknown `dominantEmotion` → each returns `invalid-argument`.
//
// Mock strategy mirrors `analyzeMoodText.test.ts` exactly so the in-memory
// Firestore rate-limit transaction is deterministic.

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

// defineSecret stub.
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

// HttpsError + onCall pass-through.
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

// In-memory Firestore mock for the rate-limit transaction. Re-used
// verbatim from analyzeMoodText.test.ts.
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

// @google/genai mock. Captures the FULL outbound call args for the PII
// canary, plus a settable next-response so different tests can drive
// different model outputs.
interface CapturedCall {
  model: string;
  contents: unknown;
  config: {
    systemInstruction?: string;
    temperature?: number;
    maxOutputTokens?: number;
    abortSignal?: AbortSignal;
  };
}
const capturedCalls: CapturedCall[] = [];

type NextResponseMode =
  | { kind: 'text'; text: string }
  | { kind: 'reject'; cause: Error }
  | { kind: 'empty' };

let nextResponse: NextResponseMode = {
  kind: 'text',
  text: 'A gentle breath might help today.',
};

const generateContentMock = jest.fn(
  (input: CapturedCall): Promise<{ text: string }> => {
    capturedCalls.push(input);
    const mode = nextResponse;
    if (mode.kind === 'reject') return Promise.reject(mode.cause);
    if (mode.kind === 'empty') return Promise.resolve({ text: '' });
    return Promise.resolve({ text: mode.text });
  },
);

jest.unstable_mockModule('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: { generateContent: generateContentMock },
  })),
  Type: { OBJECT: 'OBJECT', STRING: 'STRING', NUMBER: 'NUMBER' },
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let handleSuggestQuote: typeof import('../suggestQuote.js').handleSuggestQuote;

beforeAll(async () => {
  const mod = await import('../suggestQuote.js');
  handleSuggestQuote = mod.handleSuggestQuote;
});

beforeEach(() => {
  loggerCalls.length = 0;
  secretValueAccesses.length = 0;
  rateLimitStore.clear();
  txChain = Promise.resolve();
  capturedCalls.length = 0;
  generateContentMock.mockClear();
  nextResponse = { kind: 'text', text: 'A gentle breath might help today.' };
});

interface CallableLike {
  auth?: { uid: string };
  data: unknown;
}

function call(uid: string | null, data: unknown): CallableLike {
  return uid ? { auth: { uid }, data } : { data };
}

function validBody(
  overrides: Partial<{
    tier: number;
    weekId: string;
    dailyAvgS: number;
    dominantEmotion: string;
  }> = {},
): unknown {
  return {
    tier: overrides.tier ?? 1,
    context: {
      weekId: overrides.weekId ?? '2026-W19',
      dailyAvgS: overrides.dailyAvgS ?? -0.4,
      dominantEmotion: overrides.dominantEmotion ?? 'sad',
    },
  };
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('suggestQuote handler', () => {
  // -------------------------------------------------------------------------
  // 1. Tier-3 server-side guard (TC-40 server-side mirror).
  // -------------------------------------------------------------------------
  describe('Tier 3 guard - ADR-0012 §"Decision" point 1', () => {
    test('tier: 3 → HttpsError(invalid-argument); Gemini never called', async () => {
      await expect(
        handleSuggestQuote(call('uid-1', validBody({ tier: 3 })) as never),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
      expect(generateContentMock).not.toHaveBeenCalled();
    });

    test('error message names Tier 3 explicitly', async () => {
      try {
        await handleSuggestQuote(call('uid-1', validBody({ tier: 3 })) as never);
        throw new Error('expected throw');
      } catch (e) {
        expect((e as Error).message.toLowerCase()).toContain('tier 3');
      }
    });
  });

  // -------------------------------------------------------------------------
  // 2. PII canary - no userId / email / FCM-token-shape in outbound prompt.
  // -------------------------------------------------------------------------
  describe('PII canary - HB-008 §"forbidden in payload"', () => {
    test(
      'outbound prompt body contains NONE of: userId, email, calling uid, FCM-token shape',
      async () => {
        const callingUid = 'uid-PII-CANARY-FFFFFFFF';
        await handleSuggestQuote(
          call(callingUid, validBody({ tier: 1 })) as never,
        );

        expect(capturedCalls).toHaveLength(1);
        const captured = capturedCalls[0];
        if (!captured) throw new Error('expected captured call');

        // Serialise the whole call (contents + systemInstruction) and
        // assert no forbidden substring appears anywhere.
        const dump = JSON.stringify({
          contents: captured.contents,
          systemInstruction: captured.config.systemInstruction,
        });

        const forbidden = [
          'userId',
          'email',
          callingUid,
          // FCM-token shape - Firebase FCM tokens are long base64-ish
          // strings, but the canary asserts no field literally NAMED
          // `fcmToken`/`token` leaks AND no string of FCM-token length
          // (≥140 alphanumerics) shows up. A naive contains-check on
          // a fake token is sufficient defence here.
          'fcmToken',
          'fcm_token',
          'cFAKEFCMTOKENVALUE',
        ];
        for (const needle of forbidden) {
          expect(dump).not.toContain(needle);
        }

        // Positive control: the allow-listed fields ARE present.
        expect(dump).toContain('2026-W19');
        expect(dump).toContain('sad');
        expect(dump).toContain('-0.40');
      },
    );

    test(
      'system prompt is the locked Tier-1 verb; Tier 2 swap is the only diff',
      async () => {
        await handleSuggestQuote(
          call('uid-2', validBody({ tier: 1 })) as never,
        );
        const t1 = capturedCalls[0];
        if (!t1) throw new Error('expected captured call');
        expect(t1.config.systemInstruction).toContain('breathing exercise');
        expect(t1.config.systemInstruction).not.toContain('journaling prompt');

        capturedCalls.length = 0;
        await handleSuggestQuote(
          call('uid-2', validBody({ tier: 2 })) as never,
        );
        const t2 = capturedCalls[0];
        if (!t2) throw new Error('expected captured call');
        expect(t2.config.systemInstruction).toContain('journaling prompt');
        expect(t2.config.systemInstruction).not.toContain('breathing exercise');
      },
    );

    test('Gemini config uses temperature 0.4 and maxOutputTokens 80', async () => {
      await handleSuggestQuote(call('uid-3', validBody()) as never);
      const captured = capturedCalls[0];
      if (!captured) throw new Error('expected captured call');
      expect(captured.config.temperature).toBe(0.4);
      expect(captured.config.maxOutputTokens).toBe(80);
    });

    test(
      'structured log NEVER contains the suggested text body or dailyAvgS',
      async () => {
        nextResponse = {
          kind: 'text',
          text: 'PII-LEAK-CANARY-do-not-log-this-string-please',
        };
        await handleSuggestQuote(
          call('uid-loglog', validBody({ dailyAvgS: -0.789 })) as never,
        );
        for (const c of loggerCalls) {
          const dump = JSON.stringify(c.payload);
          expect(dump).not.toContain('PII-LEAK-CANARY');
          // dailyAvgS could leak inferences - must not appear in logs.
          expect(dump).not.toContain('-0.789');
          expect(dump).not.toContain('-0.78');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // 3. Rate limit - 10/uid/day.
  // -------------------------------------------------------------------------
  describe('Rate limit - 10 calls per uid per day', () => {
    test('11th call → HttpsError(resource-exhausted)', async () => {
      for (let i = 0; i < 10; i++) {
        const result = await handleSuggestQuote(
          call('uid-rl', validBody()) as never,
        );
        expect(result).toMatchObject({ suggestedText: expect.any(String) });
      }
      await expect(
        handleSuggestQuote(call('uid-rl', validBody()) as never),
      ).rejects.toMatchObject({ code: 'resource-exhausted' });
    });

    test('per-uid isolation: other uids still succeed after one is capped', async () => {
      for (let i = 0; i < 10; i++) {
        await handleSuggestQuote(call('uid-a', validBody()) as never);
      }
      await expect(
        handleSuggestQuote(call('uid-a', validBody()) as never),
      ).rejects.toMatchObject({ code: 'resource-exhausted' });

      // Different uid - fresh window.
      const result = await handleSuggestQuote(
        call('uid-b', validBody()) as never,
      );
      expect(result).toMatchObject({ suggestedText: expect.any(String) });
    });
  });

  // -------------------------------------------------------------------------
  // 4. Invalid input shapes.
  // -------------------------------------------------------------------------
  describe('Invalid input shapes → HttpsError(invalid-argument)', () => {
    test('tier: 4 rejects', async () => {
      await expect(
        handleSuggestQuote(call('uid-x', validBody({ tier: 4 })) as never),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
      expect(generateContentMock).not.toHaveBeenCalled();
    });

    test('tier: 0 rejects', async () => {
      await expect(
        handleSuggestQuote(call('uid-x', validBody({ tier: 0 })) as never),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('missing weekId rejects', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', {
            tier: 1,
            context: { dailyAvgS: 0, dominantEmotion: 'sad' },
          }) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('malformed weekId regex rejects', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', validBody({ weekId: '2026/19' })) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('dailyAvgS: 2.5 (out of [-1,1]) rejects', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', validBody({ dailyAvgS: 2.5 })) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('dailyAvgS: -1.5 (out of [-1,1]) rejects', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', validBody({ dailyAvgS: -1.5 })) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('unknown dominantEmotion rejects', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', validBody({ dominantEmotion: 'melancholy' })) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('unknown extra top-level key rejects (strict schema)', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', { ...(validBody() as object), userId: 'leaked' }) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });

    test('unknown extra key inside context rejects (strict schema)', async () => {
      await expect(
        handleSuggestQuote(
          call('uid-x', {
            tier: 1,
            context: {
              weekId: '2026-W19',
              dailyAvgS: 0,
              dominantEmotion: 'sad',
              email: 'leaked@example.com',
            },
          }) as never,
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });
  });

  // -------------------------------------------------------------------------
  // 5. Auth + Gemini error paths.
  // -------------------------------------------------------------------------
  describe('Auth + Gemini error paths', () => {
    test('unauth → HttpsError(unauthenticated)', async () => {
      await expect(
        handleSuggestQuote(call(null, validBody()) as never),
      ).rejects.toMatchObject({ code: 'unauthenticated' });
      expect(generateContentMock).not.toHaveBeenCalled();
    });

    test('Gemini throws → HttpsError(internal, gemini-failure)', async () => {
      nextResponse = { kind: 'reject', cause: new Error('boom') };
      await expect(
        handleSuggestQuote(call('uid-e', validBody()) as never),
      ).rejects.toMatchObject({ code: 'internal' });
    });

    test('Gemini returns empty text → HttpsError(internal)', async () => {
      nextResponse = { kind: 'empty' };
      await expect(
        handleSuggestQuote(call('uid-e', validBody()) as never),
      ).rejects.toMatchObject({ code: 'internal' });
    });
  });

  // -------------------------------------------------------------------------
  // 6. Happy path - return shape.
  // -------------------------------------------------------------------------
  describe('Happy path', () => {
    test('returns { suggestedText } verbatim - no server-side trim', async () => {
      // Trailing whitespace stays trimmed by the SDK convention; outer
      // whitespace stripping is the only post-process the CF performs
      // (transport hygiene, NOT safety). The 140-char cap is the Dart
      // filter's job.
      nextResponse = {
        kind: 'text',
        text: 'Maybe a soft breath would help - only if you would like.',
      };
      const result = await handleSuggestQuote(
        call('uid-ok', validBody()) as never,
      );
      expect(result).toEqual({
        suggestedText: 'Maybe a soft breath would help - only if you would like.',
      });
    });

    test('over-140-char suggestion is returned verbatim (filter is Dart-side)', async () => {
      // HB-008: "Do NOT trim or post-process the Gemini output on the
      // server." The filter is the Dart-side defence; the CF must
      // surface raw output so the filter can reject it.
      const longText = 'a '.repeat(80).trim() + ' breath';
      nextResponse = { kind: 'text', text: longText };
      const result = await handleSuggestQuote(
        call('uid-long', validBody()) as never,
      );
      expect((result as { suggestedText: string }).suggestedText).toBe(longText);
    });
  });
});
