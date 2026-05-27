import 'package:core/core.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../entities/per_species_skin.dart';
import '../entities/per_species_skin_state.dart';
import '../skin_failure.dart';

/// Contract for the store that persists the user's PER-SPECIES skin pool
/// + per-species selection. Additive to [SkinRepository] (global skins);
/// the two write disjoint Firestore fields and never collide.
///
/// The concrete impl writes a single nested field on `users/{uid}`:
///   * `perSpeciesSkins` - a `map` keyed by species name, each value
///     carrying an `unlocked` id list and an optional `equipped` id. The
///     global `unlockedSkinIds` / `equippedSkinId` fields are left
///     untouched.
///
/// [unlockAndEquip] runs as a SINGLE Firestore transaction mirroring the
/// global [SkinRepository.unlockAndEquip]:
///   1. Reads `tokenBalance` + the species' current `unlocked` list.
///   2. Asserts balance >= cost AND the skin is not already unlocked.
///   3. Writes `tokenBalance -= cost`, appends the new id to that
///      species' `unlocked` list, AND sets that species' `equipped` to
///      the new id - all atomically.
///
/// Pure-Dart contract. Imports only `package:core/core.dart` and sibling
/// domain types.
abstract class PerSpeciesSkinRepository {
  /// Streams the user's current per-species pool + selection.
  Stream<PerSpeciesSkinState> watchState({required String userId});

  /// Atomically debits `skin.cost`, adds `skin.id` to the unlocked set
  /// for `skin.species`, AND equips it for that species.
  Future<Result<PerSpeciesSkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required PerSpeciesSkin skin,
  });

  /// Sets the equipped per-species skin for [species] to [skinId] (or
  /// clears it when [skinId] is `null`) without touching the unlocked
  /// pool or the token balance. Caller asserts the skin is already owned.
  Future<Result<PerSpeciesSkinState, SkinFailure>> equip({
    required String userId,
    required FlowerSpecies species,
    required String? skinId,
  });
}
