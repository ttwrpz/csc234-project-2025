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
