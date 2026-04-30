import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../entities/garden_state.dart';

/// Pure-Dart use case that turns a flat list of `MoodEntry`s into the shape
/// the garden screen renders: total positive count, current consecutive
/// positive-day streak, and the last 7 days as `DayBloom` cells.
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

  GardenState call({
    required List<MoodEntry> entries,
    required DateTime now,
  }) {
    // Bucket positive entries by their *local* day so we can answer the
    // streak-and-bloom-bar questions in O(n) rather than rescanning the list.
    final positiveDays = <DateTime>{};
    var positiveCount = 0;
    for (final entry in entries) {
      if (entry.mood.category != MoodCategory.positive) continue;
      positiveCount += 1;
      positiveDays.add(_atMidnightLocal(entry.createdAt));
    }

    final today = _atMidnightLocal(now);

    // Streak: walk back from today; stop the first day with no positive
    // entry. If today itself is empty, the streak is 0 (intentional —
    // "missed days are empty slots", per CLAUDE.md, but the running tally
    // ends when the chain breaks).
    var streak = 0;
    var cursor = today;
    while (positiveDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Last 7 days, newest first. Each cell is `bloom` if any positive mood
    // landed that day, else `empty`. We do not distinguish "no entries" from
    // "negative-only entries" in S3 — S4 will add the wilting / rain-cloud
    // treatments.
    final last7Days = <DayBloom>[
      for (var i = 0; i < weeklyWindow; i += 1)
        DayBloom(
          day: today.subtract(Duration(days: i)),
          kind: positiveDays.contains(today.subtract(Duration(days: i)))
              ? DayBloomKind.bloom
              : DayBloomKind.empty,
        ),
    ];

    return GardenState(
      positiveMoodCount: positiveCount,
      currentStreakDays: streak,
      last7Days: last7Days,
    );
  }

  /// Truncates [dt] to midnight in the local TZ. Doing the conversion to
  /// local *before* the date math is what makes "an entry at 23:59 local"
  /// land on the day the user expects.
  static DateTime _atMidnightLocal(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
