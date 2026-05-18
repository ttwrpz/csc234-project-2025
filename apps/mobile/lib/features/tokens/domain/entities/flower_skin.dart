import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../garden/domain/entities/flower_species.dart';

part 'flower_skin.freezed.dart';
part 'flower_skin.g.dart';

/// One purchasable (or default) skin variant for a [FlowerSpecies].
///
/// Skins are cosmetic-only — pivot feature #10 (CLAUDE.md), spec §5.
/// Buying a skin never unlocks therapeutic features, never changes how
/// pattern detection or interventions work; it only swaps the paint
/// strategy used by the per-species painter.
///
/// `isDefault: true` means the skin is the species' built-in sprite
/// (always available, never gated). `cost == 0` for defaults; alternate
/// skins are priced in tokens.
///
/// Pure Dart on purpose — no `package:flutter` imports — so the entity
/// can be unit-tested without spinning up a widget tree. The actual
/// per-skin painting lives in `presentation/widgets/skin_preview.dart`
/// (which interprets [paletteSeed] when rendering).
/// Petal geometry kind for a [FlowerSkin]. v1.6 — drives a non-color
/// visual differentiator so alternate skins read distinctly across the
/// modal grid and the garden bed, not just as palette swaps. All
/// existing skins ship as `classic` (the species' canonical petal shape)
/// for byte-for-byte rendering parity.
enum FlowerPetalShape { classic, rounded, pointed, star, heart }

@freezed
abstract class FlowerSkin with _$FlowerSkin {
  const factory FlowerSkin({
    required String skinId,
    required FlowerSpecies species,
    required String displayName,
    required int cost,
    required bool isDefault,
    required int paletteSeed,
    @Default(FlowerPetalShape.classic) FlowerPetalShape petalShape,
  }) = _FlowerSkin;

  factory FlowerSkin.fromJson(Map<String, Object?> json) =>
      _$FlowerSkinFromJson(json);
}
