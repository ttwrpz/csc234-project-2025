import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/domain/services/garden_skin_catalog.dart';

/// Pins the v1.6 global skin catalog. The Skin Shop, the unlock use
/// case, and the migration path all read this catalog as the single
/// source of truth, so its invariants are load-bearing.
void main() {
  group('GardenSkinCatalog.all', () {
    test('contains exactly the five v1.6 skins', () {
      expect(GardenSkinCatalog.all, hasLength(5));
      expect(
        GardenSkinCatalog.all.map((s) => s.id).toList(),
        equals(<GardenSkinId>[
          GardenSkinId.meadow,
          GardenSkinId.origami,
          GardenSkinId.lantern,
          GardenSkinId.constellation,
          GardenSkinId.crystal,
        ]),
        reason:
            'catalog order is contractual - the Skin Shop card row '
            'and the migration default both depend on meadow being first',
      );
    });

    test('meadow is the default - free, first, never gated', () {
      final meadow = GardenSkinCatalog.byId(GardenSkinId.meadow);
      expect(meadow.cost, equals(0), reason: 'Meadow is the free default');
      expect(meadow.requiresFlourishingTier, isFalse);
      expect(GardenSkinCatalog.defaultSkin.id, equals(GardenSkinId.meadow));
      expect(GardenSkinCatalog.all.first.id, equals(GardenSkinId.meadow));
    });

    test('crystal is gated behind the Flourishing tier', () {
      final crystal = GardenSkinCatalog.byId(GardenSkinId.crystal);
      expect(
        crystal.requiresFlourishingTier,
        isTrue,
        reason:
            'Crystal is the only skin gated behind the Flourishing tier - '
            'the Skin Shop surfaces "Keep growing" for this skin until '
            'the user crosses the tier threshold',
      );
    });

    test('costs are monotonically increasing across the catalog', () {
      final costs = GardenSkinCatalog.all.map((s) => s.cost).toList();
      for (var i = 1; i < costs.length; i++) {
        expect(
          costs[i],
          greaterThanOrEqualTo(costs[i - 1]),
          reason:
              'skin costs must grow (or stay flat for free defaults) so the '
              'Skin Shop progression reads as a ladder; failure at index $i: '
              '${costs[i - 1]} -> ${costs[i]}',
        );
      }
    });

    test('canonical prices match the v1.6 spec', () {
      // The prototype's `skin-shop.jsx` pins these prices; the unlock
      // use case and the purchase confirm modal show them verbatim,
      // so a silent drift would surface as a UI regression at the
      // very last moment.
      expect(GardenSkinCatalog.byId(GardenSkinId.meadow).cost, 0);
      expect(GardenSkinCatalog.byId(GardenSkinId.origami).cost, 12);
      expect(GardenSkinCatalog.byId(GardenSkinId.lantern).cost, 20);
      expect(GardenSkinCatalog.byId(GardenSkinId.constellation).cost, 30);
      expect(GardenSkinCatalog.byId(GardenSkinId.crystal).cost, 40);
    });

    test('every catalog entry has non-empty displayName + tagline', () {
      for (final skin in GardenSkinCatalog.all) {
        expect(
          skin.displayName.trim(),
          isNotEmpty,
          reason: '${skin.id} displayName must be non-empty for the shop card',
        );
        expect(
          skin.tagline.trim(),
          isNotEmpty,
          reason: '${skin.id} tagline must be non-empty for the shop card',
        );
      }
    });

    test('tagline copy uses hyphens not em-dashes', () {
      // CLAUDE.md project-wide rule: no em-dashes in user-facing copy.
      // Catch a drift if a future contributor pastes copy from a
      // rich-text source.
      for (final skin in GardenSkinCatalog.all) {
        expect(
          skin.tagline.contains('—'),
          isFalse,
          reason:
              '${skin.id} tagline contains an em-dash (U+2014). '
              'Use hyphens. Tagline: "${skin.tagline}"',
        );
      }
    });
  });

  group('GardenSkinCatalog.byId', () {
    test('resolves every enum value without throwing', () {
      for (final id in GardenSkinId.values) {
        final skin = GardenSkinCatalog.byId(id);
        expect(
          skin.id,
          equals(id),
          reason: 'byId($id) must return the matching skin entity',
        );
      }
    });
  });
}
