// Gemini client wrapper.
//
// - Owns the canonical SYSTEM_PROMPT (do not edit without an ADR amendment).
// - Reads GEMINI_API_KEY *lazily* via defineSecret so the secret binding is
//   honoured at runtime, not at module load (matters for Cloud Functions cold
//   starts and for tests that mock `defineSecret`).
// - Wraps the SDK call with an externally-supplied AbortSignal so the caller
//   in `analyzeMoodText.ts` can enforce a 5s timeout that maps to
//   `gemini_unavailable`.
//
// Sprint 5 — migrated from `@google/generative-ai` (deprecated 2025-09)
// to the unified `@google/genai` SDK. The wire-level call shape changed
// (`ai.models.generateContent({ model, contents, config })` instead of
// `model.generateContent(req, opts)`), but the system prompt, response
// schema, and downstream `Result<AiSuggestion, AiAnalysisFailure>`
// mapping are byte-identical from the caller's perspective.

import { GoogleGenAI, Type, type Schema } from '@google/genai';
import { defineSecret } from 'firebase-functions/params';

import {
  type HistoryEntryWire,
  MODEL_VERSION,
  MOOD_TYPES,
  SAFETY_FLAGS,
} from './types.js';

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
 *
 * The new `@google/genai` SDK exposes the schema enum as `Type` (vs the
 * legacy `SchemaType`); the field set (`type`, `properties`, `enum`,
 * `nullable`, `required`) is unchanged.
 */
const RESPONSE_SCHEMA: Schema = {
  type: Type.OBJECT,
  properties: {
    mood: { type: Type.STRING, enum: [...MOOD_TYPES] },
    confidence: { type: Type.NUMBER },
    alternative: {
      type: Type.OBJECT,
      nullable: true,
      properties: {
        mood: { type: Type.STRING, enum: [...MOOD_TYPES] },
        confidence: { type: Type.NUMBER },
      },
      required: ['mood', 'confidence'],
    },
    rationale: { type: Type.STRING },
    flag: {
      type: Type.STRING,
      enum: [...SAFETY_FLAGS],
      nullable: true,
    },
  },
  required: ['mood', 'confidence', 'alternative', 'rationale', 'flag'],
};

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
  const ai = new GoogleGenAI({ apiKey });

  const userContent = buildUserContent(text, locale);
  const start = Date.now();

  const response = await ai.models.generateContent({
    model: MODEL_VERSION,
    contents: [{ role: 'user', parts: [{ text: userContent }] }],
    config: {
      systemInstruction: SYSTEM_PROMPT,
      temperature: 0.2,
      topP: 0.9,
      maxOutputTokens: 200,
      responseMimeType: 'application/json',
      responseSchema: RESPONSE_SCHEMA,
      abortSignal: signal,
    },
  });

  const latencyMs = Date.now() - start;
  // `response.text` is a getter on `GenerateContentResponse` that returns
  // the concatenated text of all candidate parts. May be undefined if the
  // model declined to emit output (we treat that as a JSON parse error
  // downstream — `JSON.parse(undefined as any)` throws SyntaxError, which
  // the handler maps to `parse_error`).
  const responseText = response.text ?? '';
  const raw: unknown = JSON.parse(responseText);

  const usage = response.usageMetadata;
  return {
    raw,
    latencyMs,
    usageMetadata: {
      promptTokens: usage?.promptTokenCount,
      completionTokens: usage?.candidatesTokenCount,
    },
  };
}

// ---------------------------------------------------------------------------
// Pattern themes — Gemini supplementary call for `analyzePatterns`.
// ---------------------------------------------------------------------------

/**
 * System prompt for the themes-level pattern insight. Receives a JSON
 * array of `{date, moodCode, intensity}` and returns a single
 * `{insightText, confidence}`. **Never quotes user input** — the input
 * has no user input to begin with (numeric mood codes only). Copy MUST
 * obey CLAUDE.md §"Copy rules": no clinical language, no streak-shaming,
 * no fix-your-mood verbs, compassionate imperatives only.
 */
export const PATTERNS_SYSTEM_PROMPT = `You are MoodBloom's pattern-themes assistant. You receive a JSON
array of recent mood-log entries (numeric mood codes + dates only — no
user-authored text). Return ONE compassionate observation about a theme
or rhythm in the entries, plus a confidence score.

OUTPUT JSON: { "insightText": string<=140, "confidence": number in [0,1] }.

RULES
1. NO clinical language. Never use "depression", "anxiety disorder",
   "symptom", "diagnosis", "concerning", "alarming".
2. NO streak-shaming. Missed days are empty slots, not broken streaks.
3. NO fix-your-mood verbs. Prefer "notice", "explore", "care for",
   "pause" over "improve", "boost", "overcome".
4. Compassionate imperatives only ("Want to…?" / "If it helps…")
   instead of "You should" / "You must".
5. Refer to themes and rhythms ("evenings have felt heavier this week"),
   never to specific calendar dates from the input.
6. If the entries do not show a clear theme, return
   {"insightText":"Your entries show no clear theme yet.","confidence":0.2}.
7. English only — UI localises.

ONE-SHOT EXAMPLE
Input:  [{"date":"2026-04-01","moodCode":"happy","intensity":4}, ...]
Output: {"insightText":"Recent mornings have felt lighter than evenings.",
         "confidence":0.62}`;

/**
 * Response schema for [analyzeForPatterns]. Tighter than the mood
 * classifier schema — just the two fields the handler needs to build
 * a `kind: 'gemini'` insight.
 */
const PATTERNS_RESPONSE_SCHEMA: Schema = {
  type: Type.OBJECT,
  properties: {
    insightText: { type: Type.STRING },
    confidence: { type: Type.NUMBER },
  },
  required: ['insightText', 'confidence'],
};

/**
 * Call Gemini for a themes-level pattern insight. Mirrors [analyze]
 * exactly except for the prompt + schema + content shape (numeric
 * history serialised as JSON instead of a journal entry string). The
 * `windowDays` is included as plain metadata so the model can frame the
 * observation, NOT as a behavioural lever.
 *
 * @throws under the same conditions as [analyze]: network, 5xx, abort,
 * JSON.parse failure. The caller in `analyzePatterns.ts` swallows all
 * of these as `geminiSkipped` paths — Gemini is supplementary, not
 * fatal (per ADR-0007 §"Decision: statistical-primary, Gemini-supplementary").
 */
export async function analyzeForPatterns(
  history: HistoryEntryWire[],
  windowDays: number,
  signal: AbortSignal,
): Promise<GeminiAnalyzeResult> {
  const apiKey = GEMINI_API_KEY.value();
  const ai = new GoogleGenAI({ apiKey });

  const userContent = JSON.stringify({ windowDays, history });
  const start = Date.now();

  const response = await ai.models.generateContent({
    model: MODEL_VERSION,
    contents: [{ role: 'user', parts: [{ text: userContent }] }],
    config: {
      systemInstruction: PATTERNS_SYSTEM_PROMPT,
      temperature: 0.2,
      topP: 0.9,
      maxOutputTokens: 200,
      responseMimeType: 'application/json',
      responseSchema: PATTERNS_RESPONSE_SCHEMA,
      abortSignal: signal,
    },
  });

  const latencyMs = Date.now() - start;
  const responseText = response.text ?? '';
  const raw: unknown = JSON.parse(responseText);

  const usage = response.usageMetadata;
  return {
    raw,
    latencyMs,
    usageMetadata: {
      promptTokens: usage?.promptTokenCount,
      completionTokens: usage?.candidatesTokenCount,
    },
  };
}
