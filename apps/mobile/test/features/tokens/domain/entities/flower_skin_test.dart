import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/flower_skin.dart';

void main() {
  group('FlowerSkin — entity', () {
    test('equality is value-based', () {
      const a = FlowerSkin(
        skinId: 'sunflower_sunset',
        species: FlowerSpecies.sunflower,
        displayName: 'Sunset Sunflower',
        cost: 50,
        isDefault: false,
        paletteSeed: 12,
      );
      const b = FlowerSkin(
        skinId: 'sunflower_sunset',
        species: FlowerSpecies.sunflower,
        displayName: 'Sunset Sunflower',
        cost: 50,
        isDefault: false,
        paletteSeed: 12,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith updates the requested field only', () {
      const a = FlowerSkin(
        skinId: 'lavender_meadow',
        species: FlowerSpecies.lavender,
        displayName: 'Meadow Lavender',
        cost: 150,
        isDefault: false,
        paletteSeed: 44,
      );
      final b = a.copyWith(cost: 120);
      expect(b.cost, 120);
      expect(b.skinId, a.skinId);
      expect(b.species, a.species);
      expect(b.displayName, a.displayName);
      expect(b.isDefault, a.isDefault);
      expect(b.paletteSeed, a.paletteSeed);
    });

    test('JSON round-trip preserves every field', () {
      const original = FlowerSkin(
        skinId: 'fern_forest',
        species: FlowerSpecies.fern,
        displayName: 'Forest Fern',
        cost: 50,
        isDefault: false,
        paletteSeed: 9,
      );
      final json = original.toJson();
      final restored = FlowerSkin.fromJson(json);
      expect(restored, equals(original));
    });

    test('defaults serialize correctly with cost 0', () {
      const original = FlowerSkin(
        skinId: 'daisy_default',
        species: FlowerSpecies.daisy,
        displayName: 'Classic Daisy',
        cost: 0,
        isDefault: true,
        paletteSeed: 0,
      );
      final json = original.toJson();
      expect(json['cost'], 0);
      expect(json['isDefault'], true);
      expect(json['species'], 'daisy');
      final restored = FlowerSkin.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
