import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../garden/domain/entities/flower_species.dart';

part 'per_species_skin.freezed.dart';
part 'per_species_skin.g.dart';

/// One purchasable alternate skin for a SINGLE flower species (e.g. a
/// golden-hour sunflower). This is a SECOND, additive skin model layered
/// on top of the five GLOBAL [GardenSkin]s - the two coexist by product
/// decision. A per-species skin re-tints only its own species' plant;
/// the global skin still drives every other species (and the silhouette
/// for this species too - per-species skins are an accent-colour overlay,
/// not a new painter).
///
/// `cost == 0` would be a free default, but the catalog has none - every
/// species starts on the built-in default colour, with at least one paid
/// alternate. Cosmetic only; never gates therapeutic features.
///
/// Pure Dart on purpose (mirrors [GardenSkin]). The accent is stored as a
/// raw ARGB `int` rather than a `dart:ui` `Color` so the entity stays
/// importable from the domain layer with zero Flutter dependency. The
/// presentation edge converts it to a `Color` when painting.
@freezed
abstract class PerSpeciesSkin with _$PerSpeciesSkin {
  const factory PerSpeciesSkin({
    /// Stable slug, unique across all species. Format `<species>_<name>`,
    /// e.g. `sunflower_goldenHour`. Persisted verbatim to Firestore.
    required String id,
    required FlowerSpecies species,
    required String displayName,
    required String tagline,
    required int cost,

    /// Petal/bud accent colour as a 32-bit ARGB int (e.g. `0xFFF2A93B`).
    /// The garden painter applies this in place of the species' built-in
    /// petal colour when this skin is equipped.
    required int accentArgb,
  }) = _PerSpeciesSkin;

  factory PerSpeciesSkin.fromJson(Map<String, Object?> json) =>
      _$PerSpeciesSkinFromJson(json);
}
