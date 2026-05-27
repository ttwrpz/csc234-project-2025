import 'package:core/core.dart';
import 'package:design_system/design_system.dart' show GardenSkinId;

import '../entities/skin_state.dart';
import '../repositories/skin_repository.dart';
import '../services/garden_skin_catalog.dart';
import '../skin_failure.dart';

/// Use case for spending tokens to unlock + equip a global garden skin.
///
/// Pure Dart orchestration. Controllers call this; the repository's
/// atomic Firestore transaction is the canonical "did this succeed"
/// boundary so a stale local [SkinState] never races against the live
/// doc.
///
/// Validation done before any network call:
///   * `id` resolves in the catalog. (All five enum values do today,
///     but the guard is defensive.)
///   * The skin is not the free default (Meadow) - that's always
///     unlocked, never purchased.
///   * The skin is not already in the user's pool.
///   * The user has enough tokens (cheaper client-side check; the
///     in-transaction guard still runs server-side).
///
/// "Reach Flourishing tier" gating is enforced at the presentation
/// layer (the Skin Shop card surfaces "Keep growing" for locked skins);
/// the use case treats it as a normal purchase if the controller asks
/// for it.
class UnlockGardenSkinUseCase {
  const UnlockGardenSkinUseCase(this._repo);

  final SkinRepository _repo;

  Future<Result<SkinState, SkinFailure>> call({
    required String userId,
    required GardenSkinId id,
    required SkinState currentState,
    required int currentBalance,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }

    final skin = GardenSkinCatalog.byId(id);

    if (skin.cost == 0) {
      // Defaults are NEVER purchased.
      return const Err(SkinFailure.alreadyUnlocked());
    }

    if (currentState.isUnlocked(id)) {
      return const Err(SkinFailure.alreadyUnlocked());
    }

    if (currentBalance < skin.cost) {
      return Err(
        SkinFailure.insufficientTokens(
          required: skin.cost,
          available: currentBalance,
        ),
      );
    }

    return _repo.unlockAndEquip(userId: userId, skin: skin);
  }
}
