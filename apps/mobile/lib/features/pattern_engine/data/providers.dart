import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/repositories/pattern_repository.dart';
import '../domain/usecases/run_pattern_engine.dart';
import 'datasources/patterns_firestore_datasource.dart';
import 'repositories/pattern_repository_impl.dart';

/// Riverpod wiring for the Pattern Engine.
///
/// The use case provider lives here (data layer) because the domain
/// layer must not import `package:flutter_riverpod` per CLAUDE.md's
/// domain-purity rule. The use case CLASS is pure-Dart and lives in
/// `domain/usecases/run_pattern_engine.dart`; this provider just
/// exposes a const instance for controllers + screens.

/// Pure-Dart [RunPatternEngineUseCase]. Const instance — safe to
/// `overrideWithValue` in tests with a fake.
final runPatternEngineUseCaseProvider = Provider<RunPatternEngineUseCase>(
  (ref) => const RunPatternEngineUseCase(),
);

/// Thin Firestore datasource for the `users/{uid}/patterns/{dateId}`
/// collection. Tests fake this provider via `overrideWithValue` to
/// avoid spinning up a real `FirebaseFirestore`.
final patternsFirestoreDatasourceProvider =
    Provider<PatternsFirestoreDatasource>(
      (ref) => PatternsFirestoreDatasource(ref.watch(firestoreProvider)),
    );

/// Firestore-backed [PatternRepository]. Wraps the datasource and maps
/// Firestore exceptions to `PatternFailure`. Best-effort writes —
/// failures are logged + swallowed by the post-save controller.
final patternRepositoryProvider = Provider<PatternRepository>(
  (ref) => PatternRepositoryImpl(
    datasource: ref.watch(patternsFirestoreDatasourceProvider),
  ),
);
