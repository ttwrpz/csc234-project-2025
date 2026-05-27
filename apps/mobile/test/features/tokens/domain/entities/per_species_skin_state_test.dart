import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/per_species_skin_state.dart';

/// Pure-Dart invariants for the additive per-species skin state.
void main() {
  group('PerSpeciesSkinState.initial', () {
    test('fresh-user state owns and equips nothing per-species', () {
      final state = PerSpeciesSkinState.initial();
      expect(state.unlocked, isEmpty);
      expect(state.equipped, isEmpty);
    });

    test('equippedFor returns null for every species when fresh', () {
      final state = PerSpeciesSkinState.initial();
      for (final species in FlowerSpecies.values) {
        expect(state.equippedFor(species), isNull);
      }
    });

    test('isUnlocked is false for any id when fresh', () {
      final state = PerSpeciesSkinState.initial();
      expect(state.isUnlocked(FlowerSpecies.sunflower, 'anything'), isFalse);
    });
  });

  group('PerSpeciesSkinState queries', () {
    const state = PerSpeciesSkinState(
      unlocked: <FlowerSpecies, Set<String>>{
        FlowerSpecies.sunflower: {'sunflower_goldenHour'},
      },
      equipped: <FlowerSpecies, String>{
        FlowerSpecies.sunflower: 'sunflower_goldenHour',
      },
    );

    test('isUnlocked is true only for owned ids of that species', () {
      expect(
        state.isUnlocked(FlowerSpecies.sunflower, 'sunflower_goldenHour'),
        isTrue,
      );
      expect(
        state.isUnlocked(FlowerSpecies.sunflower, 'sunflower_butter'),
        isFalse,
      );
      // Owning a sunflower skin must NOT leak across species.
      expect(
        state.isUnlocked(FlowerSpecies.poppy, 'sunflower_goldenHour'),
        isFalse,
      );
    });

    test('equippedFor returns the equipped id for that species only', () {
      expect(
        state.equippedFor(FlowerSpecies.sunflower),
        'sunflower_goldenHour',
      );
      expect(state.equippedFor(FlowerSpecies.poppy), isNull);
    });
  });

  group('PerSpeciesSkinState equality', () {
    test('equal maps yield equal states', () {
      const a = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.daisy: {'daisy_blush'},
        },
        equipped: <FlowerSpecies, String>{FlowerSpecies.daisy: 'daisy_blush'},
      );
      const b = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.daisy: {'daisy_blush'},
        },
        equipped: <FlowerSpecies, String>{FlowerSpecies.daisy: 'daisy_blush'},
      );
      expect(a, equals(b));
    });
  });
}
