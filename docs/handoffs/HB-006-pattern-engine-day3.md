# Handoff Brief — Pattern Engine Day 3 (algos 3–5 + orchestrator + data layer + dispatcher gate)

**WBS:** 5.3 (continued from HB-004 / Day-2 Track B)
**Sprint:** S4 (Day 3, May 11)
**Target branch:** `feat/s4-redesign-foundation`
**Depends on:** Day-2 Track B (Tier, DailyScore, PatternResult, PatternFailure, abstract PatternRepository, mann_kendall.dart, sliding_5_of_7.dart). Verify by checking `apps/mobile/lib/features/pattern_engine/domain/algorithms/` contains exactly two files before starting Day 3.
**Authority:** ADR-0011 §1–§5; HB-004 sections "Five algorithm functions" 3–5, "RunPatternEngineUseCase", "Data shape"; spec `.claude/specs/sprint-4-5-spec.md` §2.4 algorithms 3–5

## Summary

Day 3 closes the Pattern Engine. Three remaining algorithms (3-consecutive, Z-score, CUSUM), the orchestrating use case that runs all 5 + writes `users/{uid}/patterns/{date}`, the data-layer datasource + repository impl, the Firestore rule for the new collection, the Remote Config flag that gates the legacy cheer-up dispatcher (so v1.0 ships engine-on-dispatcher-off), and the post-save call site that runs the engine after every mood log.

Three sub-tracks, each a separate commit on the same branch. Sub-tracks B and C can run in parallel after sub-track A finishes; A produces the orchestrator that B's wire-up needs. The architect handles sub-track D (rules + Remote Config defaults) in a fourth commit on the same branch.

---

## Sub-track A — Algorithms 3–5 + RunPatternEngineUseCase + PatternRepositoryImpl

### Algorithm 3: `three_consecutive.dart`

`apps/mobile/lib/features/pattern_engine/domain/algorithms/three_consecutive.dart`. Pure-Dart top-level function.

```dart
/// Returns the count of trailing consecutive days (ending today) where
/// `avgScore <= -0.6`. Maxes at 3 — caller compares against `>= 3` for
/// Tier 3. A missing day in the trailing 3-day window breaks the streak
/// (returns 0, 1, or 2). Today's score is counted only if today exists
/// in `history`; otherwise 0. See HB-004 algorithm 3 + spec §2.4.
int consecutiveHighIntensityCount(
  List<DailyScore> history, {
  required DateTime now,
});
```

Algorithm:
1. Compute `today = localMidnight(now)`.
2. Build a `Map<DateTime, double>` from `history` keyed on each `DailyScore.day` (already at local midnight per the entity contract).
3. For `i = 0`; if `map[today.subtract(Duration(days: i))] <= -0.6`, increment count and increment `i`. Stop on the first miss (no entry that day) OR `avgScore > -0.6`. Cap at 3 (no need to walk back further).
4. Return count.

Tests at `apps/mobile/test/features/pattern_engine/domain/algorithms/three_consecutive_test.dart`:
- TC-26: 3 consecutive days each with `avgScore = -0.6` (boundary inclusive) → returns 3.
- 3 consecutive days each with `avgScore = -0.7` → returns 3.
- 3 consecutive days, middle day at `avgScore = -0.5` → returns 1 (today is heavy, breaks at yesterday).
- 3 consecutive days but yesterday is missing → returns 1.
- Empty history → 0.
- Today not in history → 0.
- 4 consecutive heavy days → returns 3 (caps).
- `avgScore = -0.6` exactly today, yesterday `avgScore = -0.6`, day before `avgScore = -0.59` → returns 2.

### Algorithm 4: `z_score.dart`

`apps/mobile/lib/features/pattern_engine/domain/algorithms/z_score.dart`.

```dart
/// Returns the z-score of today's average mood score against the user's
/// personal 30-day baseline (excluding today). Returns `null` when the
/// baseline has fewer than 14 distinct day-entries OR when the baseline
/// standard deviation is below `sigmaEpsilon` (division-by-zero guard).
///
/// Caller compares the result against `< -2.5` for Tier 3 (and against
/// `|z| > 2` for the looser "extreme" flag — not used as a tier trigger
/// but logged on PatternResult).
///
/// Note: this Z is NOT the same as Mann-Kendall's Z. Same letter,
/// different statistic; see HB-004 algorithm 4.
double? zScoreToday(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
});
```

Algorithm:
1. Compute `today = localMidnight(now)`.
2. Find today's entry: `final todayScore = history.firstWhere((s) => s.day == today, orElse: () => null)`. If null, return null (no signal today).
3. Build the baseline: `history.where((s) => s.day != today && today.difference(s.day) <= Duration(days: baselineDays))`.
4. If `baseline.length < 14`, return null (warm-up period).
5. Compute `mu = mean(baseline.map((s) => s.avgScore))`.
6. Compute `sigma = sqrt(mean(baseline.map((s) => pow(s.avgScore - mu, 2))))` (population stddev — sample stddev with `n-1` divisor is acceptable too; document the choice in the function docstring; population is closer to the spec's framing). Use `n` divisor.
7. If `sigma < sigmaEpsilon`, return null.
8. Return `(todayScore.avgScore - mu) / sigma`.

Tests at `apps/mobile/test/features/pattern_engine/domain/algorithms/z_score_test.dart`:
- TC-28 worked example: baseline mean +0.3, today's score -0.9, with a constructed baseline whose σ produces `z_day < -2.5`. Construction: 14 days at avgScore = +0.3 (μ=0.3, σ=0). σ=0 returns null — bad construction. Better: 14 days = `[0.5, 0.4, 0.3, 0.2, 0.1, 0.4, 0.3, 0.2, 0.5, 0.3, 0.3, 0.3, 0.2, 0.4]` → μ ≈ +0.314, σ ≈ 0.115. Today = -0.9 → `z = (-0.9 - 0.314) / 0.115 ≈ -10.56`. Run the implementation to verify the exact Z and adjust the baseline series until `z < -2.5` clearly. Document the chosen series in the test as an inline comment.
- σ ≈ 0 (15 identical baseline days) → null.
- baseline.length = 13 → null.
- `today` not in history → null.
- Today's score = baseline mean → z = 0.
- `z = -2.49` (just under threshold) → caller would NOT trigger Tier 3 (the function returns the value; assertion is on the value).
- `z = -2.51` → caller WOULD trigger Tier 3.

### Algorithm 5: `cusum.dart`

`apps/mobile/lib/features/pattern_engine/domain/algorithms/cusum.dart`.

```dart
/// Returns the current CUSUM statistic C_t after folding `history`
/// chronologically through the recursion:
///   C_t = max(0, C_{t-1} + (μ_30 − k) − S_t)
///   k = 0.5 × σ_30  (slack)
///   h = 4 × σ_30   (threshold; caller compares against this)
/// Returns 0.0 when baseline has fewer than 14 distinct days OR when
/// baseline σ ≈ 0. C_0 = 0 at the start of `history`.
double cusumC(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
});
```

Algorithm:
1. Compute `today = localMidnight(now)`.
2. Build the baseline as in Z-score: 30 days excluding today; require length ≥ 14; require σ ≥ sigmaEpsilon. If either guard fails, return 0.0.
3. Compute `mu`, `sigma`, then `k = 0.5 × sigma`.
4. Sort `history` ascending by day.
5. Initialise `c = 0.0`.
6. Walk `history` chronologically: for each day's entry (including today), update `c = max(0.0, c + (mu - k) - entry.avgScore)`.
7. Return the final `c`.

**HB-004 open question 2 closed**: the orchestrator does NOT carry `c` across days; it folds from the start of `history` every time. Acceptable because `history.length` is bounded by Drift cache + Firestore page limits, and the recompute is < 1 ms even at 1000 days. No persisted CUSUM state.

Tests at `apps/mobile/test/features/pattern_engine/domain/algorithms/cusum_test.dart`:
- Baseline shorter than 14 days → C = 0.
- σ ≈ 0 (constant baseline) → C = 0.
- Flat series matching baseline → C ≈ 0 throughout.
- One positive spike near the start, then flat → C resets via `max(0, ...)` and stays low.
- Sustained drop: 30 baseline days at avgScore ≈ 0.3, then 5 days at -0.5 → C accumulates; assert `C > 0`. Construct a series where C clearly exceeds `h = 4 × σ` to mirror TC-29. Document the chosen series.
- Empty history → 0.

### Orchestrator: `RunPatternEngineUseCase`

`apps/mobile/lib/features/pattern_engine/domain/usecases/run_pattern_engine.dart`.

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

Internal flow per HB-004 §"RunPatternEngineUseCase":

1. **Aggregate** `entries` by `localMidnight(entry.createdAt)` → `Map<DateTime, List<MoodScore>>` using `computeMoodScore`.
2. Build `dailyScores: List<DailyScore>` ascending by day. Each `DailyScore.day = localMidnight(...)`, `avgScore = mean of scores`, `entryCount = entries.length`.
3. Run all 5 algorithms over `dailyScores`:
   - `final mkZ = mannKendallZ(dailyScores);`
   - `final negCount = slidingNegCount(dailyScores, now: now);`
   - `final consec = consecutiveHighIntensityCount(dailyScores, now: now);`
   - `final z = zScoreToday(dailyScores, now: now);`
   - `final c = cusumC(dailyScores, now: now);`
4. **Resolve `triggeredTier`** (highest wins):
   - If `consec >= 3` OR `(z != null && z < -2.5)` OR `c > 4 * sigma_30(...)` → Tier.three. (Computing σ_30 here to compare against `h` is wasteful; **simpler**: have CUSUM expose a companion function `cusumThreshold(history, now)` returning `4 × σ_30`, OR have CUSUM return a tuple `(c, threshold)`. Pick one — orchestrator default: add `cusumThreshold(history, now)` as a sibling pure function in `cusum.dart`.)
   - Else if `negCount >= 5` → Tier.two.
   - Else if `mkZ != null && mkZ < -1.96` → Tier.one.
   - Else null.
5. Build `dateId = '${today.year}-${pad(today.month)}-${pad(today.day)}'` from `localMidnight(now)`.
6. Return `PatternResult(dateId, mannKendallZ: mkZ, slidingNegCount: negCount, consecutiveHighIntensity: consec, zScoreToday: z, cusumC: c, triggeredTier: ..., schemaV: 1)`.

Tests at `apps/mobile/test/features/pattern_engine/domain/usecases/run_pattern_engine_test.dart`:
- Empty entries → PatternResult with all null/zero fields, `triggeredTier == null`.
- Multiple algorithms fire same day → highest wins (e.g., 3-consecutive AND Mann-Kendall both trigger → tier=three).
- TC-30 (cross-week): construct entries spanning a Sunday→Monday boundary; assert that Mann-Kendall's 14-day window AND sliding 5-of-7 see the entries from before the boundary.
- Aggregation correctness: 3 entries on the same day (Joy×4, Calm×2, Sad×3) → that day's `DailyScore.avgScore = mean(0.8, 0.4, -0.6) = +0.2`.
- `dateId` formatting across midnight: `now = DateTime(2026, 5, 12, 0, 0, 1)` → `dateId = '2026-05-12'`.

### `PatternRepositoryImpl` + `PatternsFirestoreDatasource`

Per HB-004 §"Data shape" — concrete implementations of the abstract `PatternRepository` from Day 2:

- `apps/mobile/lib/features/pattern_engine/data/datasources/patterns_firestore_datasource.dart` — `upsertPatternResult({userId, result})` writes `users/{userId}/patterns/{result.dateId}` via `set(merge: false)`. `watchPatternResult({userId, dateId})` streams a single doc. Use a DTO (`pattern_result_dto.dart`) if cleaner; pure JSON round-trip via Freezed's `fromJson`/`toJson` is acceptable too.
- `apps/mobile/lib/features/pattern_engine/data/repositories/pattern_repository_impl.dart` — wires the datasource + Riverpod provider scaffolding (`@riverpod patternRepository`).
- DTO (if used): `apps/mobile/lib/features/pattern_engine/data/dtos/pattern_result_dto.dart` with Freezed + json_serializable.

Tests:
- `apps/mobile/test/features/pattern_engine/data/datasources/patterns_firestore_datasource_test.dart` — round-trip with `fake_cloud_firestore`. Idempotency on the same `dateId` (overwrite semantics).
- `apps/mobile/test/features/pattern_engine/data/repositories/pattern_repository_impl_test.dart` — `Result<void, PatternFailure>` mapping for happy + permission-denied + network paths.

---

## Sub-track B — Post-save wire-up + legacy detector deprecation

### Wire the engine into the mood-save flow

`apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_controller.dart` — find the post-save success path (after `await usecase(...)` returns `Ok`). Add (best-effort, non-blocking):

```dart
// after the existing successful save:
final entries = await ref.read(myMoodHistoryProvider.future);
final result = ref.read(runPatternEngineUseCaseProvider)(
  entries,
  now: DateTime.now(),
);
final saveOutcome = await ref
    .read(patternRepositoryProvider)
    .save(userId: user.uid, result: result);
saveOutcome.fold(
  ok: (_) {},
  err: (failure) => Logger.warn(
    'pattern_engine_save_failed',
    fields: {'dateId': result.dateId, 'failure': failure.runtimeType.toString()},
  ),
);
```

Use `ref.read` (one-shot), NOT `ref.watch`. Failures are logged and swallowed — they must NOT block the user's mood-save success. Logging emits ONLY `dateId` and the failure type — never `userId`, never `triggeredTier`, never any mood content (CLAUDE.md PII rule).

Add a controller-level test at `apps/mobile/test/features/mood/presentation/controllers/log_mood_submission_controller_test.dart` (extend the existing one) verifying:
- On successful mood save, `runPatternEngineUseCaseProvider` is called.
- On successful mood save, `patternRepositoryProvider.save` is called with the engine's result.
- A `PatternFailure.network()` from the repo does NOT cause the mood-save call to surface as failure to the UI.
- A pattern-engine save failure is logged once with the correct fields and no PII.

### Move and deprecate the legacy detector

1. `git mv apps/mobile/lib/features/garden/domain/pattern_detector.dart apps/mobile/lib/features/pattern_engine/domain/legacy_pattern_detector.dart`.
2. Add at the top of the function: `@Deprecated('Replaced by RunPatternEngineUseCase. See ADR-0011.')`.
3. Update imports in any file that references the old path:
   - `apps/mobile/lib/features/garden/data/providers.dart` (if it wires the legacy detector — check Day 2 Track A's edits first; Track A may have already removed this).
   - `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` — keeps using the legacy detector for now; will migrate to read `patterns/{date}.triggeredTier` in S5.
4. `git mv apps/mobile/test/features/garden/domain/pattern_detector_test.dart apps/mobile/test/features/pattern_engine/domain/legacy_pattern_detector_test.dart`.
5. Add `@Tags(['legacy'])` annotation at the top of the moved test file. Existing tests still pass — they reference the function which is `@Deprecated` but still callable. CI golden-test-config (`flutter_test_config.dart`) does not need changes; the `@Tags(['legacy'])` is informational unless a separate gate is added.

---

## Sub-track C — Cheer-up dispatcher Remote Config gate

This sub-track is the **architect's** responsibility per the do-not-do list (`cheer_up_controller.dart` is in `apps/mobile/lib/features/garden/`, which Track A nominally owned — but the dispatcher gate is a feature-flag concern, not a garden-rendering concern). On the same branch, separate commit.

### Add the flag default

Find the Remote Config defaults in `apps/mobile/lib/app/feature_flags*.dart` (the Day-1 audit referenced this surface; locate via `git grep "ai_pattern_analysis_enabled" -- apps/mobile/lib/app/`). Add a sibling default:

```dart
'intervention_dispatch_enabled': false,
```

Default `false` for v1.0. Sprint 5 flips the default to `true` once the new dispatcher reads `patterns/{date}.triggeredTier`.

### Gate the dispatcher

`apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` — at the top of `onShown` (the dispatch entry point), early-return when the flag is false:

```dart
Future<void> onShown(...) async {
  final dispatchEnabled = ref.read(featureFlagsProvider)
      .interventionDispatchEnabled; // accessor on the feature flags model
  if (!dispatchEnabled) {
    Logger.info('cheer_up_dispatch_skipped',
        fields: {'reason': 'flag_disabled'});
    return;
  }
  // ... existing flow ...
}
```

The Pattern Engine's `users/{uid}/patterns/{date}` write is **independent** of this gate (it happens upstream in `log_mood_submission_controller.dart`). The flag only suppresses the cheer-up banner + Cloud Function trigger.

### Test

`apps/mobile/test/features/garden/presentation/controllers/cheer_up_controller_test.dart` — extend the existing tests with:
- When `interventionDispatchEnabled = false`, `onShown` is a no-op (no anchor write, no cheer-up event create, no `Logger` call beyond the skip log).
- When `interventionDispatchEnabled = true`, behaviour is unchanged from current.

Use Riverpod `featureFlagsProvider.overrideWith(...)` to inject the flag value in tests.

---

## Sub-track D — Firestore rules

Architect-owned, separate commit on the same branch.

### Add `users/{uid}/patterns/{dateId}` rule

`firebase/firestore.rules` — append after the existing `users/{uid}/cheerUpEvents/{evtId}` block, before the closing `}` of the `users/{uid}` match:

```
match /patterns/{dateId} {
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
        || request.resource.data.triggeredTier in ['one','two','three'])
    && (request.resource.data.mannKendallZ == null
        || request.resource.data.mannKendallZ is number)
    && (request.resource.data.zScoreToday == null
        || request.resource.data.zScoreToday is number)
    && request.resource.data.slidingNegCount is int
    && request.resource.data.slidingNegCount >= 0
    && request.resource.data.slidingNegCount <= 7
    && request.resource.data.consecutiveHighIntensity is int
    && request.resource.data.consecutiveHighIntensity >= 0
    && request.resource.data.cusumC is number
    && request.resource.data.cusumC >= 0;

  allow delete: if false;
}
```

Note: `update` is allowed (same-day re-evaluation overwrites the doc cleanly per HB-004 §"Storage shape"). Mood text is **NOT** in the schema — the `affectedKeys().hasOnly(...)` allowlist enforces it.

### Add S5-stub denials

```
match /interventions/{id} {
  allow read: if isOwner(uid);
  allow write: if false;  // S5 dispatcher writes via admin SDK
}

match /cooldowns/{type} {
  allow read: if isOwner(uid);
  allow write: if false;  // S5 dispatcher writes via admin SDK
}
```

### Emulator tests

`firebase/test/` — extend the existing harness with two new test files:

- `firebase/test/patterns_test.ts` — covers:
  - Owner can create with valid schema.
  - Non-owner is denied.
  - Doc id NOT matching `yyyy-MM-dd` is denied.
  - Schema with extra key (`text`, `mood`, `intensity`) is denied.
  - `triggeredTier` outside allowlist is denied.
  - `slidingNegCount > 7` is denied.
  - `cusumC < 0` is denied.
  - Update with same-day id and valid schema succeeds (re-evaluation path).
  - Delete is denied.

- `firebase/test/interventions_cooldowns_test.ts` — covers: read allowed for owner, write denied for owner, read/write denied for non-owner.

---

## Build steps

After all four sub-tracks land:

1. `cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs`.
2. `cd apps/mobile && dart format --set-exit-if-changed lib/ test/`.
3. `cd apps/mobile && flutter analyze`.
4. `cd apps/mobile && flutter test test/features/pattern_engine/` — all 5 algorithm tests + orchestrator test + repo + datasource tests pass.
5. `cd apps/mobile && flutter test test/features/garden/presentation/controllers/cheer_up_controller_test.dart` — gate test passes; legacy paths still green.
6. `cd apps/mobile && flutter test` — full suite passes.
7. `cd firebase && firebase emulators:exec --only firestore "pnpm test"` — emulator suite green incl. new patterns + stub-denial tests.
8. Domain-purity grep — `git grep "package:flutter\|package:firebase_\|package:cloud_firestore" -- "apps/mobile/lib/features/pattern_engine/domain/"` returns empty.
9. `git grep "interventionDispatchEnabled\|intervention_dispatch_enabled"` — single source of truth in feature_flags.dart; no scattered string literals.

## Acceptance criteria — Day 3 done when

- [ ] Mann-Kendall, Sliding 5-of-7, 3-consecutive, Z-score, CUSUM all unit-tested with worked examples.
- [ ] TC-25..TC-30 all pass.
- [ ] `RunPatternEngineUseCase` returns a `PatternResult` for every entry-list it receives (including empty).
- [ ] Tier resolution: highest wins; numeric outputs preserved on `PatternResult` regardless of triggered tier.
- [ ] `users/{uid}/patterns/{date}` writes succeed for the owner; rule rejects extra keys, bad doc ids, and non-owner writes.
- [ ] Logging a mood writes a `patterns/{date}` doc — verify in Firestore emulator.
- [ ] Legacy `pattern_detector.dart` is moved + deprecated; `cheer_up_controller` still compiles via the new path.
- [ ] `interventionDispatchEnabled` Remote Config flag defaults to `false`; when false, the cheer-up banner does NOT surface and the cheer-up event doc is NOT created.
- [ ] Domain-purity grep clean for `pattern_engine/domain/`.
- [ ] CI green on the branch.

## Open questions

1. **CUSUM threshold exposure** — the orchestrator needs `4 × σ_30` to compare against `cusumC`. Architect default: add a sibling `cusumThreshold(history, now)` in `cusum.dart`. Alternative: change `cusumC`'s return type to `({double c, double threshold})` (Dart record) and inline the comparison. Pick the cleaner of the two.
2. **Z-score sample stddev divisor (n vs n-1)** — both are defensible; spec doesn't specify. Architect default: `n` (population). If qa-engineer's TC-28 numbers don't match, switch to `n-1` and rerun.
3. **`PatternResult.fromJson` on the `Tier` enum** — json_serializable usually handles enums via `.name`. If codegen rejects, add a `Tier.fromName / toName` adapter at the file top and `@JsonKey(fromJson: ..., toJson: ...)`. Mirror the same pattern in the rules file by accepting `'one'/'two'/'three'` as strings.
4. **Legacy detector callers** — the move of `pattern_detector.dart` may surface a stray import in the garden providers or cheer-up controller that Day-2 Track A did not migrate. If so, fix-forward in this Day-3 commit; do not roll back the move.
