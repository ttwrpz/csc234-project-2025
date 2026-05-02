import 'package:core/core.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../entities/garden_state.dart';

/// Pure-Dart use case that turns a flat list of `MoodEntry`s into the shape
/// the garden screen renders: total counts per glyph kind, current
/// consecutive positive-day streak, and the last 7 days as `DayBloom` cells.
///
/// `now` is injected so unit tests can pin the "today" anchor and so we don't
/// drift across midnight during a single computation.
///
/// Time-zone semantics: every entry's `createdAt` is converted to local time
/// and truncated to midnight before bucketing. This matches CLAUDE.md's
/// expectation that the user sees the garden in *their* day boundaries.
class ComputeGardenStateUseCase {
  const ComputeGardenStateUseCase();

  /// Number of cells in the weekly bloom bar. Public so widget tests can
  /// reference it without hard-coding a magic number.
  static const int weeklyWindow = 7;

  /// Pure mapping from a single (mood, intensity) pair to the bloom-bar kind
  /// it would imply for its day, **before** any per-day priority resolution.
  ///
  /// Rule (per ADR-0006): positives are blooms; negatives split on
  /// user-felt intensity — `i ≤ 3` wilts gently, `i ≥ 4` rains. `intensity`
  /// is clamped defensively to `[1, 5]` so a malformed entry can never
  /// poison the bucketing.
  static DayBloomKind kind(MoodType mood, int intensity) {
    if (mood.category == MoodCategory.positive) return DayBloomKind.bloom;
    final i = intensity.clamp(1, 5);
    return i <= 3 ? DayBloomKind.wilting : DayBloomKind.rainCloud;
  }

  GardenState call({required List<MoodEntry> entries, required DateTime now}) {
    // Bucket entries into three day-sets so we can answer the streak +
    // bloom-bar questions in O(n). Counts are tracked separately because
    // multiple entries can land on the same day and we still want each entry
    // to contribute to the canvas density.
    final positiveDays = <DateTime>{};
    final wiltingDays = <DateTime>{};
    final rainDays = <DateTime>{};
    var positiveCount = 0;
    var wiltingCount = 0;
    var rainCloudCount = 0;
    for (final entry in entries) {
      final day = localMidnight(entry.createdAt);
      switch (kind(entry.mood, entry.intensity)) {
        case DayBloomKind.bloom:
          positiveCount += 1;
          positiveDays.add(day);
        case DayBloomKind.wilting:
          wiltingCount += 1;
          wiltingDays.add(day);
        case DayBloomKind.rainCloud:
          rainCloudCount += 1;
          rainDays.add(day);
        case DayBloomKind.empty:
          // `kind()` never returns `empty` for a logged entry; the case
          // exists only so the switch is exhaustive over the enum.
          break;
      }
    }

    final today = localMidnight(now);

    // Streak: walk back from today; stop the first day with no positive
    // entry. **Wilting and rain-cloud days do NOT count** — we do not
    // streak-reward negative logging (regression guard: see test).
    var streak = 0;
    var cursor = today;
    while (positiveDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Last 7 days, newest first. Per ADR-0006 the per-cell priority is
    // `bloom > rainCloud > wilting > empty` — a single positive entry
    // outranks any number of negatives that day, and a stormy negative
    // outranks a gentler one.
    final last7Days = <DayBloom>[
      for (var i = 0; i < weeklyWindow; i += 1)
        () {
          final day = today.subtract(Duration(days: i));
          final DayBloomKind kindForDay;
          if (positiveDays.contains(day)) {
            kindForDay = DayBloomKind.bloom;
          } else if (rainDays.contains(day)) {
            kindForDay = DayBloomKind.rainCloud;
          } else if (wiltingDays.contains(day)) {
            kindForDay = DayBloomKind.wilting;
          } else {
            kindForDay = DayBloomKind.empty;
          }
          return DayBloom(day: day, kind: kindForDay);
        }(),
    ];

    return GardenState(
      positiveMoodCount: positiveCount,
      wiltingMoodCount: wiltingCount,
      rainCloudMoodCount: rainCloudCount,
      currentStreakDays: streak,
      last7Days: last7Days,
    );
  }
}
