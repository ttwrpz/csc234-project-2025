import 'package:core/core.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/services/mood_score.dart';
import '../algorithms/cusum.dart';
import '../algorithms/mann_kendall.dart';
import '../algorithms/sliding_5_of_7.dart';
import '../algorithms/three_consecutive.dart';
import '../algorithms/z_score.dart';
import '../entities/daily_score.dart';
import '../entities/pattern_result.dart';
import '../entities/tier.dart';

/// Runs the 5-algorithm Pattern Engine over a user's mood history and
/// returns the per-day [PatternResult] for "today" (anchored on `now`).
///
/// Stateless and pure — no I/O, no Firebase, no Flutter, no Riverpod
/// (the Riverpod provider lives in `data/providers.dart` to keep the
/// domain layer pure per CLAUDE.md). The Day-3 post-save wire-up calls
/// this from `LogMoodController` after every successful mood log; the
/// result is then handed to the data layer for upsert at
/// `users/{uid}/patterns/{dateId}`.
///
/// Per HB-004 §"RunPatternEngineUseCase" + HB-006 sub-track A:
///  1. Aggregate `entries` by `localMidnight(entry.createdAt)` into a
///     list of [DailyScore] (sorted ascending by day).
///  2. Run all 5 algorithms.
///  3. Resolve `triggeredTier` (highest wins; null when no algorithm fires).
///  4. Format `dateId = yyyy-MM-dd` from `localMidnight(now)`.
class RunPatternEngineUseCase {
  const RunPatternEngineUseCase();

  PatternResult call(List<MoodEntry> entries, {required DateTime now}) {
    final dailyScores = _aggregate(entries);

    final mkZ = mannKendallZ(dailyScores);
    final negCount = slidingNegCount(dailyScores, now: now);
    final consec = consecutiveHighIntensityCount(dailyScores, now: now);
    final z = zScoreToday(dailyScores, now: now);
    final c = cusumC(dailyScores, now: now);
    final h = cusumThreshold(dailyScores, now: now);

    // Highest tier wins. Three checks for Tier 3 are independently
    // sufficient (any one fires); Tier 2 only if no Tier-3 trigger;
    // Tier 1 only if neither 2 nor 3 fired.
    Tier? tier;
    if (consec >= 3 || (z != null && z < -2.5) || c > h) {
      tier = Tier.three;
    } else if (negCount >= 5) {
      tier = Tier.two;
    } else if (mkZ != null && mkZ < -1.96) {
      tier = Tier.one;
    }

    return PatternResult(
      dateId: _dateId(now),
      mannKendallZ: mkZ,
      slidingNegCount: negCount,
      consecutiveHighIntensity: consec,
      zScoreToday: z,
      cusumC: c,
      triggeredTier: tier,
    );
  }

  /// Buckets `entries` by `localMidnight(createdAt)`, computes per-entry
  /// `MoodScore` via `computeMoodScore`, and emits one [DailyScore] per
  /// distinct day. Output is sorted ascending by day so the algorithms
  /// (Mann-Kendall + CUSUM in particular) see a chronological sequence.
  List<DailyScore> _aggregate(List<MoodEntry> entries) {
    if (entries.isEmpty) return const [];

    final buckets = <DateTime, List<double>>{};
    for (final entry in entries) {
      final day = localMidnight(entry.createdAt);
      final score = computeMoodScore(entry.mood, entry.intensity).value;
      (buckets[day] ??= <double>[]).add(score);
    }

    final days = buckets.keys.toList()..sort();
    return [
      for (final day in days)
        DailyScore(
          day: day,
          avgScore: _mean(buckets[day] ?? const []),
          entryCount: (buckets[day] ?? const []).length,
        ),
    ];
  }

  double _mean(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  /// Formats `localMidnight(now)` as `yyyy-MM-dd` (the doc id at
  /// `users/{uid}/patterns/{dateId}` and the regex the rule pins).
  String _dateId(DateTime now) {
    final today = localMidnight(now);
    final mm = today.month.toString().padLeft(2, '0');
    final dd = today.day.toString().padLeft(2, '0');
    return '${today.year}-$mm-$dd';
  }
}
