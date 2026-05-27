import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/per_species_skin_state.dart';
import '../domain/entities/skin_state.dart';
import '../domain/entities/token_balance.dart';
import '../domain/repositories/per_species_skin_repository.dart';
import '../domain/repositories/skin_repository.dart';
import '../domain/repositories/token_repository.dart';
import '../domain/usecases/unlock_garden_skin.dart';
import '../domain/usecases/unlock_per_species_skin.dart';
import 'datasources/per_species_skin_firestore_datasource.dart';
import 'datasources/skin_firestore_datasource.dart';
import 'datasources/token_balance_firestore_datasource.dart';
import 'repositories/per_species_skin_repository_impl.dart';
import 'repositories/skin_repository_impl.dart';
import 'repositories/token_repository_impl.dart';

/// Riverpod wiring for the token-economy feature.
///
/// The repository provider lives here (data layer) because the domain
/// layer must not import `package:flutter_riverpod` per CLAUDE.md's
/// domain-purity rule. The pure-Dart [awardDailyTokens] function is
/// invoked inside the datasource transaction — no provider needed.

/// Thin Firestore datasource for the three token-economy fields on the
/// `users/{uid}` profile doc. Tests fake this provider via
/// `overrideWithValue` to avoid spinning up a real `FirebaseFirestore`.
final tokenBalanceFirestoreDatasourceProvider =
    Provider<TokenBalanceFirestoreDatasource>(
      (ref) => TokenBalanceFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [TokenRepository]. Wraps the datasource and maps
/// `FirebaseException` codes to `TokenFailure`. Best-effort writes —
/// failures are logged + swallowed by the post-save controller.
final tokenRepositoryProvider = Provider<TokenRepository>(
  (ref) => TokenRepositoryImpl(
    datasource: ref.watch(tokenBalanceFirestoreDatasourceProvider),
  ),
);

/// Live token-balance stream for the signed-in user. Emits a fresh
/// [TokenBalance] every time the user-doc changes (token award, future
/// skin-purchase write, etc).
///
/// Returns [AsyncValue.loading] before auth resolves and a synthetic
/// fresh-user balance once a `null` user emits — the garden chip is
/// only rendered for signed-in users so the loading branch is a
/// presentation no-op.
final tokenBalanceStreamProvider = StreamProvider<TokenBalance>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return const Stream<TokenBalance>.empty();
  }
  return ref.watch(tokenRepositoryProvider).watchBalance(userId: user.uid);
});

// ───── Skin economy ─────

/// Firestore datasource for the two global-skin fields
/// (`unlockedSkinIds`, `equippedSkinId`) on the `users/{uid}` profile
/// doc. Tests override via `overrideWithValue` to avoid spinning up a
/// real `FirebaseFirestore`.
final skinFirestoreDatasourceProvider = Provider<SkinFirestoreDatasource>(
  (ref) => SkinFirestoreDatasource(ref.watch(firestoreProvider)),
);

/// Firestore-backed [SkinRepository]. Wraps the datasource and maps
/// `FirebaseException` codes + in-transaction sentinels to [SkinFailure].
final skinRepositoryProvider = Provider<SkinRepository>(
  (ref) => SkinRepositoryImpl(
    datasource: ref.watch(skinFirestoreDatasourceProvider),
  ),
);

/// Use case that validates the unlock invariants (not the default,
/// not already owned, balance is enough) before delegating to the
/// repo's atomic transaction. Controllers (Skin Shop confirm tap)
/// invoke this, never the repository directly.
final unlockGardenSkinUseCaseProvider = Provider<UnlockGardenSkinUseCase>(
  (ref) => UnlockGardenSkinUseCase(ref.watch(skinRepositoryProvider)),
);

/// Live skin-state stream (pool + equipped id) for the signed-in user.
/// Emits a fresh [SkinState] every time the user-doc changes. Returns
/// the fresh-user state when no user is signed in - the Skin Shop is
/// only reachable for signed-in users so the empty branch is a
/// presentation no-op.
final skinStateStreamProvider = StreamProvider<SkinState>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return Stream<SkinState>.value(SkinState.initial());
  }
  return ref.watch(skinRepositoryProvider).watchSkinState(userId: user.uid);
});

// ───── Per-species skin economy (additive to the global skins above) ─────

/// Firestore datasource for the single nested `perSpeciesSkins` field on
/// the `users/{uid}` profile doc. Disjoint from the global-skin fields.
/// Tests override via `overrideWithValue` to avoid a real `Firestore`.
final perSpeciesSkinFirestoreDatasourceProvider =
    Provider<PerSpeciesSkinFirestoreDatasource>(
      (ref) => PerSpeciesSkinFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [PerSpeciesSkinRepository]. Wraps the datasource and
/// maps `FirebaseException` codes + in-transaction sentinels to
/// `SkinFailure` (the same failure type the global model uses).
final perSpeciesSkinRepositoryProvider = Provider<PerSpeciesSkinRepository>(
  (ref) => PerSpeciesSkinRepositoryImpl(
    datasource: ref.watch(perSpeciesSkinFirestoreDatasourceProvider),
  ),
);

/// Use case that validates the per-species unlock invariants (not
/// already owned, balance is enough) before delegating to the repo's
/// atomic transaction. The per-species Skin Shop section invokes this.
final unlockPerSpeciesSkinUseCaseProvider =
    Provider<UnlockPerSpeciesSkinUseCase>(
      (ref) => UnlockPerSpeciesSkinUseCase(
        ref.watch(perSpeciesSkinRepositoryProvider),
      ),
    );

/// Live per-species skin-state stream for the signed-in user. Emits a
/// fresh [PerSpeciesSkinState] on every user-doc change. Returns the
/// fresh-user state when no user is signed in (the Skin Shop is only
/// reachable when signed in, so the empty branch is a no-op).
final perSpeciesSkinStateStreamProvider = StreamProvider<PerSpeciesSkinState>((
  ref,
) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return Stream<PerSpeciesSkinState>.value(PerSpeciesSkinState.initial());
  }
  return ref
      .watch(perSpeciesSkinRepositoryProvider)
      .watchState(userId: user.uid);
});
