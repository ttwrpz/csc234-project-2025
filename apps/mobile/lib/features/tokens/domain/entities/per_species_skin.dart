import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../garden/domain/entities/flower_species.dart';

part 'per_species_skin.freezed.dart';
part 'per_species_skin.g.dart';

/// One purchasable alternate skin for a SINGLE flower species (e.g. a
/// crystal sunflower). This is a SECOND, additive skin model layered on
/// top of the five GLOBAL [GardenSkin]s - the two coexist by product
/// decision. A per-species skin overrides only its own species' plant
/// (its shape [style] AND accent colour); the global skin still drives
/// every other species.
///
/// Each per-species skin pairs a shape [style] - one of the five global
/// skin shape-languages (meadow / origami / lantern / constellation /
/// crystal) - with an [accentArgb] tint. The "classic" first variant per
/// species uses [GardenSkinId.meadow]; the rest are genuinely distinct
/// shapes drawn by the shared `MbSkinPlant` painters, scoped to one
/// species.
///
/// Cosmetic only; never gates therapeutic features.
///
/// Pure Dart on purpose (mirrors [GardenSkin]). The accent is stored as a
/// raw ARGB `int` rather than a `dart:ui` `Color` so the entity stays
/// importable from the domain layer with zero Flutter dependency. The
/// presentation edge converts it to a `Color` when painting.
@freezed
abstract class PerSpeciesSkin with _$PerSpeciesSkin {
  const factory PerSpeciesSkin({
    /// Stable slug, unique across all species. Format `<species>_<name>`,
    /// e.g. `sunflower_crystal`. Persisted verbatim to Firestore.
    required String id,
    required FlowerSpecies species,
    required String displayName,
    required String tagline,
    required int cost,

    /// Shape language this skin paints the species in - one of the five
    /// `MbSkinPlant` styles. `meadow` is the classic silhouette.
    required GardenSkinId style,

    /// Petal/bud accent colour as a 32-bit ARGB int (e.g. `0xFFF2A93B`).
    /// The garden painter applies this in place of the species' built-in
    /// petal colour when this skin is equipped.
    required int accentArgb,
  }) = _PerSpeciesSkin;

  factory PerSpeciesSkin.fromJson(Map<String, Object?> json) =>
      _$PerSpeciesSkinFromJson(json);
}
