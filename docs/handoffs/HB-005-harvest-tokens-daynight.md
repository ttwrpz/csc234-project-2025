# Handoff Brief - Weekly Harvest + Token Economy + Day/Night Theme

**WBS:** 6.1 (Weekly Harvest cycle) + 6.2 (Token economy) + 4.4 / 7.2 (Day/Night theme + dark mode)
**Sprint:** S4 (Day 4, May 12 morning)
**Target branch:** `feat/s4-redesign-foundation` (continued from Days 1–3)
**Depends on:** Day-1 Mood Score (`computeMoodScore`), Day-2 GardenState replacement (`GardenState.gardenHealth`, `PlantTier`), Day-2/3 Pattern Engine (`PatternResult`), `localMidnight` in `packages/core/`, `Result<T,F>` in `packages/core/`
**Authority:** ADR-0010 §6 (Weekly Harvest), §7 (Token economy); `.claude/specs/sprint-4-5-spec.md` §5–§6; CLAUDE.md "Copy rules" + "Pivot features 10, 11"

## Summary

Day 4 lands three independent feature tracks, each gated on Day-1/2/3 outputs being green. Together they close the Sprint-4 functional surface ahead of the Day-5 demo:

1. **Weekly Harvest cycle** - at the close of every 7-day window the user's garden is **archived** (write-once) to `users/{uid}/weeklyGardens/{weekId}` and a fresh garden begins with `H_0 = 0`. Past weeks are browsable in History. The user is shown a `WeeklySummaryScreen` before the harvest commits, with a "Continue to new week" CTA. Copy is celebratory ("harvest", "complete", "fresh week"), never punitive ("delete", "clear", "reset"). The Pattern Engine's sliding windows DO NOT reset on harvest - they read from the flat `users/{uid}/moods/` collection.

2. **Token economy** - first log of a calendar day = 5 tokens; each additional log adds 1, capped at 10/day. Mood-agnostic: logging "Sad ×5" earns the same as "Joy ×5". Missed days lose nothing. Tokens spend only on cosmetic flower skins; therapeutic features stay free. Persisted on `users/{uid}` doc fields `tokenBalance`, `tokensEarnedToday`, `lastTokenEarnedDate` (rules enforce monotonic-up-or-skin-spend on `tokenBalance`).

3. **Day/Night theme** - Settings gains a fourth `ThemeModePreference` value, `followDeviceTime`. The new `DayNightStrategy` in domain returns `ThemeMode.light` for local 07:00–19:00 and `ThemeMode.dark` otherwise (no geolocation; fixed sunrise/sunset proxy for KMUTT/Bangkok latitude). `system / light / dark / followDeviceTime` is a 4-option toggle in Settings.

The three tracks are mutually independent and CAN be built in parallel by three flutter-engineer worktrees if scheduling allows. None of them touches the Pattern Engine, the dispatcher, or the existing intervention pause.

---

## Track 6.1 - Weekly Harvest cycle

### Domain shape (pure-Dart, zero Flutter / Firebase imports)

#### NEW - `WeeklyGarden` Freezed entity

`apps/mobile/lib/features/harvest/domain/entities/weekly_garden.dart`. Match the Freezed v3 style of `apps/mobile/lib/features/mood/domain/services/mood_score.dart`.

```dart
@freezed
abstract class WeeklyGarden with _$WeeklyGarden {
  const factory WeeklyGarden({
    required String weekId,             // 'YYYY-Www' (ISO-8601 week ordinal)
    required DateTime weekStart,        // localMidnight Monday
    required DateTime weekEnd,          // localMidnight following Sunday
    required List<MoodEntry> entries,   // chronological, all entries in [weekStart, weekEnd]
    required List<double> healthHistory,// per-day H_t values for the 7 days, in order
    required WeeklySummary summary,
    required DateTime archivedAt,       // server-side timestamp on write
    @Default(1) int schemaV,
  }) = _WeeklyGarden;

  factory WeeklyGarden.fromJson(Map<String, Object?> json) =>
      _$WeeklyGardenFromJson(json);
}

@freezed
abstract class WeeklySummary with _$WeeklySummary {
  const factory WeeklySummary({
    required double averageMoodScore,   // mean of all entries' MoodScore.value
    required Map<MoodType, int> moodCounts, // dominant emotions
    required PlantTier endingPlantTier, // tier on the final day of the week
    required int totalEntryCount,
    required int triggeredTierCount,    // count of `patterns/{date}.triggeredTier != null` days
  }) = _WeeklySummary;

  factory WeeklySummary.fromJson(Map<String, Object?> json) =>
      _$WeeklySummaryFromJson(json);
}
```

#### NEW - `ArchiveWeeklyGardenUseCase`

`apps/mobile/lib/features/harvest/domain/usecases/archive_weekly_garden.dart`.

```dart
class ArchiveWeeklyGardenUseCase {
  const ArchiveWeeklyGardenUseCase({
    required HarvestRepository repository,
    required ComputeWeeklySummaryUseCase computeSummary,
  });

  /// Archives the week containing [weekStart]. Returns `Err(alreadyArchived)`
  /// when the week's `weeklyGardens/{weekId}` doc already exists. Idempotent
  /// on the doc id, write-once-on-archive per ADR-0010 §6.
  Future<Result<WeeklyGarden, HarvestFailure>> call({
    required String userId,
    required DateTime weekStart,
    required DateTime now,
    required List<MoodEntry> weekEntries,
    required List<double> dailyHealthHistory,
  });
}
```

Internal flow:
1. Compute `weekId = '${weekStart.year}-W${isoWeekNumber(weekStart).padLeft(2, '0')}'`.
2. Build `WeeklySummary` via `computeSummary(weekEntries)` (helper below).
3. Build `WeeklyGarden(weekId, weekStart, weekStart + 7d, weekEntries, dailyHealthHistory, summary, archivedAt: now)`.
4. Forward to `repository.archive(userId: userId, garden: garden)`. Repository contract is write-once: returns `Err(HarvestFailure.alreadyArchived(weekId))` on collision (the Firestore rule denies update - see §"Firestore rules" below).
5. On success, return the persisted `WeeklyGarden`.

The use case does NOT delete or modify `users/{uid}/moods/{moodId}` entries. The flat moods collection remains intact across the harvest boundary so the Pattern Engine's 14-day Mann-Kendall and 30-day Z-score / CUSUM windows are unaffected.

#### NEW - `ComputeWeeklySummaryUseCase`

`apps/mobile/lib/features/harvest/domain/usecases/compute_weekly_summary.dart`. Pure Dart; no I/O.

```dart
class ComputeWeeklySummaryUseCase {
  const ComputeWeeklySummaryUseCase();

  WeeklySummary call({
    required List<MoodEntry> weekEntries,
    required List<double> dailyHealthHistory,
    required int triggeredTierCount,  // caller pulls from patterns/{date} for the week
  });
}
```

`averageMoodScore = mean(weekEntries.map((e) => computeMoodScore(e.mood, e.intensity).value))`. `moodCounts` is `MoodType → int` over `weekEntries`. `endingPlantTier = PlantTier.fromHealth(dailyHealthHistory.last)` - null-safe, default `PlantTier.resting` when the list is empty.

#### NEW - abstract `HarvestRepository`

`apps/mobile/lib/features/harvest/domain/repositories/harvest_repository.dart`.

```dart
abstract class HarvestRepository {
  Future<Result<WeeklyGarden, HarvestFailure>> archive({
    required String userId,
    required WeeklyGarden garden,
  });

  Stream<List<WeeklyGarden>> watchHistory({required String userId});

  Future<Result<WeeklyGarden, HarvestFailure>> getByWeekId({
    required String userId,
    required String weekId,
  });
}
```

#### NEW - sealed `HarvestFailure`

`apps/mobile/lib/features/harvest/domain/harvest_failure.dart`. Cases: `unknown(String message)`, `network()`, `permissionDenied()`, `alreadyArchived(String weekId)`, `noEntries()` (the use case rejects archiving a week with zero entries - there's nothing to summarise).

### Data shape

#### NEW - `WeeklyGardensFirestoreDatasource`

`apps/mobile/lib/features/harvest/data/datasources/weekly_gardens_firestore_datasource.dart`. Concrete writes go to `users/{userId}/weeklyGardens/{weekId}`. The datasource uses `set(merge: false)` with the rule's write-once enforcement (the rule denies update; only create succeeds).

#### NEW - `HarvestRepositoryImpl`

`apps/mobile/lib/features/harvest/data/repositories/harvest_repository_impl.dart`. Wires the datasource + DTO mapper + Riverpod provider scaffolding.

#### NEW - Drift table for offline-first reads (optional, recommended)

`apps/mobile/lib/features/harvest/data/local/weekly_garden_table.dart` + DAO. The History page benefits from offline reads - reading from Drift means a user offline still sees their archived weeks. Drift is already wired for moods (see `apps/mobile/lib/features/mood/data/local/`), follow that pattern. **If this is over-scope for Day 4**, defer to v1.x and read directly from Firestore in v1.0 (acceptable trade-off; a user offline on the History page sees a loading spinner instead of cached weeks).

### Presentation

#### NEW - `WeeklySummaryScreen`

`apps/mobile/lib/features/harvest/presentation/weekly_summary_screen.dart`. Shown ONCE before each harvest commits (a `harvestPendingProvider` returns true when a week's end has been crossed and the user has not yet acknowledged the summary). Layout (from top):

1. App-bar `Text('Your week')` (no "delete", "clear", "reset").
2. Hero illustration: a small `PlantTierGroup` rendering at `summary.endingPlantTier`.
3. `SizedBox(MoodBloomSpacing.xl)`.
4. Section "Average mood": `summary.averageMoodScore` rendered as a horizontal scale `-1.0 ←----|----→ +1.0` with a marker.
5. Section "Dominant emotions": top-3 `MoodType` chips ordered by `summary.moodCounts`.
6. Section "Pattern check-ins": `'${summary.triggeredTierCount} day(s) the engine paused with you'` (compassionate framing - never "alerts fired", never numeric tier names).
7. Full-width `FilledButton('Continue to new week')` - on tap, calls `harvestController.acknowledge()` which (a) creates a fresh garden with `H_0 = 0`, (b) hides the screen.

Banner copy below the hero (from CLAUDE.md): *"Your garden this week has been harvested and saved to your history. A new week begins - a fresh canvas for your story."* - locked phrasing; do not paraphrase.

#### NEW - History extension

`apps/mobile/lib/features/harvest/presentation/weekly_harvests_tab.dart`. Tab nested in the existing `apps/mobile/lib/features/history/presentation/`. Lists archived weeks newest-first. Each list item: weekId, hero plant tier sprite, average mood, entry count. Tap → navigate to `apps/mobile/lib/features/harvest/presentation/archived_week_screen.dart` showing all entries from that week (reuse `mood_entry_tile.dart` from the existing history feature). Tap any entry → existing `entry_detail_screen.dart` from the mood feature (read-only after the 24h immutability boundary, as today).

#### Wiring in `garden_screen.dart`

When the user opens the garden screen and `harvestPendingProvider` is true, route them to `WeeklySummaryScreen` instead of the canvas. Use `addPostFrameCallback` to navigate after the first frame so the route stack stays clean. The harvest controller flips `harvestPendingProvider` back to false on `acknowledge()`.

### Copy audit (pre-merge gate)

`qa-engineer` greps every user-facing string under `apps/mobile/lib/features/harvest/` for the forbidden vocabulary:

```
delete, clear, reset, lost, destroyed, gone, erased, wilted, wilting, dead, dying
```

Any hit blocks merge (TC-15). Use `Grep` for the audit; record the result in the PR description.

### Tests (qa-engineer + flutter-engineer co-author)

- `apps/mobile/test/features/harvest/domain/usecases/archive_weekly_garden_test.dart` - TC-11 (archive on day 7 → fresh garden with H_0 = 0), TC-13 (entries preserved post-archive), TC-14 (summary stats correct), `alreadyArchived` collision returns `Err`, no-entries week returns `Err(noEntries)`.
- `apps/mobile/test/features/harvest/domain/usecases/compute_weekly_summary_test.dart` - averageMoodScore math, dominant-emotions ordering, endingPlantTier from health history, triggeredTierCount pass-through.
- `apps/mobile/test/features/harvest/copy_audit_test.dart` - TC-15. Greps a list of recursively-loaded `.dart` files under `lib/features/harvest/` for forbidden words. Implement using `dart:io` File reads + a simple regex; bail with a descriptive `expect` failure naming the offending file + line.
- `apps/mobile/test/features/harvest/presentation/weekly_summary_screen_test.dart` - widget test: renders three sections + Continue button; tap calls the controller's `acknowledge()`.

---

## Track 6.2 - Token economy

### Domain shape (pure-Dart)

#### NEW - `TokenBalance` Freezed entity

`apps/mobile/lib/features/tokens/domain/entities/token_balance.dart`.

```dart
@freezed
abstract class TokenBalance with _$TokenBalance {
  const factory TokenBalance({
    required int balance,                 // total accumulated (≥ 0)
    required int earnedToday,             // 0..10 (resets at midnight)
    required DateTime? lastEarnedDate,    // localMidnight of last award
  }) = _TokenBalance;

  factory TokenBalance.fromJson(Map<String, Object?> json) =>
      _$TokenBalanceFromJson(json);
}
```

#### NEW - `AwardDailyTokensUseCase`

`apps/mobile/lib/features/tokens/domain/services/award_daily_tokens.dart`. **Pure-Dart top-level function.** No class wrapper. **Crucially does NOT read `MoodScore`, `MoodEntry.text`, or `MoodType`** - verifiable by file-level grep. Signature:

```dart
/// Computes the token award for a new mood log given the current balance
/// state and `now`. Mood-agnostic by construction (no mood inputs).
///
/// First log of the calendar day awards 5 tokens; each additional log
/// adds 1, capped at 10/day. Missed days lose nothing - the function
/// reads `lastEarnedDate` only to decide whether `earnedToday` resets.
TokenAward awardDailyTokens({
  required TokenBalance current,
  required DateTime now,
});

@freezed
abstract class TokenAward with _$TokenAward {
  const factory TokenAward({
    required int award,                 // 0..5
    required TokenBalance updated,
  }) = _TokenAward;
}
```

Algorithm:
1. `today = localMidnight(now)`.
2. If `current.lastEarnedDate == null` OR `current.lastEarnedDate != today`: this is the first log of the day. `award = 5`, `earnedToday = 5`, `lastEarnedDate = today`.
3. Else (same calendar day): if `current.earnedToday < 10`: `award = 1`, `earnedToday = current.earnedToday + 1`. Else (cap reached): `award = 0`, `earnedToday` unchanged.
4. `updated = TokenBalance(balance: current.balance + award, earnedToday: ..., lastEarnedDate: ...)`.

The function NEVER decreases `balance`. Skin purchases use a separate `SpendTokensUseCase` (out of S4 scope; v1.0 has no skin purchase UI).

### Data shape

#### NEW - `TokenBalanceFirestoreDatasource`

`apps/mobile/lib/features/tokens/data/datasources/token_balance_firestore_datasource.dart`. Reads/writes the three top-level fields on `users/{uid}` doc: `tokenBalance`, `tokensEarnedToday`, `lastTokenEarnedDate`. NOT a sub-collection - these are fields on the user-profile doc per CLAUDE.md "Firestore data model" section.

Use a Firestore transaction for atomic update:
1. Read `users/{uid}` → `current` snapshot.
2. Build `TokenBalance` from snapshot.
3. Compute `awardDailyTokens(current, now)` → `award`.
4. Write `users/{uid}` with the three updated fields via `update({'tokenBalance': award.updated.balance, 'tokensEarnedToday': award.updated.earnedToday, 'lastTokenEarnedDate': award.updated.lastEarnedDate})`.

#### NEW - `TokenRepositoryImpl` + abstract `TokenRepository`

`apps/mobile/lib/features/tokens/domain/repositories/token_repository.dart` (abstract) + `apps/mobile/lib/features/tokens/data/repositories/token_repository_impl.dart`.

```dart
abstract class TokenRepository {
  Future<Result<TokenAward, TokenFailure>> awardForLog({required String userId});

  Stream<TokenBalance> watchBalance({required String userId});
}
```

The repo's `awardForLog` runs the transaction. Failure type `TokenFailure` follows the now-standard pattern (cases: `unknown`, `network`, `permissionDenied`).

### Presentation

The post-save flow in `apps/mobile/lib/features/mood/presentation/controllers/log_mood_submission_controller.dart` already runs the Pattern Engine (Day 3 wire-up) - add a sibling call `await ref.read(tokenRepositoryProvider).awardForLog(userId: user.uid)` AFTER the engine save succeeds. Failure of token award is best-effort (logged via `Logger`, never blocks the user's mood-save success). Order: `save mood → run pattern engine → save patterns/{date} → award tokens`.

The Settings screen gains a **"Show token balance"** toggle (boolean, default `true`). When on, the garden screen's app-bar shows a small chip: `'🪙 ${balance}'` (use a Material icon, NOT an emoji literal - match the design-system style). When off, the chip is hidden but tokens still accumulate. (Anti-pattern guardrail: optional visibility, never forced.)

### Tests

- `apps/mobile/test/features/tokens/domain/services/award_daily_tokens_test.dart` - TC-1..TC-5, with TC-2 the **load-bearing** mood-agnostic equality test:

  ```dart
  test('TC-2 mood-agnostic: same balance state produces same award regardless of mood', () {
    final state = TokenBalance(balance: 0, earnedToday: 0, lastEarnedDate: null);
    final now = DateTime(2026, 5, 12, 10, 30);
    final firstAward = awardDailyTokens(current: state, now: now);
    expect(firstAward.award, 5);
    // No mood input - by construction, the function CANNOT depend on
    // mood content. Test acts as a regression guard: any future change
    // that adds a `MoodType` or `MoodScore` parameter would break this
    // call site, surfacing the violation at compile time.
  });

  // Plus a separate "domain-purity" test that greps the file for forbidden imports:
  test('TC-2 file-level: award_daily_tokens.dart imports no MoodType / MoodEntry / MoodScore', () {
    final source = File('lib/features/tokens/domain/services/award_daily_tokens.dart')
        .readAsStringSync();
    expect(source, isNot(contains('mood_type.dart')));
    expect(source, isNot(contains('mood_entry.dart')));
    expect(source, isNot(contains('mood_score.dart')));
  });
  ```

- TC-1 (5–10 within cap): first log = 5; second log = 6; third = 7; fourth = 8; fifth = 9; sixth = 10; seventh = 10 (cap, award=0).
- TC-3 (cap): after `earnedToday == 10`, additional logs award = 0.
- TC-4 (midnight reset): `current.lastEarnedDate = today - 1`, log → award = 5, `earnedToday = 5`.
- TC-5 (no streak punishment): missed-day case where `lastEarnedDate = today - 3`; log → award = 5; `balance = previous + 5`. No reset of `balance`.

- `apps/mobile/test/features/tokens/data/repositories/token_repository_impl_test.dart` - transaction round-trip with a fake Firestore (use `fake_cloud_firestore`).

---

## Track 4.4 / 7.2 - Day/Night theme

### Domain shape (pure-Dart)

#### NEW - `ThemeModePreference` enum

`apps/mobile/lib/features/settings/domain/entities/theme_mode_preference.dart`.

```dart
enum ThemeModePreference {
  system,           // ThemeMode.system - follows device theme (existing default)
  light,            // ThemeMode.light - always light
  dark,             // ThemeMode.dark - always dark
  followDeviceTime, // light during local 07:00–19:00, dark otherwise
}
```

#### NEW - `DayNightStrategy`

`apps/mobile/lib/features/settings/domain/services/day_night_strategy.dart`. Pure-Dart; resolves preference + time → concrete `ThemeMode`. **The return type imports `flutter/material.dart` (`ThemeMode`)** - this is the ONE PLACE in domain that does so, because `ThemeMode` is a Material type with no domain analog. Document this exception in the file's docstring; flag for `architect` review at PR time.

```dart
class DayNightStrategy {
  const DayNightStrategy({this.dayStartHour = 7, this.dayEndHour = 19});

  final int dayStartHour;
  final int dayEndHour;

  ThemeMode resolve({
    required ThemeModePreference preference,
    required DateTime now,
  });
}
```

For `followDeviceTime`: `final h = now.toLocal().hour; return (h >= dayStartHour && h < dayEndHour) ? ThemeMode.light : ThemeMode.dark;`. For all other preferences: trivial mapping.

**Architectural exception notice:** the domain-purity rule (CLAUDE.md "the one rule that cannot break") forbids `package:flutter/*` imports under `domain/`. `ThemeMode` is the single allowed exception because (a) `ThemeMode` is an enum-like value, not a UI concern, and (b) re-creating a custom `MoodBloomThemeMode` enum and mapping it at every callsite would be pure ceremony. Document this in the `architect`'s ADR-0010 follow-up (a 1-line addition to ADR-0010's Compliance Check section).

If the orchestrator rejects the exception, fallback: define a domain-side `ResolvedTheme { isDark: bool }` value and let the presentation controller map to `ThemeMode`.

### Data shape

#### EDIT - `ThemeModeStorage`

`apps/mobile/lib/features/settings/data/theme_mode_storage.dart`. Currently serialises `ThemeMode`. Migrate to `ThemeModePreference`:

```dart
ThemeModePreference read() {
  switch (_prefs.getString(_key)) {
    case 'light': return ThemeModePreference.light;
    case 'dark': return ThemeModePreference.dark;
    case 'follow_device_time': return ThemeModePreference.followDeviceTime;
    case 'system':
    case null:
    default: return ThemeModePreference.system;
  }
}

Future<void> write(ThemeModePreference preference) async {
  await _prefs.setString(_key, _serialize(preference));
}
```

`_serialize` maps the four enum values to `'system' / 'light' / 'dark' / 'follow_device_time'`. Existing storage is read-compatible (the `'system' / 'light' / 'dark'` strings already on disk decode correctly to the new enum).

### Presentation

#### EDIT - `ThemeModeController`

`apps/mobile/lib/features/settings/presentation/controllers/theme_mode_controller.dart`. State now carries `ThemeModePreference` (not `ThemeMode`). The controller exposes a derived `currentThemeMode` property/provider that calls `DayNightStrategy.resolve(preference: state, now: DateTime.now())`. When `state == followDeviceTime`, the controller subscribes to a `Stream.periodic(Duration(minutes: 15))` to re-evaluate (cheap; no network). On `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` the controller also re-evaluates eagerly to handle case where the user resumes the app across the 07:00 / 19:00 boundary.

#### EDIT - `SettingsScreen`

`apps/mobile/lib/features/settings/presentation/settings_screen.dart`. Add a 4-option toggle:

- "Follow device theme" (`system`)
- "Follow device time" (`followDeviceTime`)
- "Always light" (`light`)
- "Always dark" (`dark`)

Use `RadioListTile<ThemeModePreference>`. Group label: `'Theme'`. Place above the existing notifications toggle. Semantics labels descriptive ("Theme: Follow device time, selected").

### Tests

- `apps/mobile/test/features/settings/domain/services/day_night_strategy_test.dart` - TC-19 (`system` returns `ThemeMode.system`), TC-20 (`followDeviceTime` returns light at 14:00 local, dark at 20:00 local). Plus boundary cases: 06:59 (dark), 07:00 (light), 18:59 (light), 19:00 (dark).
- `apps/mobile/test/features/settings/data/theme_mode_storage_test.dart` - round-trip for the new `followDeviceTime` value; backward-compat for legacy `'system'/'light'/'dark'` strings on disk.
- `apps/mobile/test/features/settings/presentation/settings_screen_golden_test.dart` - extend the existing golden suite with a 4th radio tile.

---

## Files to NOT touch (any track)

- `apps/mobile/lib/features/auth/**`, `apps/mobile/lib/features/onboarding/**`.
- `apps/mobile/lib/features/garden/**` except the `garden_screen.dart` route to `WeeklySummaryScreen` (Track 6.1).
- `apps/mobile/lib/features/pattern_engine/**`.
- `apps/mobile/lib/features/intervention/**`, `disclaimer/**`, `insights/**` (S5).
- `apps/mobile/lib/main.dart`, `apps/mobile/lib/app/router.dart` - architect adds the harvest route.
- `firebase/firestore.rules` - architect lands the new collection rules + user-doc field validation in a separate commit.
- `functions/**`.
- ADRs / handoff briefs / audit doc under `docs/`.
- `*.g.dart` / `*.freezed.dart` (run build_runner).

## Firestore rules (architect, separate commit on the same branch)

```
match /users/{uid} {
  allow read: if isOwner(uid);

  // Field-level validation on the user doc - replaces the overly
  // permissive `allow read, write` on line 9–10 of firestore.rules.
  // tokenBalance is monotonic-up only (skin purchases land in S5
  // with a separate diff()-affectedKeys() rule for the spend path).
  allow create: if isOwner(uid)
    && (!request.resource.data.keys().hasAny(['tokenBalance']) ||
        request.resource.data.tokenBalance == 0)
    && (!request.resource.data.keys().hasAny(['tokensEarnedToday']) ||
        request.resource.data.tokensEarnedToday == 0)
    && (!request.resource.data.keys().hasAny(['insightsDisclaimerAcked']) ||
        request.resource.data.insightsDisclaimerAcked == false);

  allow update: if isOwner(uid)
    // tokenBalance only goes up (skin purchases use a separate atomic
    // path landing in S5 - for v1.0 the field is monotonic increase).
    && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['tokenBalance']) ||
        request.resource.data.tokenBalance >= resource.data.tokenBalance)
    // earnedToday capped at 10.
    && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['tokensEarnedToday']) ||
        (request.resource.data.tokensEarnedToday is int
         && request.resource.data.tokensEarnedToday >= 0
         && request.resource.data.tokensEarnedToday <= 10))
    // insightsDisclaimerAcked is one-way false → true (S5 reads it).
    && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['insightsDisclaimerAcked']) ||
        (resource.data.get('insightsDisclaimerAcked', false) == false ||
         request.resource.data.insightsDisclaimerAcked == true));

  allow delete: if false;
}

match /users/{uid}/weeklyGardens/{weekId} {
  allow read: if isOwner(uid);

  allow create: if isOwner(uid)
    && weekId.matches('^\\d{4}-W\\d{2}$')
    && request.resource.data.weekId == weekId
    && request.resource.data.archivedAt == request.time
    && request.resource.data.schemaV == 1;

  // Write-once-on-archive: history is a record, not a redo.
  allow update, delete: if false;
}
```

The `interventionState`, `cheerUpEvents`, `settings/notifications` rules from earlier sprints stay intact. The new `users/{uid}/patterns/{date}` rule from Day 3 is independent and lands in a separate Day-3 commit.

## Build steps (per track)

1. `cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs`.
2. `cd apps/mobile && dart format --set-exit-if-changed lib/ test/`.
3. `cd apps/mobile && flutter analyze`.
4. `cd apps/mobile && flutter test test/features/<track>/`.
5. `cd apps/mobile && flutter test` - full suite.
6. Domain-purity grep - must be empty for `harvest`, `tokens`. The `settings` domain has the documented `ThemeMode` exception; flag in PR description.

## Acceptance criteria - Day-4 done when

**Track 6.1 (Harvest):**
- [ ] TC-11 passes - week's end → archive + fresh garden with H_0 = 0.
- [ ] TC-12 passes - archived garden viewable in History.
- [ ] TC-13 passes - tap entry in archived week → mood entry detail.
- [ ] TC-14 passes - Weekly Summary screen renders with correct stats.
- [ ] TC-15 passes - copy-audit grep returns zero hits for forbidden vocabulary.
- [ ] `weeklyGardens/{weekId}` rule denies update + delete (rules emulator test).

**Track 6.2 (Tokens):**
- [ ] TC-1 passes - first log of day → 5 tokens.
- [ ] TC-2 passes (mood-agnostic) - file-level import grep + behavioural equality.
- [ ] TC-3 passes - cap at 10/day.
- [ ] TC-4 passes - midnight reset.
- [ ] TC-5 passes - missed days lose nothing.
- [ ] User-doc rule rejects monotonic-down increments (rules emulator test).
- [ ] `tokenBalanceProvider` updates the garden-screen chip when "Show token balance" is on.

**Track 4.4 / 7.2 (Day/Night):**
- [ ] TC-19 passes - `system` mode follows device.
- [ ] TC-20 passes - `followDeviceTime` mode flips at 07:00 / 19:00 local.
- [ ] Settings screen shows 4 radio options.
- [ ] Existing dark-mode goldens still pass after the toggle UI change.

When all 14 boxes are checked, Day 4 is done. Day 5 is qa + security audit + tag.

## Open questions for orchestrator

1. **`ThemeMode` import in `domain/`** - Track 4.4's `DayNightStrategy` needs to return `ThemeMode`. Architect default: allow the single import, document the exception in ADR-0010's Compliance Check footer. Alternative: domain-side `ResolvedTheme { isDark: bool }` value with presentation-layer mapping. Confirm before merge.
2. **Drift offline cache for archived weeks** - Track 6.1 recommends adding a Drift table for `WeeklyGarden`. Architect default: defer to v1.x; v1.0 reads directly from Firestore in History. Confirm.
3. **Skin purchase UI** - out of S4 scope. The `tokenBalance` rule today is monotonic-up; the spend path is S5. Confirm no v1.0 demo asks the user to buy a skin.
4. **Token-chip placement** - architect default puts a small chip in the garden-screen app bar. Alternative: in the History tab header, or in Settings only. Confirm.
