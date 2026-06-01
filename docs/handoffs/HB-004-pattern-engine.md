# Handoff Brief - Pattern Engine (5 algorithms + orchestrator)

**WBS:** 5.3
**Sprint:** S4 (Day 2 May 10 → Day 3 May 11)
**Target branch:** `feat/5.3-pattern-engine`
**Depends on:** WBS 3.6 (Mood Score `MoodScore.compute`), `MoodEntry` entity (S2), `localMidnight` helper in `packages/core/lib/src/date_utils.dart` (S3), `Result<T,F>` in `packages/core/lib/src/result.dart` (S2)
**Authority:** ADR-0011 (Client-Side Pattern Engine) + `.claude/specs/sprint-4-5-spec.md` §2.4 + ADR-0010 (Ecosystem Model - for sign mapping)

## Summary

Sprint 4 lands the engine that watches a user's mood history for five different signs of distress and emits a single `PatternResult` per local-midnight day. The engine **does not surface notifications in v1.0** - that's S5. The result document lives at `users/{uid}/patterns/{yyyy-MM-dd}` with one doc per day, idempotent on the date id. The S5 dispatcher will read this document and decide whether to fan out a Tier 1 / 2 / 3 push; in v1.0 the engine simply writes and is silent.

The five algorithms (Mann-Kendall trend test, sliding 5-of-7, 3-consecutive S ≤ -0.6, Z-score anomaly, CUSUM change-point) all reduce to arithmetic over the per-day signed mood-score series `{S_day}`. They run client-side as pure-Dart functions. No Cloud Function is involved on the trigger path; `functions/src/analyzePatterns.ts` continues to ship the Insights surface only.

## Domain shape

### NEW - `MoodScore` (depends on WBS 3.6, may already exist when you start this brief)

`apps/mobile/lib/features/mood/domain/services/mood_score.dart`. Pure-Dart top-level function and Freezed value type. Authored on Day 1 alongside the `MoodType.okay` sign flip; you can rely on it.

```dart
@freezed
class MoodScore with _$MoodScore {
  const factory MoodScore({
    required double value,    // signed score in [-1, +1]
    required int sign,        // -1 or +1
    required int intensity,   // 1..5
  }) = _MoodScore;
}

MoodScore computeMoodScore(MoodType mood, int intensity);
//   value = sign × (intensity / 5)
//   sign  = mood.category == MoodCategory.positive ? +1 : -1
```

### NEW - `DailyScore` (small, public)

`apps/mobile/lib/features/pattern_engine/domain/entities/daily_score.dart`. The unit each algorithm consumes.

```dart
@freezed
class DailyScore with _$DailyScore {
  const factory DailyScore({
    required DateTime day,    // localMidnight(...)
    required double avgScore, // mean of MoodScore.value across the day's entries
    required int entryCount,  // for diagnostics; not used by algorithms
  }) = _DailyScore;
}
```

### NEW - `Tier`

`apps/mobile/lib/features/pattern_engine/domain/entities/tier.dart`. Closed enum.

```dart
enum Tier { one, two, three }
```

The mapping algorithm-output → tier is:

| Algorithm | Trigger condition | Tier |
|---|---|---|
| Mann-Kendall | `Z_trend < -1.96` | one |
| Sliding 5-of-7 | `negDays ≥ 5` | two |
| 3-consecutive | `S_{t-2} ≤ -0.6 ∧ S_{t-1} ≤ -0.6 ∧ S_t ≤ -0.6` | three |
| Z-score | `z_day < -2.5` | three |
| CUSUM | `C_t > h` (where `h = 4·σ_30`) | three |

When multiple algorithms fire the same day, the **highest tier** wins (three > two > one). When none fire, `triggeredTier` is null.

### NEW - `PatternResult`

`apps/mobile/lib/features/pattern_engine/domain/entities/pattern_result.dart`. Freezed + json_serializable (used by the data layer's Firestore mapper).

```dart
@freezed
class PatternResult with _$PatternResult {
  const factory PatternResult({
    required String dateId,                  // yyyy-MM-dd in user-local time
    required double? mannKendallZ,           // null when window n < 14 days
    required int slidingNegCount,            // 0..7
    required int consecutiveHighIntensity,   // 0..3+
    required double? zScoreToday,            // null when σ_30 ≈ 0 OR n_baseline < 14
    required double cusumC,                  // ≥ 0
    required Tier? triggeredTier,            // null = no trigger
    @Default(1) int schemaV,
  }) = _PatternResult;

  factory PatternResult.fromJson(Map<String, Object?> json) =>
      _$PatternResultFromJson(json);
}
```

### NEW - Five algorithm functions (one file each)

`apps/mobile/lib/features/pattern_engine/domain/algorithms/`. Each is a pure-Dart top-level function with **no class wrapper**. Each must compile with zero Flutter / Firebase imports. Tests (under `test/features/pattern_engine/domain/algorithms/...`) target every worked example in spec §2.4.

#### 1. `mann_kendall.dart`

```dart
/// Returns the Z statistic of the Mann-Kendall trend test over the last
/// `windowDays` (default 14). Returns `null` when `history.length < 14`.
///
/// Z < -1.96 → Tier 1.
/// Z > +1.96 → encouragement (no alert).
double? mannKendallZ(List<DailyScore> history, {int windowDays = 14});
```

Algorithm (spec §2.4 algorithm 1):
1. Take the last `windowDays` daily scores chronologically; require `n ≥ 14`.
2. `S = Σ_{i<j} sign(x_j - x_i)`.
3. `V = n(n-1)(2n+5) / 18`.
4. `Z = (S - 1)/√V` if `S > 0`; `0` if `S = 0`; `(S + 1)/√V` if `S < 0`.

**TC-27 worked example:** a steadily declining 5-day window does NOT have enough samples (n < 14) - the test that asserts Z = -2.21 in spec §7.27 must construct a 14-day series with the declining pattern at the tail. Use the same numerics as spec §2.4 (a fully monotone descending series) and assert Z to 2 decimal places.

#### 2. `sliding_5_of_7.dart`

```dart
/// Counts distinct local-midnight days in the last 7-day window where
/// `avgScore < 0`. `now` anchors "today".
int slidingNegCount(List<DailyScore> history, {required DateTime now});
```

Spec §2.4 algorithm 2: `negDays = count(S_t < 0 in last 7 days); negDays ≥ 5 → Tier 2`. Empty days are counted as 0 (no entry), not as negative - only days with at least one entry contribute. Distinct local-midnight days per `localMidnight(now)`.

#### 3. `three_consecutive.dart`

```dart
/// Returns the count of trailing consecutive days (ending today) where
/// `avgScore ≤ -0.6`. Maxes at 3 - caller compares against >= 3.
int consecutiveHighIntensityCount(
  List<DailyScore> history, {
  required DateTime now,
});
```

Spec §2.4 algorithm 3: `S_{t-2} ≤ -0.6 ∧ S_{t-1} ≤ -0.6 ∧ S_t ≤ -0.6 → Tier 3`. A missing day in the trailing 3-day window breaks the streak (returns 0, 1, or 2). Today's score is counted if today exists in `history`; otherwise 0.

#### 4. `z_score.dart`

```dart
/// Returns the z-score of today's score against the user's personal 30-day
/// baseline. Returns `null` when `n_baseline < 14` OR `σ_30 ≈ 0` (per spec
/// §2.4 algorithm 4 - division-by-zero guard).
double? zScoreToday(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
});
```

Spec §2.4 algorithm 4: `z_day = (S_t - μ_30) / σ_30; z_day < -2.5 → Tier 3`. **Important:** this is **not** the same as Mann-Kendall's Z. They share a letter; the comments in your file must call this out (it's the most common reading error in the spec). Baseline is the 30 days *prior to today* - exclude today's score from μ and σ.

#### 5. `cusum.dart`

```dart
/// Returns the current CUSUM statistic C_t after folding `history`
/// through the recursion. Returns 0.0 when baseline is too small.
double cusumC(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
});
```

Spec §2.4 algorithm 5:
- `μ_30 = mean(last 30 days excluding today)`
- `σ_30 = stddev(last 30 days excluding today)`
- `k = 0.5 × σ_30` (slack)
- `h = 4 × σ_30` (threshold)
- `C_t = max(0, C_{t-1} + (μ_30 - k) - S_t)`
- `C_0 = 0` at the start of the user's history

Trigger: `C_t > h → Tier 3`. The function returns `C_t`; the orchestrator (below) compares against `h`. Baseline rules same as Z-score: `n_baseline < 14` returns 0.0 and never triggers.

### NEW - `RunPatternEngineUseCase`

`apps/mobile/lib/features/pattern_engine/domain/usecases/run_pattern_engine.dart`. The orchestrator.

```dart
class RunPatternEngineUseCase {
  const RunPatternEngineUseCase();

  PatternResult call(
    List<MoodEntry> entries, {
    required DateTime now,
  });
}

@riverpod
RunPatternEngineUseCase runPatternEngineUseCase(RunPatternEngineUseCaseRef ref) =>
    const RunPatternEngineUseCase();
```

Internal flow:

1. **Aggregate.** Bucket `entries` by `localMidnight(entry.createdAt)`; for each bucket, compute `avgScore = mean(MoodScore.compute(e.mood, e.intensity).value)`. Sort the resulting `List<DailyScore>` ascending by `day`. This is the input to every algorithm.
2. **Run all five algorithms** synchronously (they are pure arithmetic; `Future.wait` would be unnecessary ceremony).
3. **Resolve `triggeredTier`** as the highest tier any algorithm flagged - three > two > one > null.
4. **Build `dateId`** from `localMidnight(now)` formatted as `yyyy-MM-dd`.
5. **Return `PatternResult`** carrying every algorithm's output plus the resolved tier.

**Important:** the use case does NOT write to Firestore. The data-layer datasource (below) handles the write. Domain stays pure.

Pure-Dart invariants (qa-engineer test targets - TC-25..TC-30 from spec §7):

- TC-25: 5 of last 7 days `avgScore < 0` → `triggeredTier == Tier.two` (when no higher-tier algorithm fires).
- TC-26: 3 consecutive `avgScore ≤ -0.6` → `triggeredTier == Tier.three`.
- TC-27: 14-day declining series with the spec §2.4 pattern at the tail → `mannKendallZ == -2.21` to 2 d.p. → `triggeredTier == Tier.one` (when no higher fires).
- TC-28: μ_30=+0.3, σ_30 reasonable, today's score = -0.9 → `zScoreToday` < -2.5 → `triggeredTier == Tier.three`.
- TC-29: a sustained drop produces `cusumC > 4·σ_30` → `triggeredTier == Tier.three`.
- TC-30: cross-week boundary → 7-day and 14-day windows do NOT reset on a Weekly Harvest archival (the engine reads from the flat `users/{uid}/moods/` collection, never from `weeklyGardens/{weekId}`).

### Reused (no changes)

- `apps/mobile/lib/features/mood/domain/entities/mood_entry.dart` - `MoodEntry` (id, mood, intensity, text, createdAt, ...).
- `apps/mobile/lib/features/mood/domain/entities/mood_type.dart` - six-value enum + `MoodCategory` (after the Day-1 `okay → positive` flip).
- `apps/mobile/lib/features/mood/domain/services/mood_score.dart` - `computeMoodScore`, `MoodScore`. Authored Day 1.
- `packages/core/lib/src/date_utils.dart` - `DateTime localMidnight(DateTime dt)`.

## Data shape

### NEW - `PatternsFirestoreDatasource`

`apps/mobile/lib/features/pattern_engine/data/datasources/patterns_firestore_datasource.dart`.

```dart
class PatternsFirestoreDatasource {
  const PatternsFirestoreDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> upsertPatternResult({
    required String userId,
    required PatternResult result,
  });

  Stream<PatternResult?> watchPatternResult({
    required String userId,
    required String dateId,
  });
}
```

`upsertPatternResult` writes to `users/{userId}/patterns/{result.dateId}` via `set(merge: false)` - same-day re-evaluations replace the doc cleanly. `watchPatternResult` streams a single document for the dispatcher (S5 read path).

### NEW - `PatternRepositoryImpl`

`apps/mobile/lib/features/pattern_engine/data/repositories/pattern_repository_impl.dart` implementing the abstract `PatternRepository` (next file). Wires the datasource + provider scaffolding (`@riverpod patternRepository`).

### NEW - abstract `PatternRepository`

`apps/mobile/lib/features/pattern_engine/domain/repositories/pattern_repository.dart`. Domain layer; no Flutter / Firebase imports.

```dart
abstract class PatternRepository {
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  });

  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  });
}
```

### Sealed failure type

`apps/mobile/lib/features/pattern_engine/domain/pattern_failure.dart`. Match the existing `MoodFailure` shape - Freezed with cases `unknown(String message)`, `network()`, `permissionDenied()`. Keep narrow; v1.0 only needs surface for "the write failed and the next render should not assume it succeeded."

### Firestore rules

`firebase/firestore.rules` - append (the architect lands the rules edit on the same Sprint-4 redesign branch; flutter-engineer should NOT edit `firestore.rules` directly):

```
match /users/{uid}/patterns/{dateId} {
  allow read: if isOwner(uid);

  allow create, update: if isOwner(uid)
    && dateId.matches('^\\d{4}-\\d{2}-\\d{2}$')
    && request.resource.data.dateId == dateId
    && request.resource.data.schemaV == 1
    && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['dateId','mannKendallZ','slidingNegCount',
                 'consecutiveHighIntensity','zScoreToday',
                 'cusumC','triggeredTier','schemaV'])
    && (request.resource.data.triggeredTier == null
        || request.resource.data.triggeredTier in ['one','two','three']);

  allow delete: if false;
}
```

Mood text is **not** in the schema. The `affectedKeys().hasOnly(...)` allowlist enforces it.

### Drift / offline-first

The Pattern Engine **does NOT use Drift in v1.0.** Reasons: (a) the engine is read from `MoodEntry` which is already offline-first via Drift; (b) `PatternResult` is recomputed cheaply on demand; (c) S5 dispatcher reads from Firestore via stream, not from a local cache. If a future sprint surfaces a "pattern history viewer" we'll add a Drift table then.

## Presentation shape

**Sprint 4 has no presentation layer for the Pattern Engine.** The engine is invoked from the mood-save controller (existing `LogMoodSubmissionController` or its descendant) right after a successful save:

```dart
// in apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_controller.dart
// (or a sibling controller - flutter-engineer's call which file)
//
// after save() returns Ok:
final entries = await ref.read(myMoodHistoryProvider.future);
final result = ref.read(runPatternEngineUseCaseProvider)(
  entries,
  now: DateTime.now(),
);
await ref.read(patternRepositoryProvider).save(
  userId: user.uid,
  result: result,
);
// don't surface anything: dispatch is gated until S5 (interventionDispatchEnabled = false)
```

The save path is **best-effort.** A failed `patternRepositoryProvider.save` is logged via `packages/core/lib/src/logger.dart` (no PII - log only the failure type and the dateId) but does NOT block the user's mood-save success. Treat the engine as a passive watcher in v1.0.

`cheer_up_controller` continues to exist in v1.0 but its dispatch path is gated behind a Remote Config flag `interventionDispatchEnabled` (default `false`). The architect adds the flag to `firebase_remote_config_defaults` and wires the gate in `cheer_up_controller.dart`. Flutter-engineer SHOULD not modify `cheer_up_controller.dart` in this brief - that work is on the same branch but a separate commit owned by the architect.

## Handoffs

### → flutter-engineer

Create files in this order. Each compiles standalone except where a Freezed/Riverpod codegen file is required, which runs at the end.

1. `apps/mobile/lib/features/pattern_engine/domain/entities/tier.dart`
2. `apps/mobile/lib/features/pattern_engine/domain/entities/daily_score.dart`
3. `apps/mobile/lib/features/pattern_engine/domain/entities/pattern_result.dart`
4. `apps/mobile/lib/features/pattern_engine/domain/pattern_failure.dart`
5. `apps/mobile/lib/features/pattern_engine/domain/algorithms/mann_kendall.dart`
6. `apps/mobile/lib/features/pattern_engine/domain/algorithms/sliding_5_of_7.dart`
7. `apps/mobile/lib/features/pattern_engine/domain/algorithms/three_consecutive.dart`
8. `apps/mobile/lib/features/pattern_engine/domain/algorithms/z_score.dart`
9. `apps/mobile/lib/features/pattern_engine/domain/algorithms/cusum.dart`
10. `apps/mobile/lib/features/pattern_engine/domain/repositories/pattern_repository.dart`
11. `apps/mobile/lib/features/pattern_engine/domain/usecases/run_pattern_engine.dart`
12. `apps/mobile/lib/features/pattern_engine/data/datasources/patterns_firestore_datasource.dart`
13. `apps/mobile/lib/features/pattern_engine/data/repositories/pattern_repository_impl.dart`
14. Move `apps/mobile/lib/features/garden/domain/pattern_detector.dart` → `apps/mobile/lib/features/pattern_engine/domain/legacy_pattern_detector.dart`. Add `@Deprecated('Replaced by RunPatternEngineUseCase. See ADR-0011.')` to the `detectPattern` function. Update imports in `cheer_up_controller.dart` and the existing test file. The legacy test file `apps/mobile/test/features/garden/domain/pattern_detector_test.dart` moves to `apps/mobile/test/features/pattern_engine/domain/legacy_pattern_detector_test.dart` and gains a `@Tags(['legacy'])` annotation at the top.
15. Wire the engine into the post-save path of `log_mood_submission_controller.dart` (a 6–8 line addition; use `ref.read` not `ref.watch` for one-shot invocation).
16. Run `flutter pub run build_runner build --delete-conflicting-outputs`.

Conventions (from CLAUDE.md, repeated for clarity):
- 100-char line length.
- `dart format` on save (CI hard-fails).
- snake_case filenames; PascalCase classes; camelCase members; private members prefixed `_`.
- No `print()`; use the `Logger` from `packages/core/`. Never log mood text or `MoodEntry` instances - only ids + numeric fields + failure types.
- No `!` null-assertion. Use `if-null` operators or explicit null checks.
- Domain files import zero `package:flutter/*`, `package:firebase_*/*`, or `package:cloud_firestore/*`. CI grep gate enforces.
- `Result<T, Failure>` from `packages/core/` for all repository signatures. No throwing from domain.

**Do not touch:**

- `apps/mobile/lib/features/auth/**`, `apps/mobile/lib/features/onboarding/**`, `apps/mobile/lib/features/mood/data/**`, `apps/mobile/lib/features/mood/domain/entities/**` (frozen).
- `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` - architect adds the Remote Config gate on the same branch but in a separate commit.
- `apps/mobile/lib/main.dart`, `apps/mobile/lib/app/router.dart` - architect sign-off required.
- `firebase/firestore.rules` - architect lands the new collection rules on the same branch.
- `functions/**` - architect (or `flutter-engineer` with security-reviewer sign-off) handles `analyzePatterns.ts` `NEGATIVE_MOOD_CODES` edit on Day 1; this brief assumes it has already merged.

### → qa-engineer (Day 3)

Unit tests (write alongside the implementation, same PR):

- `apps/mobile/test/features/pattern_engine/domain/algorithms/mann_kendall_test.dart` - TC-27 (Z = -2.21 to 2 d.p.) + 3 boundary cases: (a) n < 14 → null, (b) flat series → 0, (c) ascending series → positive Z (no Tier).
- `apps/mobile/test/features/pattern_engine/domain/algorithms/sliding_5_of_7_test.dart` - TC-25 (5 negative days → triggers) + 3 cases: (a) 4 negative + 3 empty days → no trigger, (b) 7 consecutive negatives → triggers, (c) all positive → 0.
- `apps/mobile/test/features/pattern_engine/domain/algorithms/three_consecutive_test.dart` - TC-26 + 3 cases: (a) S = -0.6 exactly → triggers (boundary), (b) one missing day in the trailing 3 → 0, (c) entries from yesterday + today + day before → counts up to 3.
- `apps/mobile/test/features/pattern_engine/domain/algorithms/z_score_test.dart` - TC-28 + 3 cases: (a) σ_30 ≈ 0 → null, (b) baseline < 14 days → null, (c) z_day = -2.49 → null trigger but value populated, (d) z_day = -2.51 → Tier.three.
- `apps/mobile/test/features/pattern_engine/domain/algorithms/cusum_test.dart` - TC-29 + 3 cases: (a) flat baseline series → C_t = 0, (b) one positive spike → C_t resets via the `max(0, ...)` guard, (c) sustained drop accumulates → crosses h.
- `apps/mobile/test/features/pattern_engine/domain/usecases/run_pattern_engine_test.dart` - TC-30 (week-boundary independence) + 5 cases: (a) tier resolution (multiple algorithms fire → highest wins), (b) empty history → all-null result, (c) entries on the same day aggregate to one `DailyScore`, (d) `dateId` formats correctly across midnight, (e) repository is called with the right userId on save (use a fake `PatternRepository`).

Test conventions: pin time-dependent inputs with `final now = DateTime(2026, 5, 9, 10, 30)`; build entries with a `_entry()` helper at the file top (mirror `apps/mobile/test/features/garden/domain/pattern_detector_test.dart` lines 6–19 for the pattern). Use `expectLater(... closeTo(expected, 0.005))` for floating-point assertions to tolerate < 5e-3 numeric drift.

Coverage target: every algorithm file ≥ 90% line coverage. Orchestrator file ≥ 85%. CI does not enforce a threshold, but the coverage comment posts to the PR (see `.github/workflows/ci.yml:181-201`); architect reviews before approving.

### → security-reviewer (Day 5 audit)

Audit checklist:

- [ ] **R-301 No mood text in `patterns/{date}`.** Read `patterns_firestore_datasource.dart` and confirm the upsert payload contains only the 8 fields in the rule allowlist. Spot-check Firestore emulator: write a `PatternResult` and verify `text`, `mediaRefs`, or any free-form string field is absent.
- [ ] **R-302 No Gemini call on the trigger path.** Grep the new files for `analyzeMoodText`, `analyzePatterns`, `gemini`, `generateContent`. None should match. The Gemini surface is only `analyzeMoodText` (S3, single-entry classifier) and `analyzePatterns` (S5 Insights), and neither is reachable from `RunPatternEngineUseCase`.
- [ ] **R-303 Domain purity.** `apps/mobile/lib/features/pattern_engine/domain/**/*.dart` imports zero `package:flutter/*`, `package:firebase_*/*`, `package:cloud_firestore/*`. CI grep gate enforces; manual re-check on the diff.
- [ ] **R-304 Firestore rule allowlist.** Confirm the new `patterns/{dateId}` rule rejects writes carrying `text`, `mood`, `intensity`, or any other off-allowlist key (rules emulator test).
- [ ] **R-305 Cooldown / dispatcher gating.** Confirm `interventionDispatchEnabled` defaults to `false` in `firebase_remote_config_defaults` and the existing `cheer_up_controller` early-returns when the flag is false.
- [ ] **R-306 No PII in logs.** Pattern engine save-failure logging emits only `dateId`, `triggeredTier`, and the failure type. No `userId` (it identifies the user) and no entry text.

### → architect (parallel work on same branch, separate commits)

- Add `interventionDispatchEnabled: false` to `firebase_remote_config_defaults` and wrap the dispatch path in `cheer_up_controller.dart`.
- Update `firestore.rules` with the `patterns/{dateId}` rule plus the S5 stub denials for `interventions/{id}` and `cooldowns/{type}`.
- Land `MoodType.okay → positive` flip in `mood_type.dart` and `analyzePatterns.ts` `NEGATIVE_MOOD_CODES` (Day 1).

## Acceptance Criteria

The Pattern Engine landing is complete when:

- [ ] `flutter test apps/mobile/test/features/pattern_engine/` passes - all 25+ algorithm cases + orchestrator cases.
- [ ] `flutter analyze` and `dart format --set-exit-if-changed` are clean on the branch.
- [ ] CI domain-purity grep returns nothing under `apps/mobile/lib/features/pattern_engine/domain/`.
- [ ] Logging a mood writes a `users/{uid}/patterns/{yyyy-MM-dd}` document; the doc contains the 8 allowlisted fields and no others (verify via Firestore emulator).
- [ ] No banner or push notification fires from the engine in v1.0 (`interventionDispatchEnabled` is false; dispatcher early-returns).
- [ ] All 6 spec test cases (TC-25..TC-30) are present as named tests under `test/features/pattern_engine/`.
- [ ] Legacy `pattern_detector_test.dart` still passes under its `@Tags(['legacy'])` annotation; no production code references the legacy detector except via the `@Deprecated` re-export.
- [ ] Mann-Kendall TC-27 asserts `Z = -2.21` to 2 decimal places.
- [ ] Security-reviewer R-301..R-306 are signed off.

## Open Questions for orchestrator

1. **Empty days in sliding 5-of-7.** Spec §2.4 algorithm 2 says "5 of last 7 days." A user who logs 4 negative days and 3 empty days within a 7-day window - does the empty day count as not-negative (= 0 contribution) or as missing data (= excluded from denominator)? **Architect default:** empty day = 0 contribution; algorithm reads `count(S_t < 0 in last 7 calendar days)`, NOT `fraction of logged days that were negative`. Rationale: PHQ-9's "more than half the days" is calendar-day-based, not log-frequency-based. Confirm before merge.
2. **CUSUM C_0 across user's history.** A user with 200 days of history - do we fold from day 1 every time, or carry `C_t` forward in the persisted `PatternResult`? **Architect default:** fold from day 1 every time. CUSUM is small (one float), the history is bounded (Firestore page limit + Drift cache), and the recompute is < 1 ms even at 1000 days. Avoiding persisted state simplifies the data model. Confirm before merge.
3. **Tier resolution when multiple algorithms fire.** When 3-consecutive (Tier 3) AND Mann-Kendall (Tier 1) both fire on the same day, the result carries `triggeredTier: three`. **But** the persisted `PatternResult` still records the Mann-Kendall Z value (not nulled out). The S5 dispatcher reads `triggeredTier` for the notification choice and the raw fields for the analytics card. Confirmed; this is documented behaviour, not a question - included for the qa-engineer's awareness.
4. **`zScoreToday` epsilon.** Spec §2.4 algorithm 4 doesn't specify the σ ≈ 0 guard. **Architect default:** `σ_epsilon = 1e-9`; below this the function returns null. Worth surfacing in the PR description.
