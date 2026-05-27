import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'garden_skin.freezed.dart';
part 'garden_skin.g.dart';

/// One of the five global garden skins. Buying a skin re-themes every
/// plant in the garden at once - this is not per-species. Cosmetic only;
/// never gates therapeutic features.
///
/// `cost == 0` is the free default (Meadow). Locked skins set
/// [requiresFlourishingTier] = true and surface as "Keep growing" on the
/// Skin Shop until the user reaches Flourishing.
///
/// Pure Dart on purpose. The skin painter implementation lives in
/// `packages/design_system/lib/src/widgets/mb_skin_plants.dart` and is
/// resolved at the presentation edge via the shared [GardenSkinId] enum.
@freezed
abstract class GardenSkin with _$GardenSkin {
  const factory GardenSkin({
    required GardenSkinId id,
    required String displayName,
    required String tagline,
    required int cost,
    @Default(false) bool requiresFlourishingTier,
  }) = _GardenSkin;

  factory GardenSkin.fromJson(Map<String, Object?> json) =>
      _$GardenSkinFromJson(json);
}
