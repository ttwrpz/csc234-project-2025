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
import 'mappers/mood_drift_mapper.dart';
import 'mappers/mood_entry_mapper.dart';
import 'mood_repository_impl.dart';
import 'sync/connectivity_provider.dart';
import 'sync/mood_sync_manager.dart';

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

final moodEntryMapperProvider = Provider<MoodEntryMapper>(
  (ref) => const MoodEntryMapper(),
);

final moodDriftMapperProvider = Provider<MoodDriftMapper>(
  (ref) => const MoodDriftMapper(),
);

/// Feature flag for the offline-first cutover (PR-3). Default `true` — the
/// repository routes reads + writes through Drift and the sync queue. Override
/// to `false` (e.g., in `main.dart`'s shell or via Remote Config wiring) to
/// fall back to the pre-PR-3 Firestore-only path. Reversible without a hotfix.
final offlineFirstEnabledProvider = Provider<bool>((_) => true);

/// Sync manager singleton. PR-2 wires it; PR-3 will have the repository call
/// `kick()` after every enqueue. Disposed via `ref.onDispose`, so sign-out
/// (which tears down the auth scope) cleans the listener and timers.
///
/// Note: `ref.watch(connectivityProvider.stream)` returns a broadcast
/// `Stream<bool>` of `[true|false]` events. The provider's initial Async-loading
/// state is squelched — the manager defaults `_isOnline = true` so the first
/// drain after boot proceeds; the listener corrects within milliseconds.
final moodSyncManagerProvider = Provider<MoodSyncManager>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw StateError(
      'moodSyncManagerProvider read before sharedPreferencesProvider resolved. '
      'Await `ref.read(sharedPreferencesProvider.future)` upstream first.',
    );
  }
  final manager = MoodSyncManager(
    moodDao: ref.watch(moodDaoProvider),
    syncQueueDao: ref.watch(syncQueueDaoProvider),
    remote: ref.watch(moodFirestoreDatasourceProvider),
    mapper: ref.watch(moodEntryMapperProvider),
    // Riverpod 3 will replace `.stream`; until then it is the documented way
    // to expose a StreamProvider's raw Stream to plain-Dart consumers like
    // MoodSyncManager.
    // ignore: deprecated_member_use
    connectivity: ref.watch(connectivityProvider.stream),
    deviceIdGetter: () =>
        ref.read(deviceIdProvider).valueOrNull ?? 'unknown-device',
    prefs: prefs,
  );
  ref.onDispose(() async => manager.shutdown());
  return manager;
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepositoryImpl(
    datasource: ref.watch(moodFirestoreDatasourceProvider),
    moodDao: ref.watch(moodDaoProvider),
    syncQueueDao: ref.watch(syncQueueDaoProvider),
    syncManager: ref.watch(moodSyncManagerProvider),
    deviceIdGetter: () =>
        ref.read(deviceIdProvider).valueOrNull ?? 'unknown-device',
    offlineFirstEnabled: () => ref.read(offlineFirstEnabledProvider),
    mapper: ref.watch(moodEntryMapperProvider),
    driftMapper: ref.watch(moodDriftMapperProvider),
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
