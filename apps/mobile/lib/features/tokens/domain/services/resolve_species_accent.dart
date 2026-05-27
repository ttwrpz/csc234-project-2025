import 'package:design_system/design_system.dart' show GardenSkinId;

import '../../../garden/domain/entities/flower_species.dart';
import '../entities/per_species_skin_state.dart';
import 'per_species_skin_catalog.dart';

/// Pure-Dart resolver for which accent (if any) a given flower species
/// should paint with, given both skin models active at once.
///
/// PRECEDENCE (highest wins), per species S:
///   1. PER-SPECIES skin equipped for S -> use that skin's accent ARGB.
///   2. else GLOBAL skin equipped (non-meadow) -> defer to the global
///      skin painter (return `null` here; the caller renders the global
///      [GardenSkinId] silhouette/palette via `MbSkinPlant`). We return
///      `null` rather than a colour because the global skins are full
///      alternate painters, not a single accent colour.
///   3. else (Meadow / no skin) -> the species' built-in default colour
///      (return `null`; the caller paints the classic species palette).
///
/// So a non-null return means "a per-species override is active - paint
/// the species' normal silhouette but swap the petal accent to this
/// ARGB". A null return means "no per-species override - fall through to
/// the global skin path (or the default)".
///
/// The two skin systems coexist cleanly: per-species accents only ever
/// ADD a colour override on top, and only for the species the user
/// explicitly bought an alternate for. Every other species follows the
/// global skin exactly as before.
/// Resolved render config for one species' plant: which shape [style]
/// to paint it in, and an optional [accentArgb] tint (non-null only when
/// a per-species skin is equipped for that species).
typedef ResolvedPlantSkin = ({GardenSkinId style, int? accentArgb});

class ResolveSpeciesAccent {
  const ResolveSpeciesAccent._();

  /// Resolves the shape style + accent for [species] under both skin
  /// models. Precedence:
  ///   1. PER-SPECIES skin equipped -> that skin's `style` + `accentArgb`.
  ///   2. else -> the GLOBAL equipped style (may be `meadow`), no accent
  ///      (the caller tints with the mood's palette colour).
  static ResolvedPlantSkin resolveFor({
    required FlowerSpecies species,
    required PerSpeciesSkinState perSpecies,
    required GardenSkinId globalEquipped,
  }) {
    final equippedId = perSpecies.equippedFor(species);
    if (equippedId != null) {
      final skin = PerSpeciesSkinCatalog.byId(equippedId);
      if (skin != null) {
        return (style: skin.style, accentArgb: skin.accentArgb);
      }
    }
    return (style: globalEquipped, accentArgb: null);
  }

  /// Returns the per-species accent ARGB for [species], or `null` when no
  /// per-species override applies (rules 2 and 3 above). [globalEquipped]
  /// is accepted so the precedence is explicit at the call site even
  /// though only rule 1 produces a non-null result today.
  static int? accentArgbFor({
    required FlowerSpecies species,
    required PerSpeciesSkinState perSpecies,
    required GardenSkinId globalEquipped,
  }) {
    final equippedId = perSpecies.equippedFor(species);
    if (equippedId == null) return null;
    final skin = PerSpeciesSkinCatalog.byId(equippedId);
    return skin?.accentArgb;
  }

  /// Builds the full `species -> accent ARGB` map for every species that
  /// has a per-species override active. Species with no override are
  /// omitted so the caller's fallback (global / default) stays in force.
  static Map<FlowerSpecies, int> accentMap({
    required PerSpeciesSkinState perSpecies,
    required GardenSkinId globalEquipped,
  }) {
    final out = <FlowerSpecies, int>{};
    for (final species in FlowerSpecies.values) {
      final argb = accentArgbFor(
        species: species,
        perSpecies: perSpecies,
        globalEquipped: globalEquipped,
      );
      if (argb != null) out[species] = argb;
    }
    return out;
  }
}
