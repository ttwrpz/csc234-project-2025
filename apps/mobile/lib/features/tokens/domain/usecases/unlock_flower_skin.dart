import 'package:core/core.dart';

import '../entities/flower_skin.dart';
import '../entities/skin_state.dart';
import '../repositories/skin_repository.dart';
import '../services/skin_catalog.dart';
import '../skin_failure.dart';

/// Use case for spending N tokens to unlock + activate a flower skin.
///
/// Pure-Dart orchestration over [SkinRepository]; controllers invoke
/// this use case rather than the repository directly so the
/// "validate inputs → call repo → return Result" sequence is one
/// testable unit.
///
/// Validation done here (before any network call):
///   * `skin` must be in the catalog (rejects stale/forged skinIds).
///   * `skin.isDefault == false` (defaults are always available without
///     purchase — calling this use case with a default skin would debit
///     the user 0 tokens but still bump the field count; it's safer to
///     surface it as "already unlocked").
///   * `skin.skinId` must not already be in the user's pool.
///
/// The atomic balance-debit + pool-append + selection-write happens
/// inside [SkinRepository.unlockAndSelect] (single Firestore
/// transaction). This use case never reads the balance directly — the
/// repo's transaction is the canonical "did this succeed" boundary so
/// a stale local SkinState never racing-wins against the live doc.
class UnlockFlowerSkinUseCase {
  const UnlockFlowerSkinUseCase(this._repo);

  final SkinRepository _repo;

  Future<Result<SkinState, SkinFailure>> call({
    required String userId,
    required FlowerSkin skin,
    required SkinState currentState,
  }) async {
    if (userId.isEmpty) {
      return const Err(SkinFailure.network());
    }

    final catalogHit = SkinCatalog.byId(skin.skinId);
    if (catalogHit == null) {
      return Err(SkinFailure.unknownSkin(skin.skinId));
    }
    // The caller might pass a stale copy of the skin entity — trust the
    // catalog for pricing + species so the user can't accidentally
    // (or maliciously) unlock at a cached lower price.
    final canonical = catalogHit;

    if (canonical.isDefault) {
      // Defaults are NEVER purchased. Surface as already-unlocked rather
      // than network so the modal's "Already owned" affordance still
      // fires cleanly.
      return const Err(SkinFailure.alreadyUnlocked());
    }

    if (currentState.isUnlocked(canonical.species, canonical.skinId)) {
      return const Err(SkinFailure.alreadyUnlocked());
    }

    return _repo.unlockAndSelect(userId: userId, skin: canonical);
  }
}
