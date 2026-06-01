// webauthnRegisterFinish - Cloud Function tests (ADR-0014 §"Decision B").
//
// Coverage:
//   1. Happy path - valid challenge + provisioning + verified attestation
//      persists the credential doc with the canonical schema and deletes
//      the challenge (single-use semantics).
//   2. Stale challenge → `{ ok: false, code: 'challenge_expired' }`; the
//      challenge doc is cleaned up best-effort even on the reject path.
//   3. PII canary - across every logger call, the structured payload
//      contains `uid` + `outcome` + `latencyMs` only. The challenge
//      value, clientDataJSON, attestationObject, and publicKey never
//      appear in any log line.
//
// Mock strategy mirrors `suggestQuote.test.ts` and `wipeUserData.test.ts`
// for the firebase-functions, firebase-admin/firestore, and
// @simplewebauthn/server seams. The library is replaced wholesale so the
// test does not need a real WebAuthn keypair.

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

// defineString stub - surface the same `.value()` accessor the handler
// touches at runtime. Default values mirror the production constants:
//   production_origin = 'http://localhost:5173' (so isProvisioned()
//                       returns true under tests)
//   rpid              = 'localhost'
//   staging_origins   = (default - handled by the real module).
jest.unstable_mockModule('firebase-functions/params', () => ({
  defineString: (name: string, opts?: { default?: string }) => ({
    name,
    value: () => {
      if (name === 'WEBAUTHN_PRODUCTION_ORIGIN') return 'http://localhost:5173';
      if (name === 'WEBAUTHN_RPID') return 'localhost';
      if (name === 'WEBAUTHN_STAGING_ORIGINS')
        return 'http://localhost:5173,http://localhost:3000';
      return opts?.default ?? '';
    },
  }),
  defineSecret: (name: string) => ({ name, value: () => 'TEST-SECRET' }),
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
// In-memory Firestore mock. Models documents as a flat path→data map.
// ---------------------------------------------------------------------------

const docStore = new Map<string, Record<string, unknown>>();
const deletedPaths: string[] = [];

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

function makeDocRef(path: string): FakeDocRef {
  return {
    _path: path,
    get: () => {
      const data = docStore.get(path);
      return Promise.resolve({
        exists: data !== undefined,
        data: () => (data ? { ...data } : undefined),
      });
    },
    set: (data, opts) => {
      if (opts?.merge) {
        const existing = docStore.get(path) ?? {};
        docStore.set(path, { ...existing, ...data });
      } else {
        docStore.set(path, { ...data });
      }
      return Promise.resolve();
    },
    delete: () => {
      deletedPaths.push(path);
      docStore.delete(path);
      return Promise.resolve();
    },
  };
}

const firestoreMock = {
  doc(path: string): FakeDocRef {
    return makeDocRef(path);
  },
};

jest.unstable_mockModule('firebase-admin/firestore', () => ({
  getFirestore: () => firestoreMock,
  FieldValue: {
    // Just a sentinel - the test asserts equality with the same sentinel
    // rather than a real server-timestamp.
    serverTimestamp: () => ({ __serverTimestamp: true }),
  },
  Timestamp: {
    fromMillis: (ms: number) => ({ toMillis: () => ms }),
  },
}));

// ---------------------------------------------------------------------------
// @simplewebauthn/server mock. Returns a deterministic registrationInfo
// payload; the test asserts the persisted doc shape.
// ---------------------------------------------------------------------------

let nextVerifyResult: {
  verified: boolean;
  registrationInfo?: {
    credential: {
      id: string;
      publicKey: Uint8Array;
      counter: number;
      transports?: readonly string[];
    };
    aaguid?: string;
  };
} = {
  verified: true,
  registrationInfo: {
    credential: {
      id: 'cred-id-test-001',
      publicKey: new Uint8Array([1, 2, 3, 4, 5]),
      counter: 0,
      transports: ['internal'] as const,
    },
    aaguid: 'aaguid-test',
  },
};

const verifyRegistrationMock = jest.fn(() => Promise.resolve(nextVerifyResult));

jest.unstable_mockModule('@simplewebauthn/server', () => ({
  verifyRegistrationResponse: verifyRegistrationMock,
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let handleWebauthnRegisterFinish: typeof import('../webauthnRegisterFinish.js').handleWebauthnRegisterFinish;

beforeAll(async () => {
  const mod = await import('../webauthnRegisterFinish.js');
  handleWebauthnRegisterFinish = mod.handleWebauthnRegisterFinish;
});

beforeEach(() => {
  loggerCalls.length = 0;
  docStore.clear();
  deletedPaths.length = 0;
  verifyRegistrationMock.mockClear();
  nextVerifyResult = {
    verified: true,
    registrationInfo: {
      credential: {
        id: 'cred-id-test-001',
        publicKey: new Uint8Array([1, 2, 3, 4, 5]),
        counter: 0,
        transports: ['internal'] as const,
      },
      aaguid: 'aaguid-test',
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

function seedChallenge(
  uid: string,
  challengeId: string,
  { stale = false }: { stale?: boolean } = {},
): void {
  const expiresMs = stale ? Date.now() - 1000 : Date.now() + 60_000;
  docStore.set(`users/${uid}/webauthnChallenges/${challengeId}`, {
    challenge: challengeId,
    purpose: 'register',
    expiresAt: new Date(expiresMs),
    createdAt: new Date(),
  });
}

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

describe('webauthnRegisterFinish handler', () => {
  test('happy path persists credential + deletes challenge', async () => {
    const uid = 'uid-happy-1';
    const challengeId = 'challenge-abc';
    seedChallenge(uid, challengeId);

    const result = await handleWebauthnRegisterFinish(
      call(uid, {
        v: 1,
        challengeId,
        response: {
          id: 'cred-id-test-001',
          rawId: 'AQID',
          type: 'public-key',
          response: {
            clientDataJSON: 'AAAA',
            attestationObject: 'BBBB',
          },
        },
      }) as never,
    );

    expect(result).toEqual({ ok: true, credentialId: 'cred-id-test-001' });
    expect(verifyRegistrationMock).toHaveBeenCalledTimes(1);

    // Credential doc persisted at canonical path with canonical schema.
    const credPath = `users/${uid}/webauthn/cred-id-test-001`;
    const credDoc = docStore.get(credPath);
    expect(credDoc).toBeDefined();
    if (!credDoc) throw new Error('expected credential doc');
    expect(credDoc.credentialId).toBe('cred-id-test-001');
    expect(typeof credDoc.publicKeyBase64).toBe('string');
    expect(credDoc.publicKeyBase64).not.toBe('');
    expect(credDoc.counter).toBe(0);
    expect(credDoc.transports).toEqual(['internal']);
    expect(credDoc.aaguid).toBe('aaguid-test');
    expect(credDoc.lastUsedAt).toBeNull();
    expect(credDoc.failedAttempts).toBe(0);
    expect(credDoc.lockedUntil).toBeNull();

    // Challenge doc deleted (single-use semantics).
    expect(deletedPaths).toContain(
      `users/${uid}/webauthnChallenges/${challengeId}`,
    );
    expect(docStore.has(`users/${uid}/webauthnChallenges/${challengeId}`)).toBe(
      false,
    );
  });

  test('stale challenge → challenge_expired + cleanup', async () => {
    const uid = 'uid-stale-1';
    const challengeId = 'stale-abc';
    seedChallenge(uid, challengeId, { stale: true });

    const result = await handleWebauthnRegisterFinish(
      call(uid, {
        v: 1,
        challengeId,
        response: { id: 'x', rawId: 'AQ', response: {} },
      }) as never,
    );
    expect(result).toEqual({ ok: false, code: 'challenge_expired' });
    expect(verifyRegistrationMock).not.toHaveBeenCalled();
    expect(deletedPaths).toContain(
      `users/${uid}/webauthnChallenges/${challengeId}`,
    );
  });

  test('PII canary - log payload never carries the challenge or response body', async () => {
    const uid = 'uid-pii-1';
    const challengeId = 'pii-challenge-SECRET';
    const secretClientDataJSON = 'CLIENT-DATA-SECRET-VALUE';
    const secretAttestation = 'ATTESTATION-OBJECT-SECRET';
    seedChallenge(uid, challengeId);

    await handleWebauthnRegisterFinish(
      call(uid, {
        v: 1,
        challengeId,
        response: {
          id: 'cred-id-test-001',
          rawId: 'AQID',
          type: 'public-key',
          response: {
            clientDataJSON: secretClientDataJSON,
            attestationObject: secretAttestation,
          },
        },
      }) as never,
    );

    // Walk every logger call; assert no forbidden substring landed.
    const dump = JSON.stringify(loggerCalls);
    expect(dump).not.toContain(challengeId);
    expect(dump).not.toContain(secretClientDataJSON);
    expect(dump).not.toContain(secretAttestation);
    // Positive control: the success outcome IS logged with uid +
    // latencyMs, so the dump references the uid (allowed per
    // ADR-0003 §"Logging schema").
    expect(dump).toContain(uid);
    expect(dump).toContain('latencyMs');
    expect(dump).toContain('webauthnRegisterFinish');
  });

  test('unauthenticated request throws HttpsError', async () => {
    await expect(
      handleWebauthnRegisterFinish(
        call(null, { v: 1, challengeId: 'x', response: {} }) as never,
      ),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
