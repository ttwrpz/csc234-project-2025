import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';

/// Pure-Dart invariants for the v1.6 global SkinState.
void main() {
  group('SkinState.initial', () {
    test('fresh-user state has Meadow equipped and Meadow in the pool', () {
      final state = SkinState.initial();

      expect(
        state.equippedSkinId,
        equals(GardenSkinId.meadow),
        reason: 'Meadow is the default for a fresh user',
      );
      expect(
        state.unlockedSkinIds,
        equals(<GardenSkinId>{GardenSkinId.meadow}),
        reason:
            'a brand-new account owns exactly one skin (Meadow); the rest '
            'are unlocked via the Skin Shop',
      );
    });

    test('isUnlocked agrees with the underlying set', () {
      final state = SkinState.initial();
      expect(state.isUnlocked(GardenSkinId.meadow), isTrue);
      expect(state.isUnlocked(GardenSkinId.origami), isFalse);
      expect(state.isUnlocked(GardenSkinId.lantern), isFalse);
      expect(state.isUnlocked(GardenSkinId.constellation), isFalse);
      expect(state.isUnlocked(GardenSkinId.crystal), isFalse);
    });
  });

  group('SkinState.isUnlocked', () {
    test('returns true only for ids in the unlocked pool', () {
      const state = SkinState(
        equippedSkinId: GardenSkinId.origami,
        unlockedSkinIds: <GardenSkinId>{
          GardenSkinId.meadow,
          GardenSkinId.origami,
        },
      );
      expect(state.isUnlocked(GardenSkinId.meadow), isTrue);
      expect(state.isUnlocked(GardenSkinId.origami), isTrue);
      expect(state.isUnlocked(GardenSkinId.lantern), isFalse);
      expect(state.isUnlocked(GardenSkinId.constellation), isFalse);
      expect(state.isUnlocked(GardenSkinId.crystal), isFalse);
    });
  });

  group('SkinState equality', () {
    test('two states with the same equipped id + pool are equal', () {
      const a = SkinState(
        equippedSkinId: GardenSkinId.meadow,
        unlockedSkinIds: <GardenSkinId>{GardenSkinId.meadow},
      );
      const b = SkinState(
        equippedSkinId: GardenSkinId.meadow,
        unlockedSkinIds: <GardenSkinId>{GardenSkinId.meadow},
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different equipped ids yield unequal states', () {
      const a = SkinState(
        equippedSkinId: GardenSkinId.meadow,
        unlockedSkinIds: <GardenSkinId>{
          GardenSkinId.meadow,
          GardenSkinId.origami,
        },
      );
      const b = SkinState(
        equippedSkinId: GardenSkinId.origami,
        unlockedSkinIds: <GardenSkinId>{
          GardenSkinId.meadow,
          GardenSkinId.origami,
        },
      );
      expect(a, isNot(equals(b)));
    });
  });
}
