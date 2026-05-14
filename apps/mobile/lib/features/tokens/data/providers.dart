import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/skin_state.dart';
import '../domain/entities/token_balance.dart';
import '../domain/repositories/skin_repository.dart';
import '../domain/repositories/token_repository.dart';
import '../domain/usecases/unlock_flower_skin.dart';
import 'datasources/skin_firestore_datasource.dart';
import 'datasources/token_balance_firestore_datasource.dart';
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

// ───── Skin economy (S5 — HB-008 Day 1) ─────

/// Firestore datasource for the two skin-economy map fields
/// (`unlockedSkins`, `selectedSkins`) on the `users/{uid}` profile doc.
/// Tests override via `overrideWithValue` to avoid spinning up a real
/// `FirebaseFirestore`.
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

/// Use case that validates the unlock invariants (in-catalog skin,
/// not default, not already owned) before delegating to the repo's
/// atomic transaction. Controllers (modal confirm tap) invoke this,
/// never the repository directly.
final unlockFlowerSkinUseCaseProvider = Provider<UnlockFlowerSkinUseCase>(
  (ref) => UnlockFlowerSkinUseCase(ref.watch(skinRepositoryProvider)),
);

/// Live skin-state stream (pool + selection) for the signed-in user.
/// Emits a fresh [SkinState] every time the user-doc changes. Returns
/// an empty pool stream when no user is signed in — the modal is only
/// reachable for signed-in users so the empty branch is a presentation
/// no-op.
final skinStateStreamProvider = StreamProvider<SkinState>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return Stream<SkinState>.value(SkinState.empty());
  }
  return ref.watch(skinRepositoryProvider).watchSkinState(userId: user.uid);
});
