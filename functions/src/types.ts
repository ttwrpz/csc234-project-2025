// Wire types and Zod runtime schemas for the analyzeMoodText callable.
//
// The wire contract is canonical in ADR-0003 (`docs/adr/0003-gemini-cloud-function-contract.md`).
// Keep this file in lockstep with the Dart side `ai_suggestion_dto.dart` (lands later this branch).

import { z } from 'zod';

/** Mood enum on the wire. Lowercase, six values, matches Dart `MoodType`. */
export const MOOD_TYPES = ['happy', 'calm', 'okay', 'sad', 'angry', 'anxious'] as const;
export type MoodTypeWire = (typeof MOOD_TYPES)[number];

export const MoodTypeSchema = z.enum(MOOD_TYPES);

/** Self-harm safety flag. Only one variant in S3; keep open for future flags. */
export const SAFETY_FLAGS = ['self_harm_safety'] as const;
export type SafetyFlag = (typeof SAFETY_FLAGS)[number];

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

export const AnalyzeMoodTextRequestSchema = z.object({
  // Trim before length check so " " is invalid; cap mirrors `MoodEntry.text`.
  text: z
    .string()
    .transform((s) => s.trim())
    .pipe(z.string().min(1).max(500)),
  requestId: z.string().uuid(),
  locale: z.string().min(2).max(8).optional(),
  v: z.literal(1),
});

export type AnalyzeMoodTextRequest = z.infer<typeof AnalyzeMoodTextRequestSchema>;

// ---------------------------------------------------------------------------
// Gemini response (raw, model-emitted JSON)
// ---------------------------------------------------------------------------

/**
 * Schema we apply to Gemini's parsed JSON output.
 *
 * `confidence` accepts up to 2.0 deliberately: we clamp downstream to [0, 1]
 * (we'd rather log a `confidence_clamped` event than reject a usable answer).
 * `rationale` accepts up to 120 chars and is truncated to 80 in the success
 * envelope (see `analyzeMoodText.ts`).
 */
export const GeminiResponseSchema = z.object({
  mood: MoodTypeSchema,
  confidence: z.number().min(0).max(2),
  alternative: z
    .object({
      mood: MoodTypeSchema,
      confidence: z.number().min(0).max(2),
    })
    .nullable(),
  rationale: z.string().max(120),
  flag: z.enum(SAFETY_FLAGS).nullable(),
});

export type GeminiResponse = z.infer<typeof GeminiResponseSchema>;

// ---------------------------------------------------------------------------
// Response envelope (success / error union)
// ---------------------------------------------------------------------------

export interface AnalyzeMoodTextSuccess {
  ok: true;
  v: 1;
  requestId: string;
  mood: MoodTypeWire;
  confidence: number; // clamped to [0, 1]
  alternative: { mood: MoodTypeWire; confidence: number } | null;
  rationale: string; // <=80 chars on the wire (truncate from 120)
  flag?: SafetyFlag;
  latencyMs: number;
  modelVersion: string;
}

export type AnalyzeMoodTextErrorCode =
  | 'unauthenticated'
  | 'invalid_input'
  | 'rate_limited'
  | 'gemini_unavailable'
  | 'parse_error'
  | 'internal';

export interface AnalyzeMoodTextError {
  ok: false;
  v: 1;
  requestId: string;
  code: AnalyzeMoodTextErrorCode;
  message: string; // user-safe, no stack/PII
  retryAfterSec?: number; // only when code === 'rate_limited'
}

export type AnalyzeMoodTextResponse = AnalyzeMoodTextSuccess | AnalyzeMoodTextError;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

export const MODEL_VERSION = 'gemini-2.5-flash';
export const RATIONALE_WIRE_MAX = 80;
export const TEXT_MAX = 500;

// ---------------------------------------------------------------------------
// analyzePatterns — request / response schemas (ADR-0007)
// ---------------------------------------------------------------------------

/**
 * Request schema for `analyzePatterns`. Strict — rejects unknown keys at the
 * Zod boundary so a buggy refactor cannot accidentally smuggle `text` or
 * `mediaRefs` through the proxy. The schema deliberately has NO `text` field;
 * pattern analysis is computed from numeric mood codes + dates only.
 *
 * See ADR-0007 §"Request schema" for the canonical contract.
 */
export const AnalyzePatternsRequestSchema = z
  .object({
    requestId: z.string().uuid(),
    v: z.literal(1),
    windowDays: z.number().int().min(7).max(180),
    history: z
      .array(
        z
          .object({
            // Local-day ISO (YYYY-MM-DD). The client converts entry
            // `createdAt` to local midnight before serialising.
            date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
            moodCode: z.enum(MOOD_TYPES),
            intensity: z.number().int().min(1).max(5),
          })
          .strict(),
      )
      .max(500),
  })
  .strict();

export type AnalyzePatternsRequest = z.infer<typeof AnalyzePatternsRequestSchema>;
export type HistoryEntryWire = AnalyzePatternsRequest['history'][number];

/** Kind of insight; client maps to UI tone (chip + copy template). */
export const PATTERN_INSIGHT_KINDS = ['weekday', 'streak', 'trend', 'gemini'] as const;
export type PatternInsightKind = (typeof PATTERN_INSIGHT_KINDS)[number];
export const PatternInsightKindSchema = z.enum(PATTERN_INSIGHT_KINDS);

/** Single insight surfaced on the analytics dashboard. */
export interface PatternInsight {
  /** Stable id; e.g. "weekday:mon", "streak:negStrong:3", "gemini". */
  id: string;
  kind: PatternInsightKind;
  /** Compassionate copy, ≤140 chars, English (UI localises). */
  text: string;
  /** Already clamped to [0, 1]. Sample-size floor applied server-side. */
  confidence: number;
  sampleSize: number;
  /** ISO8601 UTC. */
  generatedAt: string;
}

export interface AnalyzePatternsSuccess {
  ok: true;
  v: 1;
  requestId: string;
  /** 0..N insights, statistical first then optional gemini. */
  insights: PatternInsight[];
  /** `null` when Gemini was skipped or failed; the model id otherwise. */
  modelVersion: string | null;
  latencyMs: number;
}

export type AnalyzePatternsErrorCode =
  | 'unauthenticated'
  | 'invalid_input'
  | 'rate_limited'
  | 'internal';

export interface AnalyzePatternsError {
  ok: false;
  v: 1;
  requestId: string;
  code: AnalyzePatternsErrorCode;
  message: string;
  retryAfterSec?: number;
}

export type AnalyzePatternsResponse =
  | AnalyzePatternsSuccess
  | AnalyzePatternsError;

/** Schema we apply to Gemini's parsed JSON for the themes-level insight. */
export const GeminiThemeResponseSchema = z.object({
  insightText: z.string().max(140),
  confidence: z.number().min(0).max(1),
});
export type GeminiThemeResponse = z.infer<typeof GeminiThemeResponseSchema>;

/** Sample-size floor: insights below this size are clamped to confidence ≤0.5. */
export const PATTERN_SAMPLE_FLOOR = 10;

/** Maximum confidence a Gemini-only insight may reach (server-clamped). */
export const PATTERN_GEMINI_MAX_CONFIDENCE = 0.7;
