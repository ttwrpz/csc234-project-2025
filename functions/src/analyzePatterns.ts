// Cloud Function for pattern analysis on the user's mood history.
// Statistical-primary, Gemini-supplementary. Mirrors the validation
// order of `analyzeMoodText.ts`: auth → Zod (.strict for the PII fence)
// → rate-limit → deterministic statistical compute (always) → optional
// Gemini themes → respond. Gemini failure is non-fatal.

import { logger } from 'firebase-functions';
import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { ZodError } from 'zod';

import { analyzeForPatterns, GEMINI_API_KEY } from './geminiClient.js';
import { consumeToken } from './rateLimit.js';
import {
  AnalyzePatternsRequestSchema,
  type AnalyzePatternsErrorCode,
  type AnalyzePatternsResponse,
  GeminiThemeResponseSchema,
  type HistoryEntryWire,
  MODEL_VERSION,
  PATTERN_GEMINI_MAX_CONFIDENCE,
  PATTERN_SAMPLE_FLOOR,
  type PatternInsight,
} from './types.js';

const PATTERNS_RATE_LIMIT_WINDOW_MS = 30_000;
// Raised from 1 -> 6 per 30s: the Patterns screen re-requests when the user
// switches the day-range window (7d/14d/30d) and on retries, and 1/30s was
// rejecting those legitimate follow-ups. Still well below an abuse rate.
const PATTERNS_RATE_LIMIT_MAX = 6;

/** Wall-clock cap for the Gemini supplementary call. */
const GEMINI_TIMEOUT_MS = 5_000;

/**
 * Sample-size floor below which we skip the Gemini supplementary call
 * entirely. The history is clipped to the selected day range (7/14/30d)
 * before this check, and the prompt now returns a gentle descriptive
 * reflection even for small/mixed windows (instead of bailing to "no clear
 * theme"), so the floor only needs to guarantee there is *something* to
 * reflect on. 3 is that minimum; below it we skip the round-trip, and the
 * sample-size floor (PATTERN_SAMPLE_FLOOR) caps confidence to ≤0.5 for
 * anything under 10 samples anyway.
 */
const PATTERNS_GEMINI_SAMPLE_FLOOR = 3;

/** Mood codes that are NOT positive. Mirrors `MoodType.category` on
 *  Dart. `okay` is classified as positive (sign +1), so it is excluded
 *  here to keep the server's negativity bucket aligned with the client. */
const NEGATIVE_MOOD_CODES = new Set<HistoryEntryWire['moodCode']>([
  'sad',
  'angry',
  'anxious',
]);

const WEEKDAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

function clamp(n: number, lo: number, hi: number): number {
  if (n < lo) return lo;
  if (n > hi) return hi;
  return n;
}

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

function makeError(
  ctx: { requestId: string },
  code: AnalyzePatternsErrorCode,
  message: string,
  retryAfterSec?: number,
): AnalyzePatternsResponse {
  const out: AnalyzePatternsResponse = {
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

// ---------------------------------------------------------------------------
// Statistical generators (pure; exported for unit tests)
// ---------------------------------------------------------------------------

interface NumericEntry {
  date: string; // YYYY-MM-DD
  moodCode: HistoryEntryWire['moodCode'];
  intensity: number;
  weekday: number; // 0..6 (Sun..Sat) per Date.getUTCDay
}

function preparseHistory(history: HistoryEntryWire[]): NumericEntry[] {
  return history.map((e) => ({
    date: e.date,
    moodCode: e.moodCode,
    intensity: e.intensity,
    weekday: new Date(`${e.date}T00:00:00Z`).getUTCDay(),
  }));
}

/**
 * Weekday z-score over the supplied history. Considers only negative-category
 * entries; emits at most one insight (the worst weekday with `|z|>1.0` and
 * `n≥10`).
 */
export function weekdayInsight(
  history: NumericEntry[],
  generatedAt: string,
): PatternInsight | null {
  const negatives = history.filter((e) => NEGATIVE_MOOD_CODES.has(e.moodCode));
  if (negatives.length === 0) return null;

  // Per-weekday: sum + count, keyed by 0..6. Using a `Map<number, ...>` so
  // we can read with a `?? 0` default without `noUncheckedIndexedAccess`
  // widening every read to `number | undefined`.
  const sumByWd = new Map<number, number>();
  const countByWd = new Map<number, number>();
  for (const e of negatives) {
    sumByWd.set(e.weekday, (sumByWd.get(e.weekday) ?? 0) + e.intensity);
    countByWd.set(e.weekday, (countByWd.get(e.weekday) ?? 0) + 1);
  }

  const meanByWd: Array<number | null> = [];
  for (let i = 0; i < 7; i += 1) {
    const c = countByWd.get(i) ?? 0;
    const s = sumByWd.get(i) ?? 0;
    meanByWd.push(c > 0 ? s / c : null);
  }

  const validMeans = meanByWd.filter((m): m is number => m !== null);
  if (validMeans.length < 2) return null;

  const meanOfMeans =
    validMeans.reduce((a, b) => a + b, 0) / validMeans.length;
  const variance =
    validMeans.reduce((acc, m) => acc + (m - meanOfMeans) ** 2, 0) /
    validMeans.length;
  const stdDev = Math.sqrt(variance);
  if (stdDev === 0) return null;

  // Find the most-negative weekday (highest mean intensity ≈ "worst" mood).
  let worstWd = -1;
  let worstZ = 0;
  let worstMean = 0;
  for (let i = 0; i < 7; i += 1) {
    const m = meanByWd[i];
    if (m === null || m === undefined) continue;
    const z = (m - meanOfMeans) / stdDev;
    if (z > worstZ) {
      worstZ = z;
      worstWd = i;
      worstMean = m;
    }
  }
  if (worstWd === -1 || worstZ <= 1.0) return null;
  const sampleSize = countByWd.get(worstWd) ?? 0;
  if (sampleSize < PATTERN_SAMPLE_FLOOR) return null;

  // Rest-of-week mean for the copy template ("X.X higher than the rest").
  const restMeans: number[] = [];
  for (let i = 0; i < 7; i += 1) {
    if (i === worstWd) continue;
    const m = meanByWd[i];
    if (m === null || m === undefined) continue;
    restMeans.push(m);
  }
  const restMean =
    restMeans.length > 0
      ? restMeans.reduce((a, b) => a + b, 0) / restMeans.length
      : meanOfMeans;
  const delta = worstMean - restMean;
  const deltaRounded = Math.round(delta * 10) / 10;

  const confidence = clamp(
    (Math.abs(worstZ) / 3) * (sampleSize / 30),
    0,
    1,
  );

  const wdName = WEEKDAY_NAMES[worstWd] ?? 'this day';
  return {
    id: `weekday:${wdName.toLowerCase().slice(0, 3)}`,
    kind: 'weekday',
    text: `Your ${wdName} mood averages ${deltaRounded.toFixed(1)} higher than the rest of the week.`,
    confidence: applySampleFloor(confidence, sampleSize),
    sampleSize,
    generatedAt,
  };
}

/**
 * 3+ consecutive distinct days each with ≥1 entry where mood is negative AND
 * intensity ≥ 4. Walks newest-to-oldest from the latest history date.
 */
export function streakInsight(
  history: NumericEntry[],
  generatedAt: string,
): PatternInsight | null {
  if (history.length === 0) return null;

  // Bucket by date - does this date have a heavy-negative entry?
  const heavyByDate = new Map<string, boolean>();
  for (const e of history) {
    const heavy = NEGATIVE_MOOD_CODES.has(e.moodCode) && e.intensity >= 4;
    heavyByDate.set(e.date, (heavyByDate.get(e.date) ?? false) || heavy);
  }

  // Walk back from the most recent date in history. Stop when a date has no
  // heavy-negative entry (or no entry at all).
  const sortedDates = Array.from(heavyByDate.keys()).sort().reverse();
  let runLength = 0;
  let cursor: string | undefined = sortedDates[0];
  if (cursor === undefined) return null;
  for (const d of sortedDates) {
    if (d !== cursor) break;
    if (heavyByDate.get(d) !== true) break;
    runLength += 1;
    cursor = decrementDate(cursor);
  }

  if (runLength < 3) return null;

  const confidence = Math.min(1, runLength / 7);
  return {
    id: `streak:heavy:${runLength}`,
    kind: 'streak',
    text: "You've had three or more heavy days in a row.",
    confidence: applySampleFloor(confidence, runLength),
    sampleSize: runLength,
    generatedAt,
  };
}

/**
 * 30-day trend via closed-form least-squares on daily-mean intensity.
 * Days with no entry are excluded (not zeroed) - slope reflects the days
 * the user actually logged.
 */
export function trendInsight(
  history: NumericEntry[],
  generatedAt: string,
  nowIsoDay: string,
): PatternInsight | null {
  // Build daily-mean window over the last 30 calendar days (counted back from
  // nowIsoDay, inclusive). Excludes days with no entry.
  const cutoff = new Date(`${nowIsoDay}T00:00:00Z`);
  cutoff.setUTCDate(cutoff.getUTCDate() - 29);
  const cutoffIso = cutoff.toISOString().slice(0, 10);

  const sumByDate = new Map<string, { sum: number; count: number }>();
  for (const e of history) {
    if (e.date < cutoffIso) continue;
    if (e.date > nowIsoDay) continue;
    const cur = sumByDate.get(e.date) ?? { sum: 0, count: 0 };
    cur.sum += e.intensity;
    cur.count += 1;
    sumByDate.set(e.date, cur);
  }

  const n = sumByDate.size;
  if (n < 14) return null;

  // x = day-index 0..29 from cutoff; y = daily mean.
  const points: Array<{ x: number; y: number }> = [];
  const cutoffMs = Date.UTC(
    cutoff.getUTCFullYear(),
    cutoff.getUTCMonth(),
    cutoff.getUTCDate(),
  );
  for (const [date, agg] of sumByDate) {
    const dayMs = Date.UTC(
      Number(date.slice(0, 4)),
      Number(date.slice(5, 7)) - 1,
      Number(date.slice(8, 10)),
    );
    const x = Math.round((dayMs - cutoffMs) / 86_400_000);
    points.push({ x, y: agg.sum / agg.count });
  }

  const meanX = points.reduce((a, p) => a + p.x, 0) / n;
  const meanY = points.reduce((a, p) => a + p.y, 0) / n;
  let num = 0;
  let den = 0;
  for (const p of points) {
    num += (p.x - meanX) * (p.y - meanY);
    den += (p.x - meanX) ** 2;
  }
  if (den === 0) return null;
  const slope = num / den;

  if (Math.abs(slope) <= 0.05) return null;

  const direction = slope > 0 ? 'up' : 'down';
  const confidence = clamp(Math.abs(slope) * 10 * (n / 30), 0, 1);
  return {
    id: `trend:${direction}`,
    kind: 'trend',
    text: `Your mood has been trending ${direction} over the past 30 days.`,
    confidence: applySampleFloor(confidence, n),
    sampleSize: n,
    generatedAt,
  };
}

/**
 * Sample-size floor: confidence cannot exceed 0.5 when sampleSize is below
 * the floor, regardless of effect size. Applied uniformly to statistical
 * AND Gemini-supplementary insights.
 */
export function applySampleFloor(confidence: number, sampleSize: number): number {
  if (sampleSize < PATTERN_SAMPLE_FLOOR) return Math.min(confidence, 0.5);
  return confidence;
}

function decrementDate(iso: string): string {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export async function handleAnalyzePatterns(
  request: CallableRequest<unknown>,
): Promise<AnalyzePatternsResponse> {
  // 1. Auth check.
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const uid = request.auth.uid;

  // 2. Schema (.strict - PII fence).
  let parsed;
  try {
    parsed = AnalyzePatternsRequestSchema.parse(request.data);
  } catch (e) {
    const requestId = extractRequestId(request.data);
    const reason = e instanceof ZodError ? e.issues[0]?.code ?? 'invalid' : 'invalid';
    logger.info({
      event: 'analyzePatterns',
      requestId,
      uid,
      outcome: 'invalid_input',
      errorReason: reason,
    });
    return makeError(
      { requestId },
      'invalid_input',
      'Invalid request payload.',
    );
  }

  const startMs = Date.now();
  const generatedAt = new Date(startMs).toISOString();

  // 3. Rate limit (1 req / 30s on a separate doc family so it does not
  // interact with the analyzeMoodText limiter).
  let rateLimit;
  try {
    rateLimit = await consumeToken(uid, undefined, {
      windowMs: PATTERNS_RATE_LIMIT_WINDOW_MS,
      max: PATTERNS_RATE_LIMIT_MAX,
      collection: 'rateLimits.patterns',
    });
  } catch (e) {
    logger.error({
      event: 'analyzePatterns',
      requestId: parsed.requestId,
      uid,
      outcome: 'internal',
      errorReason: 'rate_limit_tx_failed',
      cause: e instanceof Error ? e.name : 'unknown',
    });
    return makeError(
      { requestId: parsed.requestId },
      'internal',
      'Internal error.',
    );
  }
  if (!rateLimit.allowed) {
    logger.info({
      event: 'analyzePatterns',
      requestId: parsed.requestId,
      uid,
      outcome: 'rate_limited',
      rateLimit: { remaining: 0, retryAfterSec: rateLimit.retryAfterSec },
    });
    return makeError(
      { requestId: parsed.requestId },
      'rate_limited',
      'Too many requests. Try again in a moment.',
      rateLimit.retryAfterSec,
    );
  }

  // 4. Clip the history to the selected day range, THEN compute, so every
  // insight reflects the windowDays the user picked on the chip (7/14/30)
  // instead of the whole account. Anchored on the latest ENTRY date (not
  // the server clock) - keeps the suite deterministic and gives an inactive
  // user their most recent window. Entry dates are local-day ISO strings,
  // so the lexical `>=` compare is a date compare.
  const latestEntryDate = parsed.history.reduce<string>(
    (acc, e) => (e.date > acc ? e.date : acc),
    '',
  );
  let windowedHistory = parsed.history;
  if (latestEntryDate !== '') {
    const cutoff = new Date(`${latestEntryDate}T00:00:00Z`);
    cutoff.setUTCDate(cutoff.getUTCDate() - (parsed.windowDays - 1));
    const cutoffIso = cutoff.toISOString().slice(0, 10);
    windowedHistory = parsed.history.filter((e) => e.date >= cutoffIso);
  }

  // 4b. Statistical compute (always - deterministic happy path).
  const numeric = preparseHistory(windowedHistory);
  const insights: PatternInsight[] = [];

  const wkd = weekdayInsight(numeric, generatedAt);
  if (wkd) insights.push(wkd);

  const streak = streakInsight(numeric, generatedAt);
  if (streak) insights.push(streak);

  // For trend we need a "today" anchor; use the latest history date as a
  // proxy so the test suite is deterministic without injecting Date.now.
  const latestDate = numeric.reduce<string>(
    (acc, e) => (e.date > acc ? e.date : acc),
    '0000-00-00',
  );
  if (latestDate !== '0000-00-00') {
    const tr = trendInsight(numeric, generatedAt, latestDate);
    if (tr) insights.push(tr);
  }

  // 5. Gemini supplementary call. Always non-fatal - any failure
  // swallows gracefully and the statistical insights ship on their own.
  const statisticalInsightCount = insights.length;
  let geminiSkipped = false;
  let geminiSkipReason:
    | 'sample_too_small'
    | 'timeout'
    | 'parse_error'
    | 'gemini_unavailable'
    | null = null;
  // PII-safe failure class for the skip path: the Error constructor name
  // only (e.g. 'SyntaxError' = empty/truncated/malformed model output;
  // 'ZodError' = output parsed but failed the theme schema). Never the
  // error message - JSON.parse messages can echo a fragment of the model
  // output. Lets us tell *why* a parse_error happened from the logs alone.
  let geminiErrorName: string | null = null;

  if (windowedHistory.length < PATTERNS_GEMINI_SAMPLE_FLOOR) {
    geminiSkipped = true;
    geminiSkipReason = 'sample_too_small';
  } else {
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), GEMINI_TIMEOUT_MS);
    try {
      const gem = await analyzeForPatterns(
        windowedHistory,
        parsed.windowDays,
        ac.signal,
      );
      clearTimeout(timer);
      try {
        const validated = GeminiThemeResponseSchema.parse(gem.raw);
        const sampleSize = windowedHistory.length;
        // Cap Gemini's confidence at PATTERN_GEMINI_MAX_CONFIDENCE (it can't
        // claim "high" certainty from numeric codes alone), THEN apply the
        // sample-size floor: a narrow day range can now feed as few as
        // PATTERNS_GEMINI_SAMPLE_FLOOR entries, and a small sample must not
        // present as high confidence.
        const confidence = applySampleFloor(
          Math.min(validated.confidence, PATTERN_GEMINI_MAX_CONFIDENCE),
          sampleSize,
        );
        insights.push({
          id: 'gemini',
          kind: 'gemini',
          text: validated.insightText,
          confidence,
          sampleSize,
          generatedAt,
        });
      } catch (e) {
        // Schema validation failed - Gemini returned malformed JSON.
        geminiSkipped = true;
        geminiSkipReason = 'parse_error';
        geminiErrorName = e instanceof Error ? e.name : 'unknown';
      }
    } catch (e) {
      clearTimeout(timer);
      geminiSkipped = true;
      geminiErrorName = e instanceof Error ? e.name : 'unknown';
      const aborted = ac.signal.aborted;
      const isSyntax = e instanceof SyntaxError;
      if (isSyntax) {
        geminiSkipReason = 'parse_error';
      } else if (aborted) {
        geminiSkipReason = 'timeout';
      } else {
        geminiSkipReason = 'gemini_unavailable';
      }
    }
  }

  const totalLatencyMs = Date.now() - startMs;

  // 6. Structured log line. ALLOWED fields only - no `history`, no insight
  // text bodies. The PII canary test asserts this.
  logger.info({
    event: 'analyzePatterns',
    requestId: parsed.requestId,
    uid,
    outcome: 'success',
    windowDays: parsed.windowDays,
    historyLen: parsed.history.length,
    windowedLen: windowedHistory.length,
    insightCount: insights.length,
    statisticalInsightCount,
    geminiSkipped,
    geminiSkipReason,
    geminiErrorName,
    latencyTotalMs: totalLatencyMs,
    rateLimit: {
      remaining: rateLimit.remaining,
      retryAfterSec: 0,
    },
  });

  // 7. Success envelope.
  return {
    ok: true,
    v: 1,
    requestId: parsed.requestId,
    insights,
    modelVersion: geminiSkipped ? null : MODEL_VERSION,
    latencyMs: totalLatencyMs,
  };
}

/**
 * The exported v2 callable.
 *
 * App Check enforcement is **temporarily disabled**. The Flutter web
 * client does not yet initialise `firebase_app_check`, so with
 * `enforceAppCheck: true` browser preflight requests were failing and
 * surfacing as opaque CORS errors. Re-enable once the client wires up
 * `FirebaseAppCheck.instance.activate(...)` and a reCAPTCHA v3 site key
 * is registered in Firebase Console → App Check.
 */
export const analyzePatterns = onCall(
  {
    region: 'asia-southeast1',
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    enforceAppCheck: false,
  },
  handleAnalyzePatterns,
);
