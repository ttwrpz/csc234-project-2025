import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/services/skin_catalog.dart';

void main() {
  group('SkinCatalog — read-only catalogue', () {
    test('every species has exactly one default skin', () {
      for (final species in FlowerSpecies.values) {
        final defaults = SkinCatalog.forSpecies(
          species,
        ).where((s) => s.isDefault).toList(growable: false);
        expect(
          defaults,
          hasLength(1),
          reason: 'species ${species.name} must have exactly one default',
        );
        expect(defaults.single.cost, 0);
        expect(SkinCatalog.defaultFor(species), defaults.single);
      }
    });

    test('every species has at least one alternate skin', () {
      // Modal renders defaults + alternates per species. A species with
      // only its default would surface as a "nothing to customize" row,
      // which the v1.0 design forbids.
      for (final species in FlowerSpecies.values) {
        final alternates = SkinCatalog.forSpecies(
          species,
        ).where((s) => !s.isDefault).toList(growable: false);
        expect(
          alternates,
          isNotEmpty,
          reason: 'species ${species.name} must have at least one alternate',
        );
      }
    });

    test('alternate costs are within the published tiers', () {
      // Spec §5 — token economy is uniform; no bespoke pricing. The
      // catalog file uses three tiers (50 / 100 / 150). Any new tier
      // would land via a deliberate change to this test.
      const allowedCosts = {0, 50, 100, 150};
      for (final skin in SkinCatalog.all()) {
        expect(
          allowedCosts.contains(skin.cost),
          isTrue,
          reason: 'skin ${skin.skinId} has out-of-tier cost ${skin.cost}',
        );
      }
    });

    test('byId returns the catalogue skin when present, null otherwise', () {
      final hit = SkinCatalog.byId('sunflower_sunset');
      expect(hit, isNotNull);
      expect(hit!.species, FlowerSpecies.sunflower);
      expect(hit.isDefault, isFalse);

      expect(SkinCatalog.byId('does_not_exist'), isNull);
    });

    test('all skinIds are unique across the catalogue', () {
      final ids = SkinCatalog.all()
          .map((s) => s.skinId)
          .toList(growable: false);
      expect(ids.toSet().length, equals(ids.length));
    });

    test('displayNames carry no mood/emotion words (spec §5)', () {
      // Names must be visual descriptors only. The modal would
      // otherwise imply "Cheerful Sunflower unlocks when happy", which
      // is the mood-contingent-rewards anti-pattern.
      const forbidden = [
        'happy',
        'sad',
        'angry',
        'anxious',
        'depressed',
        'calm',
        'okay',
        'cheerful',
        'gloomy',
      ];
      for (final skin in SkinCatalog.all()) {
        final lower = skin.displayName.toLowerCase();
        for (final word in forbidden) {
          expect(
            lower.contains(word),
            isFalse,
            reason:
                'skin ${skin.skinId} displayName "${skin.displayName}" '
                'contains forbidden mood word "$word"',
          );
        }
      }
    });
  });
}
