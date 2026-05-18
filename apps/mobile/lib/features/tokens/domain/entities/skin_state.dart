import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../garden/domain/entities/flower_species.dart';

part 'skin_state.freezed.dart';

/// User's per-species skin pool + current selection.
///
/// `unlockedBySpecies[species]` is the set of skinIds the user owns for
/// that species (NEVER includes the default — defaults are always
/// available without purchase). `selectedBySpecies[species]` is the
/// skinId currently active for that species' rendering; absent means
/// "use the species default".
///
/// Pure Dart — no Flutter/Firebase imports. The data layer maps this
/// to/from the `unlockedSkins` + `selectedSkins` map fields on the
/// `users/{uid}` profile doc.
@freezed
abstract class SkinState with _$SkinState {
  const SkinState._();

  const factory SkinState({
    required Map<FlowerSpecies, Set<String>> unlockedBySpecies,
    required Map<FlowerSpecies, String> selectedBySpecies,
  }) = _SkinState;

  /// Empty pool — every species defaults to its built-in sprite. Used
  /// before the user has ever unlocked a skin and during the short
  /// window between sign-up and the first profile-doc write.
  factory SkinState.empty() => const SkinState(
    unlockedBySpecies: <FlowerSpecies, Set<String>>{},
    selectedBySpecies: <FlowerSpecies, String>{},
  );

  /// `true` when [skinId] is in the user's pool for [species] (defaults
  /// are NOT considered "unlocked" here — callers check
  /// [FlowerSkin.isDefault] separately when deciding owned-vs-locked).
  bool isUnlocked(FlowerSpecies species, String skinId) =>
      unlockedBySpecies[species]?.contains(skinId) ?? false;

  /// Returns the currently-active skinId for [species], or `null` when
  /// no alternate skin has been selected (caller falls back to the
  /// species default).
  String? selectedFor(FlowerSpecies species) => selectedBySpecies[species];
}
