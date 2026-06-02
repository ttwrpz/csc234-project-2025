// Gemini client wrapper.
//
// - Owns the canonical SYSTEM_PROMPT.
// - Reads GEMINI_API_KEY *lazily* via defineSecret so the secret binding is
//   honoured at runtime, not at module load (matters for Cloud Functions cold
//   starts and for tests that mock `defineSecret`).
// - Wraps the SDK call with an externally-supplied AbortSignal so the caller
//   in `analyzeMoodText.ts` can enforce a 5s timeout that maps to
//   `gemini_unavailable`.
//
// Uses the unified `@google/genai` SDK (call shape:
// `ai.models.generateContent({ model, contents, config })`). The system
// prompt, response schema, and downstream
// `Result<AiSuggestion, AiAnalysisFailure>` mapping are stable.

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
 * Canonical system prompt. Any edit here MUST be paired with
 * security-reviewer sign-off.
 */
export const SYSTEM_PROMPT = `You are MoodBloom's mood classifier. You receive one short user-authored
journal entry (Thai or English) and return a single JSON object describing
which of MoodBloom's six mood categories best fits the entry, plus a 1..5
intensity rating for that mood.

ALLOWED MOODS - return EXACTLY one of these strings, lowercase:
  happy, calm, okay, sad, angry, anxious

INTENSITY (1..5 integer):
  1 = barely there / fleeting
  2 = mild
  3 = moderate (the everyday default)
  4 = strong
  5 = overwhelming / dominating the entry
  Use the wording's force as a cue ("a bit", "a little" → low; "really",
  "so", "completely", repeated punctuation, all-caps → high). Never go
  outside 1..5.

RULES
1. Use ONLY the six mood strings above. No synonyms, plurals, capitalisation,
   or translations.
2. Return JSON: { "mood", "confidence" (0..1), "intensity" (1..5 integer),
   "alternative" | null, "rationale" (<=80 chars, no PII echo), "flag" | null }.
3. SAFETY: explicit self-harm or suicidal intent → flag="self_harm_safety",
   mood="okay", confidence=0.2, intensity=3. Do NOT moralise. Do NOT include
   hotlines. The app handles that downstream.
4. EMPTY/GIBBERISH: mood="okay", confidence<=0.4, intensity=3, alternative=null,
   flag=null.
5. RATIONALE: refer to themes ("themes of loss and fatigue"), never quote
   the user's input. English only - UI localises.

ONE-SHOT EXAMPLE
Input:  "I aced the presentation today and the team cheered. Feeling proud."
Output: {"mood":"happy","confidence":0.92,"intensity":4,
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
    intensity: { type: Type.INTEGER },
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
  required: [
    'mood',
    'confidence',
    'intensity',
    'alternative',
    'rationale',
    'flag',
  ],
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
 * `locale` (when provided) is stated as metadata only - the prompt is English.
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
      // gemini-2.5-flash "thinking" is charged against maxOutputTokens; a
      // 200-token cap let it think away the whole budget and emit no content
      // (finishReason=MAX_TOKENS), which surfaced as a constant parse_error.
      // Disable thinking for this structured classifier and widen the cap.
      maxOutputTokens: 512,
      thinkingConfig: { thinkingBudget: 0 },
      responseMimeType: 'application/json',
      responseSchema: RESPONSE_SCHEMA,
      abortSignal: signal,
    },
  });

  const latencyMs = Date.now() - start;
  const raw = parseGenAiJson(response, 'analyze');

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

/**
 * Defensive JSON extractor for `@google/genai` responses.
 *
 * The SDK's `response.text` getter has surprised us in production with
 * three failure modes that all manifested as `parse_error: json_syntax`:
 *  1. Empty text - happens when the model finishes with `MAX_TOKENS` /
 *     `SAFETY` and emits no content parts. We surface a more useful
 *     message + finish-reason diagnostic so the caller can distinguish
 *     "model is unavailable" from "response was blocked".
 *  2. Markdown-fenced output - even with `responseMimeType: 'application/json'`,
 *     Gemini occasionally wraps the JSON in ```json … ``` fences. We strip
 *     a leading/trailing fence before parsing.
 *  3. Whitespace-only text - same root cause as (1).
 *
 * Anything still un-parseable throws SyntaxError so the handler maps it
 * to `parse_error`. We do NOT log the raw text - it could echo a user's
 * journal entry indirectly via the rationale field, which CLAUDE.md
 * forbids ("Never log PII (mood text, …)").
 */
function parseGenAiJson(
  response: { text?: string; candidates?: Array<{ finishReason?: string }> },
  callsite: 'analyze' | 'patterns',
): unknown {
  let text = (response.text ?? '').trim();

  // Strip ```json … ``` (or plain ``` … ```) fences. Gemini occasionally
  // emits them despite responseMimeType.
  if (text.startsWith('```')) {
    const stripped = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
    text = stripped.trim();
  }

  if (text.length === 0) {
    const finish =
      response.candidates && response.candidates.length > 0
        ? response.candidates[0]?.finishReason ?? 'unknown'
        : 'no_candidates';
    // Throw SyntaxError so the existing handler-side switch (which
    // checks `e instanceof SyntaxError`) keeps mapping this to
    // `parse_error`. The message includes the finish reason so the log
    // entry shows *why* the model returned nothing.
    throw new SyntaxError(
      `${callsite}: Gemini returned no text (finishReason=${finish})`,
    );
  }

  return JSON.parse(text);
}

// ---------------------------------------------------------------------------
// Pattern themes - Gemini supplementary call for `analyzePatterns`.
// ---------------------------------------------------------------------------

/**
 * System prompt for the themes-level pattern insight. Receives a JSON
 * array of `{date, moodCode, intensity}` and returns a single
 * `{insightText, confidence}`. **Never quotes user input** - the input
 * has no user input to begin with (numeric mood codes only). Copy MUST
 * obey CLAUDE.md §"Copy rules": no clinical language, no streak-shaming,
 * no fix-your-mood verbs, compassionate imperatives only.
 */
export const PATTERNS_SYSTEM_PROMPT = `You are MoodBloom's pattern-themes assistant. You receive a JSON
array of recent mood-log entries (numeric mood codes + dates only - no
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
6. ALWAYS offer one gentle, present-tense reflection of what the entries
   actually show - the prevailing feeling, or the mix ("a blend of calm
   with a couple of heavier days"). Describe what is there; do NOT invent a
   trend, cause, or pattern the numbers don't support. When the entries are
   few or evenly mixed, keep it soft and low-confidence (<= 0.35) rather
   than declaring there is nothing. Only return
   {"insightText":"Your entries show no clear theme yet.","confidence":0.2}
   when there are fewer than 3 entries.
7. English only - UI localises.

ONE-SHOT EXAMPLES
Input:  [{"date":"2026-04-01","moodCode":"happy","intensity":4}, ...]
Output: {"insightText":"Recent mornings have felt lighter than evenings.",
         "confidence":0.62}
Input (a short, mixed week):
        [{"date":"2026-05-01","moodCode":"calm","intensity":3},
         {"date":"2026-05-03","moodCode":"sad","intensity":4},
         {"date":"2026-05-06","moodCode":"happy","intensity":3}]
Output: {"insightText":"This past week has held a gentle mix of calm with a couple of heavier moments.",
         "confidence":0.3}`;

/**
 * Response schema for [analyzeForPatterns]. Tighter than the mood
 * classifier schema - just the two fields the handler needs to build
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
 * of these as `geminiSkipped` paths - Gemini is supplementary, not
 * fatal.
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
      // See analyze() above: disable thinking + widen the cap so the JSON
      // fits. Direct fix for the parse_error on every analyzePatterns call.
      maxOutputTokens: 512,
      thinkingConfig: { thinkingBudget: 0 },
      responseMimeType: 'application/json',
      responseSchema: PATTERNS_RESPONSE_SCHEMA,
      abortSignal: signal,
    },
  });

  const latencyMs = Date.now() - start;
  const raw = parseGenAiJson(response, 'patterns');

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
