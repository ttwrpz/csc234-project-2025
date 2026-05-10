# ADR-0011 — Client-Side Pattern Engine

**Status:** Accepted (Sprint 4)
**Date:** 2026-05-09
**Deciders:** orchestrator + architect
**Supersedes:** ADR-0007 (Pattern Analysis Fallback — Statistical-Primary, Gemini-Supplementary)
**Related:** ADR-0010 (Ecosystem Model), ADR-0003 (Gemini Cloud Function contract — retained for the S5 Quote Library), ADR-0008 (Intervention cooldown persistence — retained), `.claude/specs/sprint-4-5-spec.md` §2.4–§2.6

## Context

ADR-0007 placed pattern analysis behind a Cloud Function (`analyzePatterns`) with a statistical-primary / Gemini-supplementary fallback. That decision served the S3-tail acceptance bar: a single Insights card with a confidence label that survives a Gemini outage. Two things have since changed.

First, the Sprint 4 redesign ratified by ADR-0010 promotes pattern detection from "show ≥1 insight on the demo" to **the trigger source for a three-tier intervention system** (Tier 1 breathing, Tier 2 journaling, Tier 3 crisis resources + Hotline 1323). The professor's S3 feedback — "show real analytics and pattern recognition with math" — wants formula-grade detection, not narrative themes. The spec §2.4 enumerates five algorithms — Mann-Kendall trend test, sliding 5-of-7, 3-consecutive S ≤ -0.6, Z-score anomaly, CUSUM change-point — each chosen to catch a *different* failure mode (gradual worsening, sustained lows, acute crisis, one-off alarming day, sudden sustained shift). No single method covers all five. Together they form a comprehensive net.

Second, every one of those five algorithms reduces to arithmetic over the per-entry mood-score series `{S_t}`. None of them needs Gemini. None of them needs network. None of them needs server-side compute capacity. Running them in a Cloud Function buys nothing — and costs three things:

1. **Latency.** A user logs a heavy entry; the Tier 3 algorithm (3-consecutive S ≤ -0.6) might fire; the dispatcher needs the result *before* the next screen renders. A round-trip to a Cloud Function adds ~300–800 ms in the median, ~2 s on cold start. The user feels it.
2. **PII surface.** ADR-0007's request schema strips `text` and `mediaRefs` from the projection sent to the Cloud Function — but the Cloud Function still has to run, log, and rate-limit on a server, which means logs, function-execution traces, and egress endpoints are *new attack surfaces* for what is essentially a small numerical computation. Keeping the math on-device removes those surfaces entirely.
3. **Availability.** The Pattern Engine is the upstream input to the S5 Tiered Intervention dispatcher. The dispatcher is — by design — a *crisis-adjacent* feature: Tier 3 carries Hotline 1323 signposting. If a regional GCP outage takes the Cloud Function offline, the engine must keep running. A user who has just logged their third consecutive S ≤ -0.6 entry is the single worst person to fail-open against.

The S3-era `analyzeMoodText` Gemini call (ADR-0003) is unaffected by this decision — it lives on a different code path, classifies a single free-text journal entry into a mood type, and ADR-0010 + ADR-0011 leave it intact. ADR-0007's `analyzePatterns` Cloud Function is the one that gets repositioned.

## Decision

### 1. All five algorithms run client-side as pure-Dart functions

The five algorithms enumerated in spec §2.4 each become one file under `apps/mobile/lib/features/pattern_engine/domain/algorithms/`:

```
mann_kendall.dart          — gradual worsening, 14-day window
sliding_5_of_7.dart        — sustained lows
three_consecutive.dart     — acute crisis (3 days S ≤ -0.6)
z_score.dart               — single-day anomaly vs personal 30-day baseline
cusum.dart                 — sudden sustained shift
```

Each is a pure-Dart top-level function with the signature `(List<DailyScore> history, DateTime now) → AlgorithmOutput`. Inputs are numeric only (per-day aggregated mood scores plus a timestamp); outputs are numeric plus an optional `triggeredTier` (`Tier.one | Tier.two | Tier.three | null`). No file under `pattern_engine/domain/` may import `package:flutter/*`, `package:firebase_*/*`, or `package:cloud_firestore/*`. The CI domain-purity grep gate enforces this.

**Why pure-Dart, not platform-specific.** The same five algorithms must run identically on Android and Web (the two platforms in CLAUDE.md scope). Pure-Dart code shares one implementation path, one test suite, and one set of golden numerics across both platforms. There is no native-code shortcut that would justify the platform-fork cost.

**Why per-day aggregation upstream of the algorithms.** Multiple entries on the same calendar day need to be folded to a single `S_day` value before the algorithms see them, otherwise (a) Mann-Kendall would treat a single day with three entries as three trend points (incorrect), and (b) the 5-of-7 / 3-consecutive day-counters would over-count. The aggregation lives one layer above the algorithms in `RunPatternEngineUseCase` (decision §2), so each algorithm operates on a clean `List<DailyScore>` series.

### 2. `RunPatternEngineUseCase` orchestrates the five algorithms and writes one result per day

```dart
@riverpod
class RunPatternEngineUseCase extends _$RunPatternEngineUseCase {
  Future<PatternResult> call(List<MoodEntry> entries, {DateTime? now});
}
```

The use case (a) groups entries by `localMidnight` to produce a `List<DailyScore>`; (b) runs all five algorithms in parallel via `Future.wait` (synchronous arithmetic returns immediately, so this is essentially zero-cost); (c) computes `triggeredTier` as the **highest tier** any algorithm flagged; (d) returns a Freezed `PatternResult` carrying every algorithm's raw output plus the resolved tier; (e) persists the result to `users/{uid}/patterns/{yyyy-MM-dd}` with one document per local-midnight day, idempotent by date id.

```dart
@freezed
class PatternResult with _$PatternResult {
  const factory PatternResult({
    required String dateId,                // yyyy-MM-dd in user-local time
    required double? mannKendallZ,         // null if window < 14 days
    required int slidingNegCount,          // 0..7
    required int consecutiveHighIntensity, // 0..3+
    required double? zScoreToday,          // null if 30-day baseline σ ≈ 0 or n < 14
    required double cusumC,                // ≥ 0
    required Tier? triggeredTier,          // null if no algorithm fired
    required int schemaV,                  // 1
  }) = _PatternResult;
}
```

The doc id `yyyy-MM-dd` makes same-day re-evaluation idempotent: a user logging twice on May 9 produces the same `patterns/2026-05-09` doc, overwritten on the second write with the latest scalar values. Cross-day evaluation produces fresh docs without churn.

### 3. The Cloud Function `analyzePatterns` is repositioned as an *insights surface only*

`functions/src/analyzePatterns.ts` stays deployed. Its role narrows:

- It NO LONGER drives the intervention dispatcher. The Pattern Engine on-device owns that path.
- It is read only by the Insights screen (S5) — the analytics view that shows the user qualitative summaries ("your Tuesdays trend lower than the rest of the week"), with explicit confidence bands and sample-size floors.
- The `ai_pattern_analysis_enabled` Remote Config flag now gates the **Insights card's Gemini themes**, not the intervention path. Disabling the flag still lets the statistical-primary half of `analyzePatterns` ship a card; the intervention dispatcher (S5) reads from `patterns/{date}` and is unaffected.
- The atomic `MoodType.okay` sign flip (ADR-0010 §2) lands in `analyzePatterns.ts` at the same time as the client-side flip: `NEGATIVE_MOOD_CODES` no longer contains `'okay'`. Without this co-edit, the Insights card's weekday z-score and the on-device engine would disagree on which moods count as negative.

### 4. The dispatcher is feature-flagged off in v1.0

The Pattern Engine writes to `patterns/{date}` regardless of any flag. The downstream **dispatcher** — the existing `cheer_up_controller` + `cheer_up_banner` + `sendCheerUpPush` Cloud Function path that currently fires on the OLD 2-rule trigger — is wrapped in a Remote Config flag `interventionDispatchEnabled` (default `false` in v1.0). v1.0 demos the academic-grade engine with logged outputs but no notifications. Sprint 5 re-wires the dispatcher to read `patterns/{date}.triggeredTier`, attaches the Quote Library safety filter and the Bipolar/medical disclaimer footer, and flips the flag to `true` once both have merged.

This split — engine on, dispatcher off — is deliberate. Notifying a vulnerable user with the OLD copy library on a NEW tier classification would be a user-safety regression. The flag holds the door closed for one sprint while S5 builds the right copy + safety machinery.

### 5. Storage shape

| Collection | Path | S4 access | Purpose |
|---|---|---|---|
| `patterns/{date}` | `users/{uid}/patterns/{yyyy-MM-dd}` | client write/read | Pattern Engine output, idempotent by date id. Carries no mood text — PII guard. |
| `interventions/{id}` | `users/{uid}/interventions/{id}` | rule stub (read-only, write deny) | Reserved for S5 dispatcher; collection exists in rules but no client writes accepted in v1.0. |
| `cooldowns/{type}` | `users/{uid}/cooldowns/{tier}` | rule stub (read-only, write deny) | Reserved for S5 per-tier cooldowns. |
| `interventionState/current` | `users/{uid}/interventionState/current` | client write/read | Existing single-doc cooldown anchor (ADR-0008). Retained unchanged in S4; S5 may parallel-write to `cooldowns/{tier}`. |
| `cheerUpEvents/{evtId}` | `users/{uid}/cheerUpEvents/{evtId}` | client write/read | Existing append-only audit log. No S4 changes. |

The pure-Dart `RunPatternEngineUseCase` does **not** import `cloud_firestore` directly — it returns a `PatternResult`; a thin data-layer datasource (`features/pattern_engine/data/datasources/patterns_firestore_datasource.dart`) handles the write. The domain-purity grep gate would otherwise flag the use case.

## Consequences

**Positive.**

- **No latency tax on the trigger path.** Five algorithms over a 30-day window total < 5 ms on a mid-range Android. The dispatcher (S5) sees the result before the next frame paints.
- **No PII surface in the trigger path.** Mood text never leaves the device for pattern detection. The `patterns/{date}` document carries only numeric outputs and the resolved tier. (Insights surface still has the ADR-0003 + ADR-0007 PII guard around `analyzePatterns`'s text-stripping.)
- **No upstream dependency for crisis-adjacent code.** A regional GCP outage cannot prevent the on-device engine from flagging a Tier 3 condition. The `cheerUpEvents` write that S5 will use to fan out the Cloud Function push is the only network step on the dispatch side, and that is non-blocking with respect to the user-visible banner.
- **One implementation, two platforms.** Pure-Dart shares Android + Web. No platform-fork test matrix.
- **Tighter unit-testability.** Every algorithm is a pure function: a 5-line test sets up a `List<DailyScore>` and asserts a numeric output to two decimal places. The Mann-Kendall worked example in spec §2.4 (Z ≈ -2.21 on a steadily declining 14-day window) becomes a single deterministic test case (TC-27). **TC-27 quantization amendment (architect, 2026-05-12):** Mann-Kendall's `S` statistic is integer-valued, so `Z = (S±1) / √V` is quantized. With the spec's `n=14` window, `V = 14·13·33/18 = 333.667` and the closest reachable Z values to -2.21 are -2.190 (S=-41) and -2.2445 (S=-42); neither fits the spec's stated ±0.005 tolerance. The TC-27 test pins both the user-facing condition (Z < -1.96 → Tier 1) on a clearly-declining series AND the closest-achievable Z = -2.190. The spec target is hereby softened to ±0.05; the algorithm's tier-trigger semantics are unchanged. Spec §2.4 + §7.27 will be amended in the next spec revision.

**Negative / trade-offs.**

- **Algorithm changes ship via app update.** A bug in CUSUM cannot be hot-fixed by a Cloud Function redeploy; it requires a Flutter build + store rollout (or a Web reload). Mitigation: every algorithm is unit-tested against worked examples from spec §2.4 before merge; the legacy `pattern_detector.dart` is retained as a regression baseline (`@Deprecated`, `@Tags(['legacy'])`) so a rollback to the 2-rule detector is a Riverpod-override away.
- **Per-user 30-day baseline for Z-score and CUSUM is computed on the client.** A user with < 14 days of history has no baseline, so Z-score returns null and CUSUM stays at zero. This is the correct behaviour (no false Tier 3 on a brand-new user) but means the engine has a "warm-up" period for new accounts. Documented in HB-004.
- **`analyzePatterns` is now a single-purpose surface (Insights card only).** It is borderline-deprecation candidate. Decision: keep it for v1.0 because the Insights card depends on it; reconsider full retirement in v1.x once the Insights screen has a chance to migrate to a client-side aggregator if desired.

**Follow-up work.**

- HB-004 *Pattern Engine handoff* (companion to this ADR) — the `flutter-engineer` brief covering all 5 algorithm signatures, the orchestrating use case, the Freezed `PatternResult`, and the `users/{uid}/patterns/{date}` data shape.
- Sprint 5: Tiered Intervention dispatcher reads `patterns/{date}.triggeredTier`, attaches Quote Library + disclaimer footer, flips `interventionDispatchEnabled` to `true`. New `cooldowns/{tier}` collection writes go live.
- v1.x candidate: retire `analyzePatterns` Cloud Function entirely if the Insights card migrates to a client-side aggregator — would close the last server-side mood-content path.

## Alternatives Considered

- **Keep `analyzePatterns` as the trigger source (ADR-0007 status quo).** Rejected. Latency, PII surface, and availability cost outweigh any centralisation benefit. Crisis-adjacent code must not depend on a Cloud Function.
- **Run only the simple algorithms (5-of-7, 3-consecutive) on-device and keep Mann-Kendall, Z-score, CUSUM in the Cloud Function.** Rejected. Splits the engine across a network boundary, doubles the test matrix, and re-introduces the latency / availability / PII issues for the algorithms most likely to fire Tier 3 (Z-score and CUSUM are the sudden-acute detectors).
- **Persist algorithm outputs to local storage only (Drift), not Firestore.** Rejected. The S5 dispatcher (Cloud Function `sendCheerUpPush`-equivalent) needs to read the result server-side to fan out FCM with the right tier copy and the Bipolar disclaimer footer. Firestore is the right transport for that handoff.
- **Compute on every read (no persistence) and let the dispatcher read live.** Rejected. The dispatcher needs to know "did this user already see a Tier 1 today?" — that's a cooldown question (ADR-0008), and cooldown logic reads the *most recent* persisted result. A read-only ephemeral engine forces every cooldown decision to recompute the entire 30-day window, which is wasteful and deprives auditing of a dated record.
- **Use TFLite / on-device ML.** Rejected. The five algorithms in spec §2.4 are deterministic statistical methods chosen specifically because they are publishable, citable, and human-explainable to a thesis committee. ML adds opacity exactly where the professor's "show real math" feedback wants the opposite.

## Compliance Check

- **Clean Architecture domain-zero-imports rule (ADR-0001):** every algorithm + the orchestrating use case + `PatternResult` live in `features/pattern_engine/domain/` with zero Flutter / Firebase imports. The thin datasource that writes `patterns/{date}` lives in `features/pattern_engine/data/`. CI grep gate enforces.
- **PII rule (CLAUDE.md):** `patterns/{date}` carries no mood text. The `RunPatternEngineUseCase` reads `MoodEntry.intensity` and `MoodEntry.mood` (the type, not the text). Logging never emits the raw text — only algorithm outputs.
- **Enterprise Term Assignment requirements touched:** **R1** (the redesign is traceable to the professor's S3 "show real analytics with math" feedback); **R3** (architecture quality — pure-Dart domain layer preserved under a major redesign); **R5** (correctness — every algorithm's worked example from spec §2.4 is a unit test asserting numerical output to 2 decimal places).
- **Quality gates affected:** Correctness (5 new algorithm test files + the orchestrator test = ~25 new test cases; all 5 worked examples from spec §2.4 must pass), Performance (engine completes in < 5 ms on mid-range Android — well inside frame budget), Security (no Cloud Function read of mood content for the trigger path; `patterns/{date}` rule denies any client field outside the schemaV-1 allowlist).
- **Citations:**
  - Mann-Kendall trend test: Mann (1945), *Econometrica* 13, 245–259; Kendall (1975), *Rank Correlation Methods*, Griffin.
  - CUSUM: Page (1954), *Biometrika* 41, 100–115.
  - PHQ-9 anchor for "5 of last 7 days" (sliding 5-of-7): Kroenke, Spitzer & Williams (2001), *J Gen Intern Med* 16, 606–613.
  - Just-In-Time Adaptive Interventions (frame for tier dispatch in S5): Nahum-Shani et al. (2018), *Annals of Behavioral Medicine* 52(6), 446–462.
  - Digital psychiatry — on-device computation as ethical default: Torous et al. (2019), *World Psychiatry* 18(3).
