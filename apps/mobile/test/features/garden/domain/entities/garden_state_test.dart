import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';

void main() {
  group('GardenState (ADR-0010 ecosystem shape)', () {
    final today = DateTime(2026, 4, 29);
    final yesterday = today.subtract(const Duration(days: 1));

    GardenState makeState({
      double gardenHealth = 0,
      PlantTier plantTier = PlantTier.resting,
      Atmosphere atmosphere = Atmosphere.calmSunny,
      int totalEntryCount = 0,
    }) => GardenState(
      gardenHealth: gardenHealth,
      plantTier: plantTier,
      atmosphere: atmosphere,
      last7Days: [
        DayScore(day: today, avgScore: null, entryCount: 0),
        DayScore(day: yesterday, avgScore: null, entryCount: 0),
      ],
      totalEntryCount: totalEntryCount,
    );

    test('isEmpty is true when totalEntryCount is 0', () {
      expect(makeState().isEmpty, isTrue);
    });

    test('isEmpty is false when at least one entry has been logged', () {
      expect(makeState(totalEntryCount: 1).isEmpty, isFalse);
    });

    test('GardenState with no entries → tier=resting, atmosphere=calmSunny, '
        'all last7Days null', () {
      final s = GardenState(
        gardenHealth: 0,
        plantTier: PlantTier.resting,
        atmosphere: Atmosphere.calmSunny,
        last7Days: [
          for (var i = 0; i < 7; i += 1)
            DayScore(
              day: today.subtract(Duration(days: i)),
              avgScore: null,
              entryCount: 0,
            ),
        ],
        totalEntryCount: 0,
      );

      expect(s.isEmpty, isTrue);
      expect(s.plantTier, PlantTier.resting);
      expect(s.atmosphere, Atmosphere.calmSunny);
      expect(s.last7Days, hasLength(7));
      expect(s.last7Days.every((d) => d.avgScore == null), isTrue);
      expect(s.last7Days.every((d) => d.entryCount == 0), isTrue);
    });

    test('two equal states compare equal (Freezed value equality)', () {
      final a = makeState(
        gardenHealth: 0.2,
        plantTier: PlantTier.thriving,
        totalEntryCount: 3,
      );
      final b = makeState(
        gardenHealth: 0.2,
        plantTier: PlantTier.thriving,
        totalEntryCount: 3,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith mutates only the named field', () {
      final a = makeState(
        gardenHealth: 0.2,
        plantTier: PlantTier.thriving,
        totalEntryCount: 3,
      );
      final b = a.copyWith(plantTier: PlantTier.flourishing);
      expect(b.plantTier, PlantTier.flourishing);
      expect(b.gardenHealth, 0.2);
      expect(b.totalEntryCount, 3);
      expect(b.last7Days, equals(a.last7Days));
    });
  });

  group('DayScore', () {
    test('equality is value-based', () {
      final a = DayScore(
        day: DateTime(2026, 4, 29),
        avgScore: 0.4,
        entryCount: 2,
      );
      final b = DayScore(
        day: DateTime(2026, 4, 29),
        avgScore: 0.4,
        entryCount: 2,
      );
      expect(a, equals(b));
    });

    test('null avgScore distinguishes "no entries" from "neutral"', () {
      final empty = DayScore(
        day: DateTime(2026, 4, 29),
        avgScore: null,
        entryCount: 0,
      );
      final logged = DayScore(
        day: DateTime(2026, 4, 29),
        avgScore: 0,
        entryCount: 1,
      );
      expect(empty, isNot(equals(logged)));
    });
  });
}
