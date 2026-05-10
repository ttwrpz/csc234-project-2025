import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/token_balance.dart';
import '../domain/repositories/token_repository.dart';
import 'datasources/token_balance_firestore_datasource.dart';
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
