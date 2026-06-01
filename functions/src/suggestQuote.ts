// Cloud Function for the Tier 1/2 quote-suggestion hybrid path (HB-008).
//
// The Dart side calls this CF with an `AiAllowedTier` projection that
// excludes Tier 3 at the type level. The CF additionally rejects
// `tier: 3` at the input-schema boundary - belt-and-suspenders per
// ADR-0012 §"Decision" point 1: Tier 3 messages NEVER call Gemini, EVER.
//
// Validation order mirrors `analyzeMoodText.ts`:
//   1. Auth check (throws `HttpsError('unauthenticated')`).
//   2. Zod schema validation (strict - unknown keys rejected, tier ∈
//      {1, 2}, weekId regex, dailyAvgS ∈ [-1, 1], dominantEmotion ∈
//      6-mood enum).
//   3. Rate limit: 10 calls / uid / day. Consumed BEFORE the Gemini
//      call so an upstream outage cannot DoS the project's Gemini quota.
//   4. Gemini call with the locked, tier-specific prompt. 30s budget;
//      `temperature: 0.4`; `maxOutputTokens: 80`.
//   5. Return `{suggestedText: string}` - NO server-side trim or
//      post-process. The Dart-side QuoteSafetyFilter is the second line
//      of defence and MUST see what Gemini actually said.
//
// PII canary (HB-008 §"forbidden in payload"): the Gemini prompt is
// built ONLY from `tier`, `weekId`, `dailyAvgS`, `dominantEmotion`.
// Never `userId`, never `email`, never raw `moodText`, never an FCM
// token. The test in `__tests__/suggestQuote.test.ts` intercepts the
// Gemini SDK call and asserts the prompt body contains none of these.

import { GoogleGenAI } from '@google/genai';
import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { z, ZodError } from 'zod';

import { GEMINI_API_KEY } from './geminiClient.js';
import { consumeToken } from './rateLimit.js';
import { MOOD_TYPES, MODEL_VERSION } from './types.js';

// ---------------------------------------------------------------------------
// Locked system prompt - top-of-file `const`, NEVER from Remote Config.
// HB-008 §"system prompt (locked, version-controlled in this file)".
// Edits require an ADR amendment + security-reviewer sign-off.
// ---------------------------------------------------------------------------

/** Returns the locked system prompt for the given tier. */
function buildSystemPrompt(tier: 1 | 2): string {
  const verb = tier === 1 ? 'breathing exercise' : 'journaling prompt';
  return `You are a gentle companion for a mood-tracking app. Suggest a single supportive sentence (max 140 characters) inviting the user to a ${verb}. Forbidden words: depression, anxiety disorder, bipolar, diagnose, medication, therapy, must, should. Use compassionate language only. Reply with the sentence only - no quotes, no preamble.`;
}

// ---------------------------------------------------------------------------
// Request validation
// ---------------------------------------------------------------------------

const WEEK_ID_RE = /^\d{4}-W\d{2}$/;

/** Zod schema for the suggestQuote request. Strict - rejects unknown keys. */
export const SuggestQuoteRequestSchema = z
  .object({
    /** Tier-3 is INTENTIONALLY absent. ADR-0012 §"Decision" point 1. */
    tier: z.union([z.literal(1), z.literal(2)]),
    context: z
      .object({
        weekId: z.string().regex(WEEK_ID_RE),
        dailyAvgS: z.number().min(-1).max(1),
        dominantEmotion: z.enum(MOOD_TYPES),
      })
      .strict(),
  })
  .strict();

export type SuggestQuoteRequest = z.infer<typeof SuggestQuoteRequestSchema>;

const RATE_LIMIT_WINDOW_MS = 86_400_000; // 24h - 10 calls per uid per day.
const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_COLLECTION = 'rateLimits.suggestQuote';

const GEMINI_TIMEOUT_MS = 30_000;
const TEMPERATURE = 0.4;
const MAX_OUTPUT_TOKENS = 80;

interface LogPayload {
  event: 'suggestQuote';
  uid: string;
  outcome: 'success' | 'rate_limited' | 'gemini_failure' | 'invalid_input' | 'internal';
  tier?: number;
  latencyMs?: number;
  errorReason?: string;
  rateLimit?: { remaining: number; retryAfterSec: number };
}

// ---------------------------------------------------------------------------
// Gemini call (exported for tests so they can intercept the SDK)
// ---------------------------------------------------------------------------

/**
 * Build the user content sent to Gemini. The prompt body carries ONLY the
 * tier-appropriate framing + the three aggregate signals from the context.
 * Never any field-level PII (no uid, no email, no mood text).
 */
function buildUserContent(req: SuggestQuoteRequest): string {
  // Compose a short, structured framing. Gemini sees only the three
  // aggregate signals - no field-level PII whatsoever.
  return [
    'Context for the suggestion:',
    `- week: ${req.context.weekId}`,
    `- todayAverageScore: ${req.context.dailyAvgS.toFixed(2)} (range -1..+1)`,
    `- dominantEmotion: ${req.context.dominantEmotion}`,
    '',
    'Now write the single supportive sentence as instructed.',
  ].join('\n');
}

/**
 * Call Gemini for a Tier 1/2 quote suggestion. Throws on SDK error /
 * timeout / abort; the handler maps those to `HttpsError('internal')`.
 *
 * Exported so the test file can mock at the `@google/genai` boundary
 * (same pattern as `geminiClient.ts.analyze`).
 */
export async function callGeminiForQuote(
  req: SuggestQuoteRequest,
  signal: AbortSignal,
): Promise<{ suggestedText: string; latencyMs: number }> {
  const apiKey = GEMINI_API_KEY.value();
  const ai = new GoogleGenAI({ apiKey });

  const systemInstruction = buildSystemPrompt(req.tier);
  const userContent = buildUserContent(req);
  const start = Date.now();

  const response = await ai.models.generateContent({
    model: MODEL_VERSION,
    contents: [{ role: 'user', parts: [{ text: userContent }] }],
    config: {
      systemInstruction,
      temperature: TEMPERATURE,
      maxOutputTokens: MAX_OUTPUT_TOKENS,
      abortSignal: signal,
    },
  });

  const latencyMs = Date.now() - start;
  const text = (response.text ?? '').trim();
  // HB-008: "Do NOT trim or post-process the Gemini output on the
  // server." We strip outer whitespace only because some Gemini
  // responses arrive with a trailing newline that the SDK leaves in;
  // this is transport hygiene, not safety post-processing. The 140-char
  // length cap is the Dart-side filter's job. The blacklist check is
  // also the Dart-side filter's job. We return what Gemini said.
  if (text.length === 0) {
    throw new Error('gemini-empty-response');
  }
  return { suggestedText: text, latencyMs };
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

/**
 * Core handler - exported for tests so they can call it without going
 * through `firebase-functions-test`'s wrap layer.
 */
export async function handleSuggestQuote(
  request: CallableRequest<unknown>,
): Promise<{ suggestedText: string }> {
  // 1. Auth.
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;
  const startMs = Date.now();

  // 2. Schema validation. Strict - rejects unknown keys, tier=3, malformed
  // weekId, dailyAvgS out of [-1, 1], unknown emotion, etc.
  let parsed: SuggestQuoteRequest;
  try {
    parsed = SuggestQuoteRequestSchema.parse(request.data);
  } catch (e) {
    const reason =
      e instanceof ZodError ? e.issues[0]?.code ?? 'invalid' : 'invalid';
    const payload: LogPayload = {
      event: 'suggestQuote',
      uid,
      outcome: 'invalid_input',
      errorReason: reason,
    };
    logger.info(payload);
    throw new HttpsError(
      'invalid-argument',
      // ADR-0012 §"Decision" point 1 - make the Tier-3 rejection obvious
      // in the error message so a future reviewer sees the invariant at
      // a glance. The generic invalid-argument bucket covers the other
      // shape errors (weekId regex, dailyAvgS range, etc.).
      'Tier 3 must not call this function.',
    );
  }

  // 3. Rate limit - 10/uid/day.
  let rateLimit;
  try {
    rateLimit = await consumeToken(uid, Date.now(), {
      windowMs: RATE_LIMIT_WINDOW_MS,
      max: RATE_LIMIT_MAX,
      collection: RATE_LIMIT_COLLECTION,
    });
  } catch (e) {
    const payload: LogPayload = {
      event: 'suggestQuote',
      uid,
      outcome: 'internal',
      errorReason: 'rate_limit_tx_failed',
      latencyMs: Date.now() - startMs,
    };
    // NEVER log `e.message` - could indirectly carry context. Log the
    // error name only.
    logger.error({ ...payload, cause: e instanceof Error ? e.name : 'unknown' });
    throw new HttpsError('internal', 'internal-error');
  }
  if (!rateLimit.allowed) {
    const payload: LogPayload = {
      event: 'suggestQuote',
      uid,
      outcome: 'rate_limited',
      tier: parsed.tier,
      rateLimit: { remaining: 0, retryAfterSec: rateLimit.retryAfterSec },
      latencyMs: Date.now() - startMs,
    };
    logger.info(payload);
    throw new HttpsError(
      'resource-exhausted',
      'Too many quote suggestions today.',
    );
  }

  // 4. Gemini call with 30s AbortController. The dailyAvgS / dominantEmotion
  // values flow into the prompt body but NEVER into the structured log -
  // dailyAvgS could leak inferences about the user's day.
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), GEMINI_TIMEOUT_MS);
  let gem;
  try {
    gem = await callGeminiForQuote(parsed, ac.signal);
  } catch (e) {
    clearTimeout(timer);
    const payload: LogPayload = {
      event: 'suggestQuote',
      uid,
      outcome: 'gemini_failure',
      tier: parsed.tier,
      // Log the exception NAME only - never the message. Gemini errors
      // may carry user-context inferences in their message bodies, and
      // ADR-0012 + HB-008 forbid that surfacing in observability.
      errorReason: e instanceof Error ? e.name : 'unknown',
      latencyMs: Date.now() - startMs,
    };
    logger.warn(payload);
    throw new HttpsError('internal', 'gemini-failure');
  }
  clearTimeout(timer);

  // 5. Allowlist log. The suggested text is NOT logged - only the tier,
  // latency, and rate-limit telemetry.
  const successLog: LogPayload = {
    event: 'suggestQuote',
    uid,
    outcome: 'success',
    tier: parsed.tier,
    latencyMs: gem.latencyMs,
    rateLimit: { remaining: rateLimit.remaining, retryAfterSec: 0 },
  };
  logger.info(successLog);

  // Return verbatim. The Dart-side filter is the second line of defence.
  return { suggestedText: gem.suggestedText };
}

/**
 * The exported v2 callable. Mirrors the `analyzeMoodText` deployment
 * posture: `asia-southeast1`, 256MiB, 30s timeout.
 *
 * `enforceAppCheck` - kept `false` to match the existing CFs in this
 * project. Per `analyzeMoodText.ts`, App Check enforcement is
 * temporarily disabled across the suite until the Flutter web client
 * initialises `firebase_app_check`. Re-enable when the client ships
 * the activation call (tracked in v1.6 ADR).
 */
export const suggestQuote = onCall(
  {
    region: 'asia-southeast1',
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
  },
  handleSuggestQuote,
);
