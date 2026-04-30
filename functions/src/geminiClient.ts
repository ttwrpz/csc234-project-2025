// Gemini client wrapper.
//
// - Owns the canonical SYSTEM_PROMPT (do not edit without an ADR amendment).
// - Reads GEMINI_API_KEY *lazily* via defineSecret so the secret binding is
//   honoured at runtime, not at module load (matters for Cloud Functions cold
//   starts and for tests that mock `defineSecret`).
// - Wraps the SDK call with an externally-supplied AbortSignal so the caller
//   in `analyzeMoodText.ts` can enforce a 5s timeout that maps to
//   `gemini_unavailable`.

import { GoogleGenerativeAI, SchemaType } from '@google/generative-ai';
import { defineSecret } from 'firebase-functions/params';

import { MODEL_VERSION, MOOD_TYPES, SAFETY_FLAGS } from './types.js';

/**
 * Bound at deploy time via `firebase functions:secrets:set GEMINI_API_KEY`.
 *
 * Type annotation uses `ReturnType<typeof defineSecret>` to avoid TS2742
 * (the inferred type lives at an internal package path not exposed via the
 * library's `exports` map).
 */
export const GEMINI_API_KEY: ReturnType<typeof defineSecret> = defineSecret(
  'GEMINI_API_KEY',
);

/**
 * Canonical system prompt. Copied verbatim from ADR-0003 §"Gemini system prompt".
 * Any edit here MUST be paired with an ADR amendment + security-reviewer sign-off.
 */
export const SYSTEM_PROMPT = `You are MoodBloom's mood classifier. You receive one short user-authored
journal entry (Thai or English) and return a single JSON object describing
which of MoodBloom's six mood categories best fits the entry.

ALLOWED MOODS — return EXACTLY one of these strings, lowercase:
  happy, calm, okay, sad, angry, anxious

RULES
1. Use ONLY the six mood strings above. No synonyms, plurals, capitalisation,
   or translations.
2. Return JSON: { "mood", "confidence" (0..1), "alternative" | null,
   "rationale" (<=80 chars, no PII echo), "flag" | null }.
3. SAFETY: explicit self-harm or suicidal intent → flag="self_harm_safety",
   mood="okay", confidence=0.2. Do NOT moralise. Do NOT include hotlines.
   The app handles that downstream.
4. EMPTY/GIBBERISH: mood="okay", confidence<=0.4, alternative=null, flag=null.
5. RATIONALE: refer to themes ("themes of loss and fatigue"), never quote
   the user's input. English only — UI localises.

ONE-SHOT EXAMPLE
Input:  "I aced the presentation today and the team cheered. Feeling proud."
Output: {"mood":"happy","confidence":0.92,
         "alternative":{"mood":"calm","confidence":0.31},
         "rationale":"Achievement and social validation indicate happy.",
         "flag":null}`;

/**
 * Enum-constrained response schema for Gemini's structured-output mode.
 * Collapses parse errors to a rare exception (the model can still emit
 * out-of-range numbers, hence the runtime Zod check downstream).
 */
const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    mood: { type: SchemaType.STRING, enum: [...MOOD_TYPES] },
    confidence: { type: SchemaType.NUMBER },
    alternative: {
      type: SchemaType.OBJECT,
      nullable: true,
      properties: {
        mood: { type: SchemaType.STRING, enum: [...MOOD_TYPES] },
        confidence: { type: SchemaType.NUMBER },
      },
      required: ['mood', 'confidence'],
    },
    rationale: { type: SchemaType.STRING },
    flag: {
      type: SchemaType.STRING,
      enum: [...SAFETY_FLAGS],
      nullable: true,
    },
  },
  required: ['mood', 'confidence', 'alternative', 'rationale', 'flag'],
} as const;

export interface GeminiAnalyzeResult {
  /** Raw parsed JSON from the model. Caller validates with Zod. */
  raw: unknown;
  /** Wall-clock latency of the SDK call in milliseconds. */
  latencyMs: number;
  /** Token usage as reported by the SDK; both fields are best-effort. */
  usageMetadata: {
    promptTokens?: number;
    completionTokens?: number;
  };
}

/**
 * Build the user-content message. The journal `text` is an inline string;
 * `locale` (when provided) is stated as metadata only — the prompt is English.
 */
function buildUserContent(text: string, locale: string | undefined): string {
  const localeLine = locale ? `Locale: ${locale}\n` : '';
  return `${localeLine}Journal entry:\n${text}`;
}

/**
 * Call Gemini and return the parsed JSON object plus latency/usage telemetry.
 *
 * @throws if the SDK rejects (network, 5xx, abort, JSON.parse failure). The
 * caller in `analyzeMoodText.ts` decides whether the failure maps to
 * `gemini_unavailable` (abort/network) or `parse_error` (JSON / schema).
 */
export async function analyze(
  text: string,
  locale: string | undefined,
  signal: AbortSignal,
): Promise<GeminiAnalyzeResult> {
  const apiKey = GEMINI_API_KEY.value();
  const client = new GoogleGenerativeAI(apiKey);
  const model = client.getGenerativeModel({
    model: MODEL_VERSION,
    systemInstruction: SYSTEM_PROMPT,
    generationConfig: {
      temperature: 0.2,
      topP: 0.9,
      maxOutputTokens: 200,
      responseMimeType: 'application/json',
      // The SDK accepts a Schema-shaped object here. The narrow `as const` on
      // RESPONSE_SCHEMA preserves enum literals at compile time but conflicts
      // with the SDK's mutable `Schema` interface, so we widen at this single
      // call site rather than throughout the schema declaration.
      // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment
      responseSchema: RESPONSE_SCHEMA as any,
    },
  });

  const userContent = buildUserContent(text, locale);
  const start = Date.now();

  const result = await model.generateContent(
    {
      contents: [{ role: 'user', parts: [{ text: userContent }] }],
    },
    { signal },
  );

  const latencyMs = Date.now() - start;
  const responseText = result.response.text();
  const raw: unknown = JSON.parse(responseText);

  const usage = result.response.usageMetadata;

  return {
    raw,
    latencyMs,
    usageMetadata: {
      promptTokens: usage?.promptTokenCount,
      completionTokens: usage?.candidatesTokenCount,
    },
  };
}
