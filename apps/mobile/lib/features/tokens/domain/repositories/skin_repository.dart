import 'package:core/core.dart';

import '../../../garden/domain/entities/flower_species.dart';
import '../entities/flower_skin.dart';
import '../entities/skin_state.dart';
import '../skin_failure.dart';

/// Contract for any backing store that persists the user's flower-skin
/// pool + selection — TC-6 through TC-10 (HB-008 Day 1).
///
/// Implementations live in `data/` and may use Firestore or a fake.
/// The concrete implementation maps to two top-level fields on
/// `users/{uid}`:
///   * `unlockedSkins: map<emotion, [skinId]>` — already in the schema
///     (CLAUDE.md "Firestore data model"), per-species set of owned
///     non-default skinIds.
///   * `selectedSkins: map<emotion, skinId>` — new in S5, per-species
///     active selection. Absent species fall back to the built-in
///     default at render time.
///
/// [unlockAndSelect] runs as a SINGLE Firestore transaction that:
///   1. Reads `tokenBalance` + `unlockedSkins[species]`.
///   2. Asserts the balance is ≥ cost and the skinId is not already
///      unlocked.
///   3. Writes `tokenBalance -= cost`, appends skinId to
///      `unlockedSkins[species]`, AND sets `selectedSkins[species] =
///      skinId` — all in one atomic update so a partial write can never
///      leave a debited balance with no skin to show for it.
///
/// Pure-Dart contract — imports only `package:core/core.dart` and
/// sibling domain types. Domain-purity rule per CLAUDE.md.
abstract class SkinRepository {
  /// Streams the user's current skin pool + selection map. Emits a
  /// fresh [SkinState] every time the user-doc changes (unlock, select,
  /// or token award racing the spend).
  Stream<SkinState> watchSkinState({required String userId});

  /// Atomically debits the user's token balance by `skin.cost`,
  /// appends `skin.skinId` to `unlockedSkins[skin.species]`, AND sets
  /// `selectedSkins[skin.species] = skin.skinId` so the freshly-bought
  /// skin becomes active on the next render (TC-6).
  ///
  /// Returns [SkinFailure.insufficientTokens] when the live balance is
  /// below `skin.cost`, [SkinFailure.alreadyUnlocked] when the skinId
  /// is already in the pool (idempotency guard), and the usual
  /// network/permissionDenied/unknown shapes from CLAUDE.md.
  Future<Result<SkinState, SkinFailure>> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  });

  /// Sets `selectedSkins[species] = skinId` without touching the
  /// unlocked pool or the token balance. Caller asserts the skin is
  /// already in the pool (or is the species default); the impl trusts
  /// the caller — defense-in-depth lives in the modal's affordance
  /// state, not in this repository (a malicious actor would just write
  /// the field directly via Firestore SDK).
  Future<Result<SkinState, SkinFailure>> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  });
}
