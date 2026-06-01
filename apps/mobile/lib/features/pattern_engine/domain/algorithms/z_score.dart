import 'dart:math' as math;

import 'package:core/core.dart';

import '../entities/daily_score.dart';

/// Returns the Z-score of today's average mood score against the user's
/// personal `baselineDays`-day baseline (excluding today).
///
/// Returns `null` when:
///   * today's entry is not present in `history` (no signal today),
///   * the baseline has fewer than 14 distinct day-entries (warm-up period),
///   * the baseline standard deviation is below `sigmaEpsilon`
///     (division-by-zero guard for a flat baseline).
///
/// Caller compares the result against `< -2.5` for Tier 3 and against
/// `|z| > 2` for the looser "extreme" flag - not used as a tier trigger
/// but logged on `PatternResult` for diagnostic surfaces.
///
/// **Variance divisor:** population stddev (`n` divisor), NOT sample
/// stddev (`n-1`). The baseline is the user's *own* 30 days - they ARE
/// the population, not a sample drawn from one - so dividing by `n` is
/// the truer translation. Sample stddev is acceptable (the warm-up gate
/// hides the divisor distinction at small `n`); flip to `n-1` if
/// downstream test cases need it.
///
/// Note: this Z is NOT the same as Mann-Kendall's Z (same letter,
/// different statistic).
///
/// Pure-Dart function - imports only `dart:math`, `package:core/core.dart`
/// (for `localMidnight`), and the sibling [DailyScore] entity.
double? zScoreToday(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
}) {
  if (history.isEmpty) return null;

  final today = localMidnight(now);

  // Bucket by local-midnight day to handle duplicate `day` keys defensively
  // (last-write-wins). Today's score is looked up from this bucket.
  final byDay = <DateTime, double>{
    for (final entry in history) localMidnight(entry.day): entry.avgScore,
  };

  final todayScore = byDay[today];
  if (todayScore == null) return null;

  // Build baseline: distinct days within the last `baselineDays` calendar
  // days, EXCLUDING today. Iterating `byDay` (already deduped) keeps the
  // baseline length monotone with the user's actual logging cadence.
  final baseline = <double>[];
  for (final MapEntry(:key, :value) in byDay.entries) {
    if (key == today) continue;
    final diff = today.difference(key).inDays;
    if (diff > 0 && diff <= baselineDays) {
      baseline.add(value);
    }
  }

  if (baseline.length < 14) return null;

  final mu = baseline.reduce((a, b) => a + b) / baseline.length;
  var sumSquares = 0.0;
  for (final v in baseline) {
    final d = v - mu;
    sumSquares += d * d;
  }
  // Population stddev - divisor `n`, see docstring for rationale.
  final sigma = math.sqrt(sumSquares / baseline.length);

  if (sigma < sigmaEpsilon) return null;

  return (todayScore - mu) / sigma;
}
