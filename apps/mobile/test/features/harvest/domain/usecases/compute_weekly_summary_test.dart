import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/domain/usecases/compute_weekly_summary.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

MoodEntry _entry({
  required MoodType mood,
  required int intensity,
  String id = 'e',
  DateTime? createdAt,
}) => MoodEntry(
  id: id,
  userId: 'u1',
  mood: mood,
  intensity: intensity,
  text: '',
  createdAt: createdAt ?? DateTime(2026, 5, 6, 12),
);

void main() {
  const useCase = ComputeWeeklySummaryUseCase();

  group('averageMoodScore', () {
    test('is the mean of MoodScore.value across the week', () {
      // Joy×5 = +1.0, Sad×5 = -1.0, Joy×4 = +0.8 → mean = 0.2666…
      final summary = useCase(
        weekEntries: [
          _entry(mood: MoodType.happy, intensity: 5, id: 'a'),
          _entry(mood: MoodType.sad, intensity: 5, id: 'b'),
          _entry(mood: MoodType.happy, intensity: 4, id: 'c'),
        ],
        dailyHealthHistory: const [0.0, 0.12, 0.10],
        triggeredTierCount: 0,
      );
      expect(summary.averageMoodScore, closeTo(0.2666, 0.001));
      expect(summary.totalEntryCount, 3);
    });

    test('is 0.0 with no entries (defensive — caller rejects empty week)', () {
      final summary = useCase(
        weekEntries: const [],
        dailyHealthHistory: const [],
        triggeredTierCount: 0,
      );
      expect(summary.averageMoodScore, 0.0);
      expect(summary.totalEntryCount, 0);
    });
  });

  group('moodCounts', () {
    test('counts entries per MoodType', () {
      final summary = useCase(
        weekEntries: [
          _entry(mood: MoodType.happy, intensity: 5, id: 'a'),
          _entry(mood: MoodType.happy, intensity: 3, id: 'b'),
          _entry(mood: MoodType.happy, intensity: 1, id: 'c'),
          _entry(mood: MoodType.sad, intensity: 4, id: 'd'),
          _entry(mood: MoodType.sad, intensity: 2, id: 'e'),
          _entry(mood: MoodType.calm, intensity: 5, id: 'f'),
        ],
        dailyHealthHistory: const [0.1],
        triggeredTierCount: 0,
      );
      expect(summary.moodCounts[MoodType.happy], 3);
      expect(summary.moodCounts[MoodType.sad], 2);
      expect(summary.moodCounts[MoodType.calm], 1);
      // Unobserved moods are absent from the map (consumers default to 0).
      expect(summary.moodCounts.containsKey(MoodType.angry), isFalse);
    });

    test('returns empty map when no entries are logged', () {
      final summary = useCase(
        weekEntries: const [],
        dailyHealthHistory: const [],
        triggeredTierCount: 0,
      );
      expect(summary.moodCounts, isEmpty);
    });
  });

  group('endingPlantTier', () {
    test('reads PlantTier.fromHealth on the LAST element of the history', () {
      final summary = useCase(
        weekEntries: [_entry(mood: MoodType.happy, intensity: 5)],
        dailyHealthHistory: const [0.0, 0.12, 0.20, 0.32, 0.45],
        triggeredTierCount: 0,
      );
      // 0.45 ≥ 0.4 → flourishing.
      expect(summary.endingPlantTier, PlantTier.flourishing);
    });

    test('falls back to PlantTier.resting on empty history', () {
      final summary = useCase(
        weekEntries: [_entry(mood: MoodType.happy, intensity: 5)],
        dailyHealthHistory: const [],
        triggeredTierCount: 0,
      );
      expect(summary.endingPlantTier, PlantTier.resting);
    });

    test('storm season tier when ending health ≤ -0.4', () {
      final summary = useCase(
        weekEntries: [_entry(mood: MoodType.sad, intensity: 5)],
        dailyHealthHistory: const [-0.1, -0.3, -0.5, -0.6],
        triggeredTierCount: 0,
      );
      expect(summary.endingPlantTier, PlantTier.stormSeason);
    });
  });

  group('triggeredTierCount', () {
    test('passes through verbatim — caller pulls from patterns docs', () {
      final summary = useCase(
        weekEntries: [_entry(mood: MoodType.happy, intensity: 5)],
        dailyHealthHistory: const [0.1],
        triggeredTierCount: 3,
      );
      expect(summary.triggeredTierCount, 3);
    });
  });
}
