import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';

void main() {
  group('SkinState — pool + selection', () {
    test('empty() has no entries', () {
      final s = SkinState.empty();
      expect(s.unlockedBySpecies, isEmpty);
      expect(s.selectedBySpecies, isEmpty);
      expect(s.isUnlocked(FlowerSpecies.sunflower, 'whatever'), isFalse);
      expect(s.selectedFor(FlowerSpecies.sunflower), isNull);
    });

    test('isUnlocked reflects pool membership only', () {
      const s = SkinState(
        unlockedBySpecies: {
          FlowerSpecies.sunflower: {'sunflower_sunset'},
        },
        selectedBySpecies: {FlowerSpecies.sunflower: 'sunflower_sunset'},
      );
      expect(s.isUnlocked(FlowerSpecies.sunflower, 'sunflower_sunset'), isTrue);
      expect(s.isUnlocked(FlowerSpecies.sunflower, 'sunflower_moonlit'), isFalse);
      // Cross-species lookup never leaks.
      expect(s.isUnlocked(FlowerSpecies.lavender, 'sunflower_sunset'), isFalse);
    });

    test('selectedFor returns null when no explicit selection', () {
      const s = SkinState(
        unlockedBySpecies: {
          FlowerSpecies.sunflower: {'sunflower_sunset'},
        },
        // Note: pool entry without a selection.
        selectedBySpecies: {},
      );
      expect(s.selectedFor(FlowerSpecies.sunflower), isNull);
    });
  });
}
