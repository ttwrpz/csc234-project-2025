import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/mood_failure.dart';
import '../domain/mood_repository.dart';
import '../domain/usecases/save_mood_entry.dart';
import '../domain/usecases/watch_my_moods.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'local/mood_dao.dart';
import 'local/sync_queue_dao.dart';
import 'mood_repository_impl.dart';

// PR-1 wires the DAOs as Riverpod providers but does NOT change the
// repository wiring. PR-2 (sync manager) and PR-3 (repo cutover) consume
// these. Until PR-3 lands, `moodRepositoryProvider` keeps routing through
// the Firestore datasource — no behavior change at the UI layer.
final moodDaoProvider = Provider<MoodDao>(
  (ref) => ref.watch(databaseProvider).moodDao,
);
final syncQueueDaoProvider = Provider<SyncQueueDao>(
  (ref) => ref.watch(databaseProvider).syncQueueDao,
);

final moodFirestoreDatasourceProvider = Provider<MoodFirestoreDatasource>((
  ref,
) {
  return MoodFirestoreDatasource(ref.watch(firestoreProvider));
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepositoryImpl(
    datasource: ref.watch(moodFirestoreDatasourceProvider),
  );
});

// Use case providers — domain classes themselves are pure Dart; only the
// Riverpod providers (which need flutter_riverpod) live here.

final saveMoodEntryUseCaseProvider = Provider<SaveMoodEntryUseCase>((ref) {
  return SaveMoodEntryUseCase(repository: ref.watch(moodRepositoryProvider));
});

final watchMyMoodsUseCaseProvider = Provider<WatchMyMoodsUseCase>((ref) {
  return WatchMyMoodsUseCase(repository: ref.watch(moodRepositoryProvider));
});

/// Stream of the signed-in user's mood entries, ordered newest-first.
/// Returns an empty stream when no user is signed in (router guarantees this
/// won't happen in practice, but defense-in-depth).
final myMoodsStreamProvider = StreamProvider<List<MoodEntry>>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(watchMyMoodsUseCaseProvider)(userId: user.uid);
});

/// Single-entry lookup for the detail screen.
final moodEntryByIdProvider = FutureProvider.family<MoodEntry?, String>((
  ref,
  id,
) async {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return null;
  final result = await ref
      .watch(moodRepositoryProvider)
      .findById(userId: user.uid, id: id);
  return switch (result) {
    Ok(:final value) => value,
    Err<MoodEntry, MoodFailure>() => null,
  };
});
