import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('FlowerSpecies.forMood', () {
    test('happy → sunflower', () {
      expect(FlowerSpecies.forMood(MoodType.happy), FlowerSpecies.sunflower);
    });

    test('sad → forgetMeNot', () {
      expect(FlowerSpecies.forMood(MoodType.sad), FlowerSpecies.forgetMeNot);
    });

    test('okay → daisy', () {
      expect(FlowerSpecies.forMood(MoodType.okay), FlowerSpecies.daisy);
    });

    test('angry → poppy', () {
      expect(FlowerSpecies.forMood(MoodType.angry), FlowerSpecies.poppy);
    });

    test('anxious → fern', () {
      expect(FlowerSpecies.forMood(MoodType.anxious), FlowerSpecies.fern);
    });

    test('calm → lavender', () {
      expect(FlowerSpecies.forMood(MoodType.calm), FlowerSpecies.lavender);
    });

    test('mapping is exhaustive — every MoodType maps to a distinct species, '
        'and all six species are reachable', () {
      final reached = MoodType.values.map(FlowerSpecies.forMood).toSet();
      // All six species reachable — no mood collapses onto another's
      // species.
      expect(reached, FlowerSpecies.values.toSet());
      expect(reached.length, 6);
    });
  });
}
