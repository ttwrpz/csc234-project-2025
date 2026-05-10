# ADR-0007 — Pattern Analysis Fallback Strategy (Statistical-Primary, Gemini-Supplementary)

**Status:** Superseded by ADR-0011 (2026-05-09)
**Date:** 2026-05-01
**Deciders:** orchestrator + architect
**Related:** ADR-0001 (repo structure & Clean Architecture); ADR-0003 (`analyzeMoodText` Cloud Function contract — wire format, validation order, rate-limit scaffolding, logging schema); CLAUDE.md pivot feature #4 ("Gemini pattern analysis over history with explicit confidence labels"); CLAUDE.md feature flag `ai_pattern_analysis_enabled`

> **Superseded.** The intervention-trigger path moves from `analyzePatterns` (Cloud Function, statistical-primary) to a client-side pure-Dart Pattern Engine running five algorithms (Mann-Kendall, sliding 5-of-7, 3-consecutive, Z-score, CUSUM) per ADR-0011. The `analyzePatterns` Cloud Function remains deployed for the Insights screen (qualitative themes, confidence bands, sample-size floors) but no longer drives the dispatcher. The `ai_pattern_analysis_enabled` flag continues to gate the Gemini themes path, not the intervention path. See ADR-0011 §3 and `docs/audit/sprint-4-redesign-audit.md` for the full migration plan.

## Context

Sprint 4 acceptance demands "≥1 Pattern Insight visible with confidence label" on a graded demo, with a kill-switch rehearsal that flips `ai_pattern_analysis_enabled` to `false` and confirms the Insights card hides within 60 seconds. The two halves of that requirement are in tension. The first half wants Gemini's qualitative themes ("you tend to feel calmer on weekend mornings"). The second half presupposes that the system tolerates Gemini being absent.

Three operational realities shape the design:

1. **Gemini is non-deterministic.** Even with `temperature: 0.2`, structured-output mode (`responseMimeType: 'application/json'` plus `responseSchema`), and a tightly templated system prompt, Gemini can produce empty arrays, malformed JSON, or 5xx-class transport failures. ADR-0003's `analyzeMoodText` contract handles this for the single-entry classifier by mapping every failure mode to a typed `AiAnalysisFailure` and degrading the UX (the suggestion pill hides; manual mood pick still works). For pattern analysis the equivalent fallback cannot simply be "no insight" — that flunks the demo acceptance bar.
2. **The history payload is PII-dense.** A naive request shape would send `List<MoodEntry>` with `text` and `mediaRefs` to Gemini through the proxy. Each entry's `text` is the most sensitive field in the entire app — it is the user's free-form journal. We cannot send it server-side for pattern analysis when the patterns are derivable from numeric data alone, and we definitely cannot let it land in Cloud Function logs or in Gemini's prompt. CLAUDE.md "Never log PII (mood text, email, uid-with-text)" is non-negotiable.
3. **Confidence must be honest.** The card displays a confidence band (low / mid / high). A 5-sample weekday claim is not "high confidence" no matter what Gemini says. The sample-size floor must clamp confidence server-side AND defensively client-side.

ADR-0003 established the validation pipeline (auth → Zod → rate-limit → Gemini → respond), the Firestore-backed rate-limit scaffolding (`rateLimits/{uid}` document, transactional `consumeToken`), and the typed `Result<AiSuggestion, AiAnalysisFailure>` mapping on the Dart side. ADR-0007 extends that scaffolding without replacing it.

The S3 detector for Sprint-3-end did not need pattern insights; the S4 acceptance bar makes them load-bearing.

## Decision

### Statistical-primary, Gemini-supplementary

The new `analyzePatterns` Cloud Function **always** computes deterministic insights server-side from numeric mood codes plus dates. It **optionally** calls Gemini for one extra "themes" insight. Gemini failure (timeout, 5xx, malformed JSON, empty result) is **non-fatal** — the response still ships with the statistical insights and one extra log field `geminiSkipped: true` plus `geminiSkipReason: 'timeout' | 'parse_error' | 'gemini_unavailable' | 'flag_disabled'`.

This guarantees the acceptance bar holds under a full Gemini outage: as long as the user has ≥10 historical entries on at least one weekday, a weekday z-score insight will be generated and shown.

### Request schema (Zod, strict)

The request schema deliberately omits any text or media fields. The `.strict()` modifier rejects unknown keys at the Zod boundary, which closes the door on a future bug where a refactor might accidentally include `text` in the projection.

```ts
AnalyzePatternsRequestSchema = z.object({
  requestId: z.string().uuid(),
  v: z.literal(1),
  windowDays: z.number().int().min(7).max(180),
  history: z.array(z.object({
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    moodCode: z.enum(MOOD_TYPES),
    intensity: z.number().int().min(1).max(5),
  })).max(500),
}).strict();
```

Three things to notice:

- No `text` field at any nesting level. A request that includes `text` is rejected at Zod-parse time with `invalid_input`.
- No `mediaRefs` field. The presence of an attached photo is irrelevant to mood patterns and would only add a vector for accidentally exposing storage paths.
- `history` is capped at 500 entries. At one entry per day for 180 days the natural ceiling is 180; 500 gives headroom for users who log multiple times per day without unbounded payloads.

### Statistical insight definitions

The function emits zero, one, two, or three statistical insights. Each insight has the shape `{ id, kind, text, confidence, sampleSize, generatedAt }`. The three generators are:

**Weekday z-score over `windowDays`.** Group history by weekday (Mon–Sun), compute mean intensity of negative entries (entries where `MoodType.fromCode(moodCode).category != positive`) per weekday, and compute the z-score of each weekday's mean against the cross-weekday distribution. For the worst weekday (most-negative z-score) where `|z| > 1.0` AND that weekday has `n ≥ 10` entries, emit:

```
"Your <weekday> mood averages X.X lower than the rest of the week"
```

with `X.X = mean_other_days - mean_this_day` rounded to one decimal. Confidence:

```
confidence = clamp(0, 1, (|z| / 3) * (n / 30))
```

Rationale: a weekday with `|z| = 1.0` and `n = 10` produces `confidence = 0.11` (low band, outlined chip with yellow text). A weekday with `|z| = 3.0` and `n = 30` produces `confidence = 1.0` (high band, filled primary). Both factors must be present to land in the mid or high band.

**3-day intensity-≥4 streak.** Walk history newest-to-oldest; count the run of consecutive distinct local-midnight days each containing ≥1 entry with `mood.category != positive` AND `intensity ≥ 4`. If `runLength ≥ 3`, emit a streak insight:

```
"You've had three or more heavy days in a row"
```

(exact wording locked at PR time, per Sprint 4 plan Open Question O-2). Confidence:

```
confidence = min(1.0, runLength / 7)
```

`sampleSize = runLength`. A 3-day run gives `confidence = 0.43` (mid band); a 7-or-more-day run gives `confidence = 1.0`.

**30-day trend (least-squares).** Compute daily mean intensity over the last 30 days (days with no entry are excluded, not zeroed). Apply closed-form linear regression `slope = Σ((x_i - x̄)(y_i - ȳ)) / Σ((x_i - x̄)^2)` where `x` is day-index `0..29` and `y` is the daily mean. If `|slope| > 0.05/day` AND `n ≥ 14` (at least 14 days with at least one entry in the 30-day window), emit:

```
"Your mood has been trending up over the past 30 days"   // slope > 0
"Your mood has been trending down over the past 30 days" // slope < 0
```

Confidence:

```
confidence = clamp(0, 1, |slope| * 10 * (n / 30))
```

A `slope = 0.05/day` over `n = 14` days produces `confidence = 0.23` (low band). A `slope = 0.15/day` over `n = 28` days produces `confidence = 1.4` clamped to `1.0` (high band).

All three computations are pure numeric — no `text` is read, no `mediaRefs` is read.

### Gemini supplementary call

If `featureFlags.aiPatternAnalysisEnabled` is true on the server side AND the statistical insights produced ≥1 result, the function calls Gemini once with a prompt that receives only the numeric history (date + moodCode + intensity) and asks for a single themes-level observation. The call is wrapped in a 5s `AbortController` mirroring ADR-0003. On success, the response is Zod-validated and appended as a fourth insight with `kind: 'gemini'`. On any failure (abort, 5xx, parse_error, schema mismatch, empty), the function logs `geminiSkipped: true` with a reason and proceeds with the statistical insights only. There is no retry.

The Gemini insight's confidence is server-clamped to `0.7` maximum — Gemini's qualitative reads are inherently less anchored than the statistical generators, and we do not want a Gemini-only result to render in the high-confidence band.

### Confidence bands and chip styling

```
confidence < 0.5      → outlined Chip with warning-yellow text     (low band)
0.5 ≤ confidence < 0.8 → filled Chip default surface               (mid band)
confidence ≥ 0.8      → filled Chip primary surface                (high band)
```

Sample size is shown as a muted `bodySmall` badge `"$n samples"` adjacent to the chip. This duality (confidence band + sample-size badge) lets a careful reader sanity-check the chip — a high-confidence claim with `n = 11` is visibly thin even if the math says `clamp(0,1, ...) = 0.83`. Both displays are surfaced; neither is editorialised.

### PII fence

Three layers of defence ensure mood text never leaves the client and never lands in any log:

1. **Client datasource projection.** `analyze_patterns_functions_datasource.dart` projects each `MoodEntry` to `{ date, moodCode, intensity }` only. A unit test asserts `projected[0].containsKey('text') == false` and `projected[0].containsKey('mediaRefs') == false`. This is the single most important client-side test for the entire feature — any future refactor that breaks the projection will fail this test before it lands.
2. **Server Zod schema.** `AnalyzePatternsRequestSchema.strict()` rejects any request that contains `text` or `mediaRefs` (or any other unknown key). Even a misbehaving client cannot accidentally smuggle text through.
3. **Server logger schema.** Allowed log fields: `event, requestId, uid, outcome, windowDays, historyLen, insightCount, statisticalInsightCount, geminiSkipped, geminiSkipReason, latencyTotalMs, latencyGeminiMs, rateLimit.{remaining, retryAfterSec}, errorReason`. Forbidden: `history`, `history[].date`, any `text`, any rendered insight body. A **PII canary** test in `analyzePatterns.test.ts` asserts that no captured log payload across the 10-case suite contains `'2026-'` (a date prefix would indicate `history[].date` leaked) or the rendered insight body strings.

### Reasoning

The decision is statistical-primary, Gemini-supplementary, with a strict request schema and a sample-size floor, because:

- **Acceptance-robust under Gemini outage.** A graded demo cannot afford to flip a coin on Gemini's availability. Statistical insights produce on every request that has enough history; Gemini layers on top when it works.
- **PII surface minimal.** No `text`, no `mediaRefs`, ever. Three independent defences (client projection, server schema, log allowlist).
- **Auditable confidence.** The two-factor confidence formula (effect size × sample size) is reviewable and explainable — `n = 10` floor + `|z| > 1.0` is a defensible threshold a reviewer can sanity-check by eye.
- **Cost ceiling.** At most one Gemini call per request, rate-limited 1 request per 30 seconds per uid. A user opening the analytics screen 100 times in a session triggers at most ~200 Gemini calls per hour — well under the project's daily quota.
- **Compatible with ADR-0003.** Validation order, rate-limit scaffolding, secret handling, and structured-log conventions are reused; only the new schemas and the new computation path are additive.

## Consequences

**Positive**

- Graceful degradation by construction. The deterministic happy path lands the demo whether Gemini answers or not.
- The PII fence is testable and tested. The unit test on the client projection is the single guard that future refactors must respect.
- Confidence labels are honest. A weekday claim with `n = 5` cannot reach the mid band no matter what the effect size is.
- The wire format is forward-compatible. Future generators (e.g. monthly cycle, time-of-day) bolt on without a `v: 2` bump.

**Negative / trade-offs**

- Two insight generators (statistical + Gemini) to maintain. Statistical generator is owned by the architect contract here; Gemini prompt and `responseSchema` will live alongside `analyzeMoodText.ts` in `geminiClient.ts`.
- The Gemini insight's text shape is locked via `responseSchema` — future prompt iterations may need a `v: 2` bump if the response field set changes.
- Server-side feature-flag check (`aiPatternAnalysisEnabled`) requires the function to read Remote Config server-side OR for the client to short-circuit by not calling at all. Decision: the client gates the call (the card returns `SizedBox.shrink()` and never invokes the datasource when the flag is false). The server defensively also checks via the request never being made; if a misbehaving client calls anyway, the function still runs because the kill-switch's job is to hide the UI, not to refuse compute.

**Follow-up work this creates**

- `packages/core/lib/src/date_utils.dart` exporting `DateTime localMidnight(DateTime dt)` is created on Day 3 alongside the pattern detector. `compute_garden_state.dart:70` and `compute_analytics_state.dart:89` migrate to it (they have identical helpers today).
- `AIAnalysisRepository` gains `bool get isEnabled` and `Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns(...)`. The same repository (not a sibling) keeps the AI surface coherent.
- `firestore.rules` already permits owner-read on `users/{uid}/insights/{id}` and admin-only write (S3 anticipated S4). No rule changes in S4. Insights are written by the function's admin SDK.
- The runbook `docs/runbooks/feature-flag-rollback.md` documents the demo kill-switch flow and the temporary 60s `minimumFetchInterval` lowering for demo day (with a v1.0.1 patch to restore 60min).
- A future ADR-0008 (S5) will specify the cheer-up intervention banner that consumes `interventionStateProvider` and may consume `analyzePatterns` insights for personalisation.

## Alternatives Considered

- **Gemini-only with statistical as supplementary.** Rejected. Fails the acceptance bar when Gemini is unavailable. The whole point of the kill-switch rehearsal is to demonstrate that the system survives Gemini's absence; making Gemini the primary insight source contradicts that goal.
- **Conditional Gemini gating** (e.g. only call Gemini when statistical insights are weak). Rejected. Adds complexity (a "weakness" threshold function) without payoff — the cost of an unconditional call is bounded by the rate limit, and the user benefits from a Gemini themes insight even when the statistical insights are strong.
- **No Gemini at all, statistical only.** Rejected. CLAUDE.md pivot feature #4 explicitly grades Gemini pattern analysis. Removing Gemini sidesteps the requirement rather than meeting it.
- **Send `text` to Gemini for theme extraction.** Rejected. PII surface explosion. The Gemini themes insight is computable from numeric data plus a careful prompt; we accept that this constrains Gemini's output to weaker themes and judge the trade worth it.
- **Persist Gemini insights to `users/{uid}/insights/{id}` and serve from cache on subsequent requests.** Rejected for S4 (deferred to S5 if needed). The current design re-computes per request, which is cheap (numeric compute is microseconds; rate limit caps Gemini cost). Caching adds Firestore writes and a TTL to reason about; not worth it before user-base growth.
- **No `responseSchema` constraint on Gemini.** Rejected for the same reason as ADR-0003 — structured-output mode collapses the parse-error class to a rare exception.

## Compliance Check

- Clean Architecture domain-zero-imports rule: satisfied. `PatternInsight` (Freezed) lives in `apps/mobile/lib/features/analytics/domain/entities/`; `AIAnalysisRepository` (extended) is abstract in `domain/`. The Cloud Function is server-side TypeScript and lives outside the Dart layer boundaries.
- Enterprise Term Assignment requirements touched: **R1** (acceptance criteria from the kickoff are now traceable through the architecture); **R3** (architecture quality — the validation pipeline is reused); **R5** (correctness via PII-canary test, security via Zod-strict schema and App Check enforcement, performance via 5s abort and rate limit).
- Quality gates affected: **Correctness** (10-case server suite + datasource projection unit test, ≥90% server coverage); **Security** (App Check `enforceAppCheck: true`, Zod `.strict()` PII fence, no-PII log allowlist, rate limit reused from ADR-0003 with parameterised `consumeToken`); **Accessibility** (confidence-band styling pairs colour with shape — outlined vs filled chip — so the bands are distinguishable in grayscale); **Performance** (5s `AbortController` on Gemini, max one Gemini call per request, rate-limit 1/30s/uid).
- CLAUDE.md "Never log PII" — satisfied via the three-layer fence (client projection, server schema, log allowlist) and the PII canary test.
- CLAUDE.md "Gemini via Cloud Functions proxy, never direct from app" — satisfied. Client never holds the API key; Gemini is called server-side only.
- CLAUDE.md feature flag `ai_pattern_analysis_enabled` — satisfied. The card renders `SizedBox.shrink()` when the flag is false; the kill-switch rehearsal in the demo script verifies the 60s hide-window.
- ADR-0003 contract reuse: validation order, rate-limit transaction shape, secret-binding ceremony, structured-log line conventions all reused. New surface area (request schema, statistical generators, response shape) is additive.
