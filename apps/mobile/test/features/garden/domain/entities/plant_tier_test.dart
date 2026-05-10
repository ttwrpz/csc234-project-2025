import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/plant_tier.dart';

void main() {
  group('PlantTier.fromHealth — boundary cuts (ADR-0010 §4)', () {
    // Boundaries are inclusive at the lower bound — equal-to-threshold
    // moves UP into the higher tier.
    test('h = 0.4 → flourishing (lower bound inclusive)', () {
      expect(PlantTier.fromHealth(0.4), PlantTier.flourishing);
    });

    test('h = 0.39 → thriving (just below flourishing)', () {
      expect(PlantTier.fromHealth(0.39), PlantTier.thriving);
    });

    test('h = 0.1 → thriving (lower bound inclusive)', () {
      expect(PlantTier.fromHealth(0.1), PlantTier.thriving);
    });

    test('h = 0.09 → resting (just below thriving)', () {
      expect(PlantTier.fromHealth(0.09), PlantTier.resting);
    });

    test('h = 0 → resting (neutral mid-band)', () {
      expect(PlantTier.fromHealth(0), PlantTier.resting);
    });

    test('h = -0.09 → resting (just above weathering)', () {
      expect(PlantTier.fromHealth(-0.09), PlantTier.resting);
    });

    test('h = -0.1 → weathering (lower bound inclusive)', () {
      expect(PlantTier.fromHealth(-0.1), PlantTier.weathering);
    });

    test('h = -0.39 → weathering (just above storm)', () {
      expect(PlantTier.fromHealth(-0.39), PlantTier.weathering);
    });

    test('h = -0.4 → stormSeason (lower bound inclusive)', () {
      expect(PlantTier.fromHealth(-0.4), PlantTier.stormSeason);
    });
  });
}
