import 'package:core/core.dart';

import '../entities/per_species_skin.dart';
import '../entities/per_species_skin_state.dart';
import '../repositories/per_species_skin_repository.dart';
import '../skin_failure.dart';

/// Use case for spending tokens to unlock + equip a PER-SPECIES flower
/// skin. Mirrors [UnlockGardenSkinUseCase] one-for-one so the two skin
/// systems behave identically from the controller's point of view.
///
/// Validation done before any network call:
///   * `userId` is non-empty.
///   * The skin is not already in the user's pool for its species.
///   * The user has enough tokens (cheaper client-side check; the
///     in-transaction guard still runs server-side).
///
/// On success the repository's atomic transaction is the canonical
/// "did this succeed" boundary, so a stale local
/// [PerSpeciesSkinState] never races against the live doc.
class UnlockPerSpeciesSkinUseCase {
  const UnlockPerSpeciesSkinUseCase(this._repo);

  final PerSpeciesSkinRepository _repo;

  Future<Result<PerSpeciesSkinState, SkinFailure>> call({
    required String userId,
    required PerSpeciesSkin skin,
    required PerSpeciesSkinState currentState,
    required int currentBalance,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }

    if (currentState.isUnlocked(skin.species, skin.id)) {
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
