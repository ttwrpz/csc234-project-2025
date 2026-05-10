import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/repositories/disclaimer_repository.dart';
import 'datasources/disclaimer_firestore_datasource.dart';
import 'repositories/disclaimer_repository_impl.dart';

/// Riverpod wiring for the bipolar / medical disclaimer service (S5
/// feature 7.4, pulled forward into S4).
///
/// The repository ack-state lives in `users/{uid}.insightsDisclaimerAcked`
/// — a single boolean on the user doc, rule-guarded one-way (false → true
/// only). Tests fake either the datasource OR the repo provider via
/// `overrideWithValue`.

/// Thin Firestore datasource for the
/// `users/{uid}.insightsDisclaimerAcked` boolean. Tests can fake this
/// provider via `overrideWithValue` to avoid spinning up a real
/// `FirebaseFirestore`.
final disclaimerFirestoreDatasourceProvider =
    Provider<DisclaimerFirestoreDatasource>(
      (ref) => DisclaimerFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [DisclaimerRepository]. Wraps the datasource and
/// maps Firestore exceptions to `DisclaimerFailure`.
final disclaimerRepositoryProvider = Provider<DisclaimerRepository>(
  (ref) => DisclaimerRepositoryImpl(
    datasource: ref.watch(disclaimerFirestoreDatasourceProvider),
  ),
);

/// Streams the current user's ack state. Emits `false` when no user is
/// signed in (the S5 Insights screen is rendered after auth, but this
/// provider is also consumed by Settings — the false default keeps the
/// "tap to read more" affordance always discoverable).
final disclaimerAckStreamProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) {
    return Stream.value(false);
  }
  return ref
      .watch(disclaimerRepositoryProvider)
      .watchAckState(userId: user.uid);
});
