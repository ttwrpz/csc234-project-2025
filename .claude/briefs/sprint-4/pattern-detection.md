# Handoff Brief — Pattern Detection (WBS 5.3 + 5.4)

**WBS:** 5.3 (`analyzePatterns` CF + Insights UI + RC gate), 5.4 (Pattern detector + cooldown + escalation)
**Sprint:** S4
**Day:** Day 3 (Fri 2026-05-08)
**Target branch:** `feat/5.3-5.4-pattern-detection`
**Owner:** flutter-engineer (Kraiwich), with security-reviewer audit PM Day 3

## Goal

Ship two things on Day 3: (1) the `analyzePatterns` Cloud Function plus its client datasource and the `PatternInsightCard` widget that renders insights on the Analytics screen, gated by `ai_pattern_analysis_enabled`; (2) the pure-Dart `pattern_detector.dart` + `intervention_state.dart` entities that S5's cheer-up banner will consume. The detector is wiring-only in S4 — no UI, no banner. The card on Analytics IS the user-visible deliverable.

The architectural decisions for this work are locked in **ADR-0007** (statistical-primary, Gemini-supplementary; Zod `.strict()` PII fence; confidence bands; sample-size floor). Read ADR-0007 before opening any file.

## Day 3 breakdown

### Morning — server (`functions/src/analyzePatterns.ts`)

1. NEW `functions/src/analyzePatterns.ts`. Mirror `analyzeMoodText.ts:79-285` line by line (auth check at the top, Zod parse, rate-limit `consumeToken` call, then the new compute path, then optional Gemini, then respond). `onCall` config: `region: 'asia-southeast1'`, `secrets: [GEMINI_API_KEY]`, `timeoutSeconds: 30`, `memory: '256MiB'`, **`enforceAppCheck: true`** (stricter than `analyzeMoodText`'s `false`; per kickoff Open Question O-1).
2. Edit `functions/src/rateLimit.ts`: parameterise `consumeToken(uid, nowMs?, opts?: { windowMs, max })` with the current values as defaults. `analyzeMoodText` callsite stays byte-identical. `analyzePatterns` calls with `{ windowMs: 30_000, max: 1 }` — one request per 30 seconds per uid.
3. Edit `functions/src/types.ts`: add `AnalyzePatternsRequestSchema` (the Zod schema in ADR-0007 §"Request schema"), `PatternInsight`, `AnalyzePatternsSuccess`, `AnalyzePatternsError`. The schema must be `.strict()` and must NOT contain a `text` or `mediaRefs` field at any nesting level.
4. Implement the three statistical generators per ADR-0007 §"Statistical insight definitions": weekday z-score, 3-day streak, 30-day trend. Pure numeric, no text reads.
5. Optional Gemini supplementary call: 5s `AbortController` mirroring `analyzeMoodText.ts`, response Zod-validated, server-clamp confidence to ≤0.7, on any failure log `geminiSkipped: true` and proceed.
6. Edit `functions/src/index.ts`: `export { analyzePatterns } from './analyzePatterns.js';`. The TODO at `index.ts:3` is already there.

**Validation order (mirror ADR-0003 / `analyzeMoodText.ts`):**

```
auth (HttpsError unauthenticated if no uid)
  → Zod-parse (invalid_input on failure; .strict() rejects unknown keys)
  → rate-limit (consumeToken with {windowMs:30_000, max:1}; rate_limited with retryAfterSec on failure)
  → statistical compute (always; deterministic; pure numeric)
  → Gemini call (optional; 5s AbortController; non-fatal on any failure)
  → emit one structured log line
  → return success
```

The rate-limit token is consumed BEFORE the Gemini call so a Gemini outage cannot DoS the project's quota.

### Afternoon — client + security review

**Datasource and repo wiring:**

1. NEW `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart` (Freezed): `id, text, confidence, sampleSize, generatedAt, kind: PatternInsightKind { weekday, streak, trend, gemini }`.
2. NEW `apps/mobile/lib/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart`. Clone `apps/mobile/lib/features/mood/data/datasources/ai_analysis_functions_datasource.dart` for transport-only typed-exception structure. **Hard rule:** the projection of `List<MoodEntry>` to the request body MUST drop `text` and `mediaRefs`. The unit test asserts `expect(projected[0].containsKey('text'), isFalse)` and `expect(projected[0].containsKey('mediaRefs'), isFalse)`. This is the most important test in the entire feature.
3. Extend `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` with `bool get isEnabled` and `Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({required List<MoodEntry> history, int windowDays = 90})`. Do NOT spawn a sibling repository — the AI surface stays coherent on one abstract.
4. Implement in `apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart`. `isEnabled` returns the `featureFlagsProvider.aiPatternAnalysisEnabled` value injected at construction.

**Card and Analytics insertion:**

5. NEW `apps/mobile/lib/features/analytics/presentation/widgets/pattern_insight_card.dart` (`ConsumerWidget`). First check `ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled` — return `SizedBox.shrink()` when `false`. When enabled, watch a new `patternInsightsProvider` (FutureProvider keyed on the current `MoodWindow`). Five UI states:
   - **loading** — skeleton placeholder
   - **error** — `"We couldn't read your patterns just now"` (no clinical language, no "failed", no "retry" CTA)
   - **empty** — `"Log a few more moods to see patterns"`
   - **data** — list rows, each with confidence chip + `"$n samples"` badge, styled per ADR-0007 §"Confidence bands"
   - **disabled** — hidden via `SizedBox.shrink()`
6. Edit `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart`: insert `const PatternInsightCard()` between `Expanded(_ChartBody)` and `_Legend`. Wrap the **insertion** in `if (ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled)` for defence in depth (the widget self-hides too — both layers exist intentionally).

**Copy templates locked at this PR (per Open Question O-2):**

- weekday: `"Your <weekday> mood averages X.X lower than the rest of the week"`
- trend up: `"Your mood has been trending up over the past 30 days"`
- trend down: `"Your mood has been trending down over the past 30 days"`
- streak: `"You've had three or more heavy days in a row"`

UX writer reviews post-merge.

### Late afternoon (parallel) — detector (WBS 5.4)

1. NEW `packages/core/lib/src/date_utils.dart`: pure-Dart `DateTime localMidnight(DateTime dt)`. Migrate `compute_garden_state.dart:70` AND `compute_analytics_state.dart:89` to use it (they have byte-identical helpers today). Re-export from `packages/core/lib/core.dart`. No new dependencies.
2. NEW `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart` (Freezed): `bool triggered, bool escalated, String reason` where `reason ∈ {'5_of_7_negative', '3_consecutive_high_intensity', 'cooldown', 'none'}`.
3. NEW `apps/mobile/lib/features/garden/domain/pattern_detector.dart` (pure function, no Flutter imports):

   ```dart
   InterventionState detectPattern(
     List<MoodEntry> entries, {
     required DateTime now,
     DateTime? lastTriggeredAt,
     DateTime? firstTriggeredAt,
   });
   ```

   Rules:
   - **5-of-7 days**: count distinct local-midnight days in last 7 with ≥1 entry where `mood.category != positive`. Trigger if count ≥ 5.
   - **3-consecutive ≥4 negative**: last 3 distinct days each have ≥1 entry with `mood.category != positive` AND `intensity ≥ 4`. Mixed neg types count.
   - **48h cooldown**: `lastTriggeredAt != null && now.difference(lastTriggeredAt) < 48h` → return `triggered: false, reason: 'cooldown'`.
   - **10-day escalation**: if `triggered && firstTriggeredAt != null && now.difference(firstTriggeredAt) >= 10d` → `escalated: true`.

   Pure function. No Flutter, no Firebase, no `package:cloud_firestore/*`. Domain-purity hook will reject any violating import.

## File index (NEW + EDIT)

**NEW (server):**
- `functions/src/analyzePatterns.ts`
- `functions/src/__tests__/analyzePatterns.test.ts`

**NEW (client):**
- `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart`
- `apps/mobile/lib/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart`
- `apps/mobile/lib/features/analytics/presentation/widgets/pattern_insight_card.dart`
- `apps/mobile/lib/features/garden/domain/pattern_detector.dart`
- `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart`
- `packages/core/lib/src/date_utils.dart`

**NEW (tests):**
- `apps/mobile/test/features/analytics/data/datasources/analyze_patterns_functions_datasource_test.dart`
- `apps/mobile/test/features/garden/domain/pattern_detector_test.dart`
- (Day-4 follow-on) `apps/mobile/test/features/analytics/presentation/widgets/pattern_insight_card_test.dart`

**EDIT (server):**
- `functions/src/index.ts` (export `analyzePatterns`)
- `functions/src/types.ts` (add request/response/insight schemas)
- `functions/src/rateLimit.ts` (parameterise `consumeToken`)

**EDIT (client):**
- `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` (add `isEnabled` + `analyzePatterns`)
- `apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart`
- `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart` (slot card)
- `apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart` (use new helper)
- `apps/mobile/lib/features/analytics/domain/usecases/compute_analytics_state.dart` (use new helper)
- `packages/core/lib/core.dart` (export `date_utils`)

## Reuse cues — do NOT redesign these

- **Validation order template**: `functions/src/analyzeMoodText.ts:79-285` — auth at line 84, rate-limit at line 137. Mirror this ordering exactly.
- **CF test harness boilerplate**: `functions/src/__tests__/analyzeMoodText.test.ts:1-100` — logger spy setup, in-memory Firestore tx mock, `defineSecret` stub. Copy it verbatim and adapt the request/response shapes.
- **Client datasource template**: `apps/mobile/lib/features/mood/data/datasources/ai_analysis_functions_datasource.dart` — transport-only, typed exceptions mapped to `AiAnalysisFailure`. The new datasource is a structural clone; the only material difference is the projection drop of `text` and `mediaRefs`.
- **Day-bucketing helpers**: `compute_garden_state.dart:70` and `compute_analytics_state.dart:89` — extract to `packages/core/lib/src/date_utils.dart` rather than copying a third time.
- **RC consumer**: `featureFlagsProvider` at `apps/mobile/lib/app/providers.dart:72-84` is sync — `ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled` returns a bool directly; no `AsyncValue` unwrap.

## PII fence — read this before any edit

The client datasource projection MUST drop `text` and `mediaRefs`. The unit test asserts the projected map for each entry contains exactly `{ date, moodCode, intensity }` keys. The Zod schema is `.strict()`. The server logger allowlist excludes `history`, `history[].date`, and any insight body. Any of those three doors leaking text is a release blocker.

## Server tests — 10 cases (`functions/src/__tests__/analyzePatterns.test.ts`)

1. **auth missing** — no `request.auth.uid` → throws `HttpsError('unauthenticated')`.
2. **Zod-strict reject** — request includes a `text` field at any nesting → `{ ok: false, code: 'invalid_input' }`.
3. **rate-limit exceeded** — second call within 30s for same uid → `{ ok: false, code: 'rate_limited', retryAfterSec }`.
4. **statistical-only happy path** — Gemini disabled (flag off server-side), 30-day history with strong Monday bias → 1 weekday insight returned, `geminiSkipped: true, geminiSkipReason: 'flag_disabled'`.
5. **Gemini-success enrich** — Gemini returns valid JSON within 5s → 4 insights returned (weekday + streak + trend + gemini).
6. **Gemini-timeout fallthrough** — Gemini call exceeds 5s `AbortController` → statistical insights still returned, log `geminiSkipped: true, geminiSkipReason: 'timeout'`.
7. **Gemini-malformed fallthrough** — Gemini returns invalid JSON or fails Zod re-check → statistical insights still returned, log `geminiSkipped: true, geminiSkipReason: 'parse_error'`.
8. **sample-size floor clamp** — weekday with `n = 5` and `|z| = 3.0` → no weekday insight emitted (floor `n ≥ 10`).
9. **trend insufficient** — 30-day window with `n = 12` distinct days → no trend insight (floor `n ≥ 14`).
10. **PII canary** — 10-case run captured into a `loggerCalls` array; assert no payload contains `'2026-'` (date-prefix leak from `history[].date`), no payload contains the rendered insight body strings, no payload contains `'text'` or `'mediaRefs'` keys.

Coverage target: ≥90% on the new module.

## Detector tests — 10 cases (`apps/mobile/test/features/garden/domain/pattern_detector_test.dart`)

1. **empty entries** — `detectPattern([], now: any)` → `triggered: false, reason: 'none'`.
2. **4 distinct neg days / 7** — does NOT trigger.
3. **5 distinct neg days / 7** — triggers with `reason: '5_of_7_negative'`.
4. **5/7 with duplicates same day** — multiple entries on a single day count as one; 5 distinct days still triggers.
5. **3 consecutive @ i=4/5/4 mixed neg types** — triggers with `reason: '3_consecutive_high_intensity'`.
6. **3 consecutive but day-2 i=3** — does NOT trigger (intensity floor is `≥ 4`).
7. **cooldown 12h ago** — even with currently-qualifying entries, returns `triggered: false, reason: 'cooldown'`.
8. **cooldown 49h ago** — cooldown expired; trigger fires normally.
9. **11 days ago + currently triggering** — `escalated: true`.
10. **11 days ago, not currently triggering** — `escalated: false` (escalation requires both conditions).

## Validation order

Before merging, in order:

1. `cd functions && npm test` — all 10 server cases green, ≥90% coverage on `analyzePatterns.ts`.
2. `cd apps/mobile && flutter test` — datasource projection test green, detector 10-case suite green, existing suite still green.
3. `cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs` — clean run.
4. `dart format --output=none --set-exit-if-changed .` — clean.
5. `flutter analyze` — zero errors.
6. **security-reviewer audit** (PM Day 3) covers: Zod `.strict()` rejects unknown keys; client datasource projection drops `text` + `mediaRefs` (verified by test); rate-limit `consumeToken` order and `{windowMs:30_000, max:1}` opts; `enforceAppCheck: true` set; logs contain only `insightCount`, `geminiSkipped`, `geminiSkipReason`, no PII.
7. Non-author approver merges (Enterprise R3).

## Out of scope on this brief

- The cheer-up banner UI (S5 owns it).
- FCM push for the intervention (S5).
- Hotline 1323 footer (S5; only after the 10-day escalation threshold).
- Persisting insights to `users/{uid}/insights/{id}` (re-computed per request in S4; cache deferred).
- A11y rebalance of `MoodBloomColors` for dark mode (S5 a11y sweep).

## Open questions resolved before kickoff

- **O-1**: `analyzePatterns` ships with `enforceAppCheck: true`; `analyzeMoodText` stays at `false` until S5.
- **O-2**: Copy templates hard-coded at this PR; UX writer reviews post-merge.
- **O-3**: Remote Config `minimumFetchInterval` lowered to 60s for the demo only; restored to 60min in v1.0.1. Documented in `docs/runbooks/feature-flag-rollback.md`.
