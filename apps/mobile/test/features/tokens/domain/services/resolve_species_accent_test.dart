import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/domain/entities/per_species_skin_state.dart';
import 'package:moodbloom/features/tokens/domain/services/per_species_skin_catalog.dart';
import 'package:moodbloom/features/tokens/domain/services/resolve_species_accent.dart';

/// Pure-Dart tests for the rendering precedence resolver.
///
/// Precedence (highest wins): per-species skin > global skin > default.
void main() {
  final goldenHour = PerSpeciesSkinCatalog.byId('sunflower_goldenHour')!;

  group('ResolveSpeciesAccent.accentArgbFor', () {
    test('rule 1: per-species skin equipped -> its accent ARGB', () {
      const state = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.sunflower: {'sunflower_goldenHour'},
        },
        equipped: <FlowerSpecies, String>{
          FlowerSpecies.sunflower: 'sunflower_goldenHour',
        },
      );

      final argb = ResolveSpeciesAccent.accentArgbFor(
        species: FlowerSpecies.sunflower,
        perSpecies: state,
        // A global skin is also equipped - per-species must still win.
        globalEquipped: GardenSkinId.origami,
      );
      expect(argb, equals(goldenHour.accentArgb));
    });

    test('rule 2: no per-species override -> null (defer to global)', () {
      final argb = ResolveSpeciesAccent.accentArgbFor(
        species: FlowerSpecies.sunflower,
        perSpecies: PerSpeciesSkinState.initial(),
        globalEquipped: GardenSkinId.lantern,
      );
      expect(argb, isNull);
    });

    test('rule 3: meadow + no per-species -> null (species default)', () {
      final argb = ResolveSpeciesAccent.accentArgbFor(
        species: FlowerSpecies.poppy,
        perSpecies: PerSpeciesSkinState.initial(),
        globalEquipped: GardenSkinId.meadow,
      );
      expect(argb, isNull);
    });

    test('override is scoped to its species only', () {
      const state = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.sunflower: {'sunflower_goldenHour'},
        },
        equipped: <FlowerSpecies, String>{
          FlowerSpecies.sunflower: 'sunflower_goldenHour',
        },
      );
      // The equipped sunflower skin must not affect the poppy.
      expect(
        ResolveSpeciesAccent.accentArgbFor(
          species: FlowerSpecies.poppy,
          perSpecies: state,
          globalEquipped: GardenSkinId.meadow,
        ),
        isNull,
      );
    });

    test('an unknown equipped id resolves to null (forward-compat)', () {
      const state = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.fern: {'fern_fromTheFuture'},
        },
        equipped: <FlowerSpecies, String>{
          FlowerSpecies.fern: 'fern_fromTheFuture',
        },
      );
      expect(
        ResolveSpeciesAccent.accentArgbFor(
          species: FlowerSpecies.fern,
          perSpecies: state,
          globalEquipped: GardenSkinId.meadow,
        ),
        isNull,
      );
    });
  });

  group('ResolveSpeciesAccent.accentMap', () {
    test('only includes species with an active per-species override', () {
      const state = PerSpeciesSkinState(
        unlocked: <FlowerSpecies, Set<String>>{
          FlowerSpecies.sunflower: {'sunflower_goldenHour'},
          FlowerSpecies.lavender: {'lavender_twilight'},
        },
        equipped: <FlowerSpecies, String>{
          FlowerSpecies.sunflower: 'sunflower_goldenHour',
          // Lavender is owned but NOT equipped - must be omitted.
        },
      );

      final map = ResolveSpeciesAccent.accentMap(
        perSpecies: state,
        globalEquipped: GardenSkinId.meadow,
      );
      expect(map.keys, equals({FlowerSpecies.sunflower}));
      expect(map[FlowerSpecies.sunflower], equals(goldenHour.accentArgb));
    });

    test('empty when no per-species overrides are active', () {
      final map = ResolveSpeciesAccent.accentMap(
        perSpecies: PerSpeciesSkinState.initial(),
        globalEquipped: GardenSkinId.crystal,
      );
      expect(map, isEmpty);
    });
  });
}
