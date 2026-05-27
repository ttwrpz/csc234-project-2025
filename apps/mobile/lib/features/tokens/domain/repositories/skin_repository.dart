import 'package:core/core.dart';
import 'package:design_system/design_system.dart' show GardenSkinId;

import '../entities/garden_skin.dart';
import '../entities/skin_state.dart';
import '../skin_failure.dart';

/// Contract for any backing store that persists the user's global skin
/// pool + current selection.
///
/// Implementations live in `data/` and may use Firestore or a fake.
/// The concrete impl writes two top-level fields on `users/{uid}`:
///   * `unlockedSkinIds` - `List<String>`: the user's owned skin ids
///     (always includes "meadow"; defaults are listed too so the doc
///     is self-describing for migrations).
///   * `equippedSkinId` - `String`: the currently active skin id.
///
/// [unlockAndEquip] runs as a SINGLE Firestore transaction that:
///   1. Reads `tokenBalance` + `unlockedSkinIds`.
///   2. Asserts balance >= cost AND the skin is not already unlocked.
///   3. Writes `tokenBalance -= cost`, appends the new id to
///      `unlockedSkinIds`, AND sets `equippedSkinId` to the new id -
///      all in one atomic update.
///
/// Pure-Dart contract. Imports only `package:core/core.dart`, the
/// design system enum, and sibling domain types.
abstract class SkinRepository {
  /// Streams the user's current pool + selection. Emits a fresh
  /// [SkinState] every time the user-doc changes (unlock, equip, or a
  /// token award racing the spend).
  Stream<SkinState> watchSkinState({required String userId});

  /// Atomically debits `skin.cost`, adds `skin.id` to the unlocked set,
  /// AND sets `equippedSkinId = skin.id`.
  Future<Result<SkinState, SkinFailure>> unlockAndEquip({
    required String userId,
    required GardenSkin skin,
  });

  /// Sets `equippedSkinId = id` without touching the unlocked pool or
  /// the token balance. Caller asserts the skin is already in the pool;
  /// the modal's affordance state is the canonical guard.
  Future<Result<SkinState, SkinFailure>> equip({
    required String userId,
    required GardenSkinId id,
  });
}
