import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../garden/domain/entities/flower_species.dart';

part 'per_species_skin_state.freezed.dart';

/// User's per-species skin pool + current per-species selection.
///
/// This is the SECOND skin model, additive to the global `SkinState`. The
/// two are persisted to separate Firestore fields and never overwrite one
/// another (global -> `unlockedSkinIds`/`equippedSkinId`; per-species ->
/// `perSpeciesSkins`).
///
/// Both maps are keyed by [FlowerSpecies]:
///   * [unlocked] - the set of owned per-species skin ids for that
///     species (empty when the user only has the built-in default).
///   * [equipped] - the id the user has equipped for that species. Absent
///     means "no per-species override" - the global skin / default wins
///     (see the rendering precedence in `resolve_species_accent.dart`).
///
/// Pure Dart. The data layer maps this to/from the nested `perSpeciesSkins`
/// map field on `users/{uid}`.
@freezed
abstract class PerSpeciesSkinState with _$PerSpeciesSkinState {
  const PerSpeciesSkinState._();

  const factory PerSpeciesSkinState({
    required Map<FlowerSpecies, Set<String>> unlocked,
    required Map<FlowerSpecies, String> equipped,
  }) = _PerSpeciesSkinState;

  /// Fresh-user state: nothing unlocked, nothing equipped per-species.
  /// Every species renders on its built-in default until the user buys
  /// an alternate.
  factory PerSpeciesSkinState.initial() => const PerSpeciesSkinState(
    unlocked: <FlowerSpecies, Set<String>>{},
    equipped: <FlowerSpecies, String>{},
  );

  /// `true` when [skinId] is in the owned pool for [species].
  bool isUnlocked(FlowerSpecies species, String skinId) =>
      unlocked[species]?.contains(skinId) ?? false;

  /// The id the user has equipped for [species], or `null` when no
  /// per-species override is active (global / default wins).
  String? equippedFor(FlowerSpecies species) => equipped[species];
}
