import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';
import 'package:moodbloom/features/harvest/domain/entities/weekly_garden.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('WeeklySummary JSON round-trip', () {
    test('preserves every field including the moodCounts map', () {
      const summary = WeeklySummary(
        averageMoodScore: 0.32,
        moodCounts: {MoodType.happy: 4, MoodType.calm: 2, MoodType.sad: 1},
        endingPlantTier: PlantTier.thriving,
        totalEntryCount: 7,
        triggeredTierCount: 1,
      );

      final json = summary.toJson();
      final round = WeeklySummary.fromJson(json);

      expect(round, summary);
      expect(round.moodCounts[MoodType.happy], 4);
      expect(round.moodCounts[MoodType.sad], 1);
      expect(round.endingPlantTier, PlantTier.thriving);
    });

    test('round-trips an empty moodCounts map', () {
      const summary = WeeklySummary(
        averageMoodScore: 0.0,
        moodCounts: <MoodType, int>{},
        endingPlantTier: PlantTier.resting,
        totalEntryCount: 0,
        triggeredTierCount: 0,
      );

      expect(WeeklySummary.fromJson(summary.toJson()), summary);
    });
  });

  group('WeeklyGarden JSON round-trip', () {
    test('preserves every field across serialisation', () {
      final entry = MoodEntry(
        id: 'entry-1',
        userId: 'uid-1',
        mood: MoodType.happy,
        intensity: 4,
        text: '',
        createdAt: DateTime.utc(2026, 5, 6, 12),
      );
      final garden = WeeklyGarden(
        weekId: '2026-W19',
        weekStart: DateTime.utc(2026, 5, 4),
        weekEnd: DateTime.utc(2026, 5, 11),
        entries: [entry],
        healthHistory: const [0.0, 0.12, 0.10, 0.08, 0.06, 0.05, 0.04],
        summary: WeeklySummary(
          averageMoodScore: 0.8,
          moodCounts: const {MoodType.happy: 1},
          endingPlantTier: PlantTier.flourishing,
          totalEntryCount: 1,
          triggeredTierCount: 0,
        ),
        archivedAt: DateTime.utc(2026, 5, 11, 0, 0, 1),
      );

      // Round-trip through JSON encode/decode so nested Freezed objects
      // are flattened to maps the same way Firestore would. Without
      // jsonEncode the List<MoodEntry> reference is preserved verbatim
      // and `fromJson` would throw on the cast - this matches the
      // production path (Firestore ↔ Map<String, dynamic>).
      final json =
          jsonDecode(jsonEncode(garden.toJson())) as Map<String, Object?>;
      final round = WeeklyGarden.fromJson(json);

      expect(round.weekId, '2026-W19');
      expect(round.entries.single, entry);
      expect(round.healthHistory, garden.healthHistory);
      expect(round.summary, garden.summary);
      expect(round.archivedAt, garden.archivedAt);
      expect(round.schemaV, 1);
    });

    test('defaults schemaV to 1 when absent in JSON', () {
      final json = {
        'weekId': '2026-W19',
        'weekStart': DateTime.utc(2026, 5, 4).toIso8601String(),
        'weekEnd': DateTime.utc(2026, 5, 11).toIso8601String(),
        'entries': <Map<String, Object?>>[],
        'healthHistory': <double>[],
        'summary': const WeeklySummary(
          averageMoodScore: 0.0,
          moodCounts: <MoodType, int>{},
          endingPlantTier: PlantTier.resting,
          totalEntryCount: 0,
          triggeredTierCount: 0,
        ).toJson(),
        'archivedAt': DateTime.utc(2026, 5, 11).toIso8601String(),
      };

      final garden = WeeklyGarden.fromJson(json);
      expect(garden.schemaV, 1);
    });
  });
}
