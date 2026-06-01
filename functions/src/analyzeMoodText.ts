// onCall handler implementing the validation pipeline. Short-circuits
// on each failure with a wire envelope. Throws `HttpsError('unauthenticated')`
// for the unauth case so the Firebase SDK on the client maps it to
// `FirebaseFunctionsException` before the envelope path runs (we cannot
// trust an unauth caller's `requestId`).

import { logger } from 'firebase-functions';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { ZodError } from 'zod';

import { analyze, GEMINI_API_KEY } from './geminiClient.js';
import { consumeToken } from './rateLimit.js';
import {
  AnalyzeMoodTextRequestSchema,
  type AnalyzeMoodTextErrorCode,
  type AnalyzeMoodTextResponse,
  GeminiResponseSchema,
  MODEL_VERSION,
  RATIONALE_WIRE_MAX,
} from './types.js';

const GEMINI_TIMEOUT_MS = 5_000;

/** Best-effort `requestId` extraction for error envelopes when Zod fails. */
function extractRequestId(data: unknown): string {
  if (
    typeof data === 'object' &&
    data !== null &&
    'requestId' in data &&
    typeof (data as { requestId?: unknown }).requestId === 'string'
  ) {
    return (data as { requestId: string }).requestId;
  }
  return 'unknown';
}

function clamp(n: number, lo: number, hi: number): number {
  if (n < lo) return lo;
  if (n > hi) return hi;
  return n;
}

function truncate(s: string, max: number): string {
  return s.length <= max ? s : s.slice(0, max);
}

interface HandlerLogContext {
  requestId: string;
  uid: string;
  textLen: number;
  locale?: string;
  startMs: number;
}

function makeError(
  ctx: { requestId: string },
  code: AnalyzeMoodTextErrorCode,
  message: string,
  retryAfterSec?: number,
): AnalyzeMoodTextResponse {
  const out: AnalyzeMoodTextResponse = {
    ok: false,
    v: 1,
    requestId: ctx.requestId,
    code,
    message,
  };
  if (retryAfterSec !== undefined) {
    out.retryAfterSec = retryAfterSec;
  }
  return out;
}

/**
 * Core handler - exported for tests so they can call it without going through
 * `firebase-functions-test`'s wrap layer if desired.
 */
export async function handleAnalyzeMoodText(
  request: CallableRequest<unknown>,
): Promise<AnalyzeMoodTextResponse> {
  // 1. Auth check. Throw, do NOT echo a requestId - caller is unauthenticated
  // and we have no trustworthy correlation id at this point.
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;

  // 2. Schema validation.
  let parsed;
  try {
    parsed = AnalyzeMoodTextRequestSchema.parse(request.data);
  } catch (e) {
    const requestId = extractRequestId(request.data);
    const reason = e instanceof ZodError ? e.issues[0]?.code ?? 'invalid' : 'invalid';
    logger.info({
      event: 'analyzeMoodText',
      requestId,
      uid,
      outcome: 'invalid_input',
      errorReason: reason,
    });
    return makeError({ requestId }, 'invalid_input', 'Invalid request payload.');
  }

  // 3. Length cap. (The Zod schema also enforces 1..500 after trim, so this
  // branch is double-defensive - kept explicit.)
  const text = parsed.text;
  if (text.length < 1 || text.length > 500) {
    logger.info({
      event: 'analyzeMoodText',
      requestId: parsed.requestId,
      uid,
      outcome: 'invalid_input',
      errorReason: 'length',
      textLen: text.length,
    });
    return makeError(
      { requestId: parsed.requestId },
      'invalid_input',
      'Text must be 1..500 characters.',
    );
  }

  const ctx: HandlerLogContext = {
    requestId: parsed.requestId,
    uid,
    textLen: text.length,
    locale: parsed.locale,
    startMs: Date.now(),
  };

  // 4. Rate limit. Consume the token BEFORE the Gemini call so an upstream
  // outage cannot let bursts burn the project's Gemini quota.
  let rateLimit;
  try {
    rateLimit = await consumeToken(uid);
  } catch (e) {
    logger.error({
      event: 'analyzeMoodText',
      requestId: ctx.requestId,
      uid,
      outcome: 'internal',
      errorReason: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return makeError({ requestId: ctx.requestId }, 'internal', 'Internal error.');
  }
  if (!rateLimit.allowed) {
    logger.info({
      event: 'analyzeMoodText',
      requestId: ctx.requestId,
      uid,
      outcome: 'rate_limited',
      rateLimit: { remaining: 0, retryAfterSec: rateLimit.retryAfterSec },
    });
    return makeError(
      { requestId: ctx.requestId },
      'rate_limited',
      'Too many requests. Please slow down a moment.',
      rateLimit.retryAfterSec,
    );
  }

  // 5. Gemini call with 5s AbortController.
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), GEMINI_TIMEOUT_MS);
  let gem;
  try {
    gem = await analyze(text, parsed.locale, ac.signal);
  } catch (e) {
    clearTimeout(timer);
    const aborted = ac.signal.aborted;
    const isSyntax = e instanceof SyntaxError;
    if (isSyntax) {
      logger.warn({
        event: 'analyzeMoodText',
        requestId: ctx.requestId,
        uid,
        outcome: 'parse_error',
        errorReason: 'json_syntax',
        // The geminiClient's `parseGenAiJson` helper throws SyntaxError
        // with a `finishReason=…` suffix when Gemini emits no text.
        // Surfacing the message in the structured log lets us distinguish
        // "model truncated" (MAX_TOKENS) from "blocked" (SAFETY) without
        // ever logging PII.
        cause: e instanceof Error ? e.message : 'unknown',
      });
      return makeError(
        { requestId: ctx.requestId },
        'parse_error',
        "We couldn't read the model's reply. Try again in a moment.",
      );
    }
    logger.warn({
      event: 'analyzeMoodText',
      requestId: ctx.requestId,
      uid,
      outcome: 'gemini_unavailable',
      errorReason: aborted ? 'abort' : 'sdk_error',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return makeError(
      { requestId: ctx.requestId },
      'gemini_unavailable',
      'The mood model is temporarily unavailable. Please pick a mood manually.',
    );
  }
  clearTimeout(timer);

  // 6. Validate Gemini's JSON shape.
  let validated;
  try {
    validated = GeminiResponseSchema.parse(gem.raw);
  } catch (e) {
    const reason = e instanceof ZodError ? e.issues[0]?.code ?? 'shape' : 'shape';
    logger.warn({
      event: 'analyzeMoodText',
      requestId: ctx.requestId,
      uid,
      outcome: 'parse_error',
      errorReason: reason,
    });
    return makeError(
      { requestId: ctx.requestId },
      'parse_error',
      "We couldn't read the model's reply. Try again in a moment.",
    );
  }

  // 7. Clamp confidence + truncate rationale + structured success log.
  const originalConfidence = validated.confidence;
  const confidence = clamp(validated.confidence, 0, 1);
  const clamped = confidence !== originalConfidence;

  // Intensity: clamp to [1,5]. Default to 3 (neutral) when the
  // model omits it - older deployments may not have been instructed
  // to emit `intensity`, and we'd rather surface a neutral default
  // than fail the whole call. Round to int so the client's slider
  // (1..5 step 1) lands on a valid stop.
  const intensityRaw = validated.intensity ?? 3;
  const intensity = Math.round(clamp(intensityRaw, 1, 5));

  const altOriginal = validated.alternative?.confidence;
  const alternative =
    validated.alternative === null
      ? null
      : {
          mood: validated.alternative.mood,
          confidence: clamp(validated.alternative.confidence, 0, 1),
        };
  const altClamped =
    alternative !== null && altOriginal !== undefined && alternative.confidence !== altOriginal;

  const totalLatencyMs = Date.now() - ctx.startMs;

  // CRITICAL: never log raw text, full prompt, or model rationale. The
  // PII-canary test asserts this.
  logger.info({
    event: 'analyzeMoodText',
    requestId: ctx.requestId,
    uid,
    outcome: 'success',
    textLen: ctx.textLen,
    locale: ctx.locale,
    model: MODEL_VERSION,
    latencyTotalMs: totalLatencyMs,
    latencyGeminiMs: gem.latencyMs,
    promptTokens: gem.usageMetadata.promptTokens,
    completionTokens: gem.usageMetadata.completionTokens,
    classification: {
      mood: validated.mood,
      confidence,
      intensity,
      safetyFlag: validated.flag ?? null,
    },
    rateLimit: {
      remaining: rateLimit.remaining,
      retryAfterSec: 0,
    },
    confidence_clamped: clamped || altClamped ? true : undefined,
  });

  // 8. Success envelope.
  const success: AnalyzeMoodTextResponse = {
    ok: true,
    v: 1,
    requestId: ctx.requestId,
    mood: validated.mood,
    confidence,
    intensity,
    alternative,
    rationale: truncate(validated.rationale, RATIONALE_WIRE_MAX),
    latencyMs: totalLatencyMs,
    modelVersion: MODEL_VERSION,
  };
  if (validated.flag) {
    success.flag = validated.flag;
  }
  return success;
}

/**
 * The exported v2 callable. Region matches Firestore (lowest latency for KMUTT
 * users).
 *
 * App Check enforcement is **temporarily disabled**. The Flutter web
 * client does not yet initialise `firebase_app_check`, so with
 * `enforceAppCheck: true` browser preflight requests were failing and
 * surfacing as opaque CORS errors in the console. Re-enable this flag
 * once `FirebaseAppCheck.instance.activate(...)` ships on the client
 * and a reCAPTCHA v3 site key is registered in Firebase Console → App
 * Check.
 */
export const analyzeMoodText = onCall(
  {
    region: 'asia-southeast1',
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
  },
  handleAnalyzeMoodText,
);
