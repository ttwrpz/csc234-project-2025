import 'package:core/core.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/services/mood_score.dart';
import '../entities/atmosphere.dart';
import '../entities/garden_state.dart';
import '../entities/plant_tier.dart';
import '../services/atmosphere.dart' as atmosphere_service;
import '../services/garden_health_ewma.dart';

/// Pure-Dart use case that turns a flat list of `MoodEntry`s into the
/// Sprint 4–5 ecosystem [GardenState]:
///   * `H_t` Garden Health folded over the current week's per-day means
///     (`gardenHealth`) → drives [PlantTier] (5 alive tiers).
///   * Today's mean mood-score → drives [Atmosphere] (4 weather states).
///   * The last 7 calendar days as [DayScore] cells (newest first).
///
/// `now` and `weekStart` are injected so unit tests can pin both
/// anchors. `weekStart` is the local-midnight `DateTime` of the
/// current week's first day (e.g. Monday); the EWMA fold runs over
/// `[weekStart, now]` and resets to `H_0 = 0` every week (weekly
/// harvest cycle — ADR-0010 §3).
///
/// Empty-day interpretation: days within the week with NO logged
/// entries are NOT folded as zero. Spec §2.3 defines `S_day` only when
/// the user logs on that day; folding zero would bias `H` toward 0
/// over time, which is incorrect (a missing day means "no signal", not
/// "neutral"). Only days with entries contribute to the EWMA.
class ComputeGardenStateUseCase {
  const ComputeGardenStateUseCase();

  /// Number of cells in the daily-score strip. Public so widget tests
  /// can reference it without hard-coding a magic number.
  static const int weeklyWindow = 7;

  GardenState call({
    required List<MoodEntry> entries,
    required DateTime now,
    required DateTime weekStart,
  }) {
    // Bucket every entry by its local-midnight day key. We hold the raw
    // mood-score values per day so we can compute both the per-day mean
    // (for the strip + EWMA) and today's atmosphere from the same source.
    final byDay = <DateTime, List<double>>{};
    for (final entry in entries) {
      final day = localMidnight(entry.createdAt);
      final score = computeMoodScore(entry.mood, entry.intensity).value;
      (byDay[day] ??= <double>[]).add(score);
    }

    final today = localMidnight(now);
    final weekStartDay = localMidnight(weekStart);

    // EWMA fold over the current week. Walk forward in chronological
    // order; only days with entries contribute (see class docstring on
    // empty-day interpretation).
    final weekDailyMeans = <double>[];
    for (
      var d = weekStartDay;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))
    ) {
      final scores = byDay[d];
      if (scores == null || scores.isEmpty) continue;
      weekDailyMeans.add(_mean(scores));
    }
    final gardenHealth = foldGardenHealthEwma(weekDailyMeans);
    final tier = PlantTier.fromHealth(gardenHealth);

    // Today's atmosphere: mean of today's per-entry scores.
    final todayScores = byDay[today] ?? const <double>[];
    final atmosphere = atmosphere_service.computeAtmosphere(todayScores);

    // Last-7-days strip, newest first. Days with no entry surface as
    // `(avgScore: null, entryCount: 0)` so the widget can render the
    // empty-cell treatment without a separate enum.
    final last7Days = <DayScore>[
      for (var i = 0; i < weeklyWindow; i += 1)
        () {
          final day = today.subtract(Duration(days: i));
          final scores = byDay[day];
          if (scores == null || scores.isEmpty) {
            return DayScore(day: day, avgScore: null, entryCount: 0);
          }
          return DayScore(
            day: day,
            avgScore: _mean(scores),
            entryCount: scores.length,
          );
        }(),
    ];

    return GardenState(
      gardenHealth: gardenHealth,
      plantTier: tier,
      atmosphere: atmosphere,
      last7Days: last7Days,
      totalEntryCount: entries.length,
    );
  }

  static double _mean(List<double> xs) {
    var sum = 0.0;
    for (final x in xs) {
      sum += x;
    }
    return sum / xs.length;
  }
}
