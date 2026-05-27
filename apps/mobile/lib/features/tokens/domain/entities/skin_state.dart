import 'package:design_system/design_system.dart' show GardenSkinId;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'skin_state.freezed.dart';

/// User's global skin pool + current selection.
///
/// `equippedSkinId` - the skin currently re-theming the garden. Always
/// non-null. `unlockedSkinIds` - the set of owned skin ids. Meadow is
/// always in this set (every user owns it by default).
///
/// Pure Dart. The data layer maps this to/from the flat
/// `unlockedSkinIds` + `equippedSkinId` fields on `users/{uid}` (see
/// `SkinFirestoreDatasource`).
@freezed
abstract class SkinState with _$SkinState {
  const SkinState._();

  const factory SkinState({
    required GardenSkinId equippedSkinId,
    required Set<GardenSkinId> unlockedSkinIds,
  }) = _SkinState;

  /// Fresh-user state: Meadow equipped, Meadow unlocked. Used during the
  /// short window between sign-up and the first profile-doc write, and
  /// any time the datasource reads a doc with the old per-species
  /// `unlockedSkins` map (the Phase 12 migration is a "fresh start" -
  /// see the datasource comment for rationale).
  factory SkinState.initial() => const SkinState(
    equippedSkinId: GardenSkinId.meadow,
    unlockedSkinIds: <GardenSkinId>{GardenSkinId.meadow},
  );

  /// `true` when [id] is in the user's pool.
  bool isUnlocked(GardenSkinId id) => unlockedSkinIds.contains(id);
}
