import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/services/per_species_skin_catalog.dart';

/// Pure-Dart invariants for the additive per-species skin catalog.
void main() {
  group('PerSpeciesSkinCatalog invariants', () {
    test('every species has exactly six variants', () {
      for (final species in FlowerSpecies.values) {
        expect(
          PerSpeciesSkinCatalog.forSpecies(species).length,
          equals(6),
          reason: '$species should offer exactly six per-species variants',
        );
      }
    });

    test('catalog has 36 skins total (6 species x 6)', () {
      expect(PerSpeciesSkinCatalog.all.length, equals(36));
    });

    test('every species variant 1 is the classic meadow style', () {
      for (final species in FlowerSpecies.values) {
        expect(
          PerSpeciesSkinCatalog.forSpecies(species).first.style,
          equals(GardenSkinId.meadow),
          reason: '$species first variant should be the classic meadow shape',
        );
      }
    });

    test('every variant declares a non-null shape style', () {
      for (final skin in PerSpeciesSkinCatalog.all) {
        expect(GardenSkinId.values.contains(skin.style), isTrue);
      }
    });

    test('all ids are unique', () {
      final ids = PerSpeciesSkinCatalog.all.map((s) => s.id).toSet();
      expect(ids.length, equals(PerSpeciesSkinCatalog.all.length));
    });

    test('every id is prefixed with its species name', () {
      for (final skin in PerSpeciesSkinCatalog.all) {
        expect(
          skin.id.startsWith(skin.species.name),
          isTrue,
          reason: '${skin.id} must be prefixed with ${skin.species.name}',
        );
      }
    });

    test('every cost is positive (no free per-species defaults)', () {
      for (final skin in PerSpeciesSkinCatalog.all) {
        expect(skin.cost, greaterThan(0), reason: '${skin.id} cost');
      }
    });

    test('costs stay within the cheaper per-species band (<= global min)', () {
      // The global catalog spans 12..40; per-species accents are the
      // cheaper granular tier and must not exceed the cheapest global
      // skin (12) so they read as the lighter-weight personalisation.
      for (final skin in PerSpeciesSkinCatalog.all) {
        expect(skin.cost, lessThanOrEqualTo(12), reason: '${skin.id} cost');
      }
    });

    test('every accent ARGB is fully opaque', () {
      for (final skin in PerSpeciesSkinCatalog.all) {
        final alpha = (skin.accentArgb >> 24) & 0xFF;
        expect(alpha, equals(0xFF), reason: '${skin.id} should be opaque');
      }
    });

    test('taglines contain no em-dashes (CLAUDE.md copy rule)', () {
      for (final skin in PerSpeciesSkinCatalog.all) {
        expect(skin.tagline.contains('-'), isFalse, reason: skin.id);
        expect(skin.displayName.contains('-'), isFalse, reason: skin.id);
      }
    });
  });

  group('PerSpeciesSkinCatalog lookup', () {
    test('byId resolves a known id', () {
      final skin = PerSpeciesSkinCatalog.byId('sunflower_goldenHour');
      expect(skin, isNotNull);
      expect(skin?.species, FlowerSpecies.sunflower);
    });

    test('byId returns null for an unknown id', () {
      expect(PerSpeciesSkinCatalog.byId('not_a_real_skin'), isNull);
    });

    test('forSpecies only returns that species skins', () {
      final poppy = PerSpeciesSkinCatalog.forSpecies(FlowerSpecies.poppy);
      expect(poppy, isNotEmpty);
      expect(poppy.every((s) => s.species == FlowerSpecies.poppy), isTrue);
    });
  });
}
