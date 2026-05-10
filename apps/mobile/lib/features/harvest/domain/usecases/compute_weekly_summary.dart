import '../../../garden/domain/entities/plant_tier.dart';
import '../../../mood/domain/entities/mood_entry.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../../../mood/domain/services/mood_score.dart';
import '../entities/weekly_garden.dart';

/// Computes a [WeeklySummary] from a week's entries + per-day Garden
/// Health history (HB-005 Track 6.1).
///
/// Pure-Dart, no I/O. Stateless — instantiated as a const value. The
/// archive use case calls this once per harvest; tests can also exercise
/// the math standalone.
///
/// `averageMoodScore` is the mean of `MoodScore.value` across every
/// entry; range [-1, +1]. With no entries the value is `0.0` (the
/// archive use case rejects empty weeks before this point, so the zero
/// fallback only matters for unit tests).
///
/// `moodCounts` is the per-emotion histogram across the week — the
/// presentation layer reads the top-3 keys from this map.
///
/// `endingPlantTier` is `PlantTier.fromHealth(dailyHealthHistory.last)`,
/// or [PlantTier.resting] when the list is empty (week with no logs
/// would never reach `endingPlantTier`, but the fallback keeps the
/// function total).
///
/// `triggeredTierCount` is passed through verbatim — the caller pulls
/// it from `patterns/{date}.triggeredTier != null` over the week, since
/// the use case has no Firestore handle.
class ComputeWeeklySummaryUseCase {
  const ComputeWeeklySummaryUseCase();

  WeeklySummary call({
    required List<MoodEntry> weekEntries,
    required List<double> dailyHealthHistory,
    required int triggeredTierCount,
  }) {
    final avg = _averageMoodScore(weekEntries);
    final counts = _moodCounts(weekEntries);
    final endingTier = dailyHealthHistory.isEmpty
        ? PlantTier.resting
        : PlantTier.fromHealth(dailyHealthHistory.last);

    return WeeklySummary(
      averageMoodScore: avg,
      moodCounts: counts,
      endingPlantTier: endingTier,
      totalEntryCount: weekEntries.length,
      triggeredTierCount: triggeredTierCount,
    );
  }

  double _averageMoodScore(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<double>(
      0.0,
      (acc, e) => acc + computeMoodScore(e.mood, e.intensity).value,
    );
    return sum / entries.length;
  }

  Map<MoodType, int> _moodCounts(List<MoodEntry> entries) {
    final counts = <MoodType, int>{};
    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts;
  }
}
