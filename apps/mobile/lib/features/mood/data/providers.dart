import 'package:cloud_functions/cloud_functions.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/data/datasources/analyze_patterns_functions_datasource.dart';
import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/mood_failure.dart';
import '../domain/mood_repository.dart';
import '../domain/repositories/ai_analysis_repository.dart';
import '../domain/repositories/mood_media_repository.dart';
import '../domain/usecases/analyze_mood_text.dart';
import '../domain/usecases/pick_mood_media.dart';
import '../domain/usecases/save_mood_entry.dart';
import '../domain/usecases/upload_mood_media.dart';
import '../domain/usecases/watch_my_moods.dart';
import 'datasources/ai_analysis_functions_datasource.dart';
import 'datasources/image_picker_datasource.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'datasources/mood_storage_datasource.dart';
import 'local/mood_dao.dart';
import 'local/sync_queue_dao.dart';
import 'mappers/mood_drift_mapper.dart';
import 'mappers/mood_entry_mapper.dart';
import 'mood_repository_impl.dart';
import 'repositories/ai_analysis_repository_impl.dart';
import 'repositories/mood_media_repository_impl.dart';
import 'sync/connectivity_provider.dart';
import 'sync/mood_sync_manager.dart';

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

/// Feature flag for the offline-first path. Default `!kIsWeb` - native
/// targets get the Drift-first read/write path; Web routes through the
/// Firestore-only fallback because Drift's native connector pulls
/// `dart:ffi` which is not available on Web. Override in tests or via
/// Remote Config to flip behaviour at runtime.
final offlineFirstEnabledProvider = Provider<bool>((_) => !kIsWeb);

/// Sync manager singleton. The repository calls `kick()` after every enqueue.
/// Disposed via `ref.onDispose`, so sign-out (which tears down the auth scope)
/// cleans the listener and timers.
final moodSyncManagerProvider = Provider<MoodSyncManager>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final prefs = prefsAsync.value;
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
    // The sibling `connectivityStreamProvider` exposes the raw
    // `Stream<bool>` for plain-Dart consumers like MoodSyncManager.
    connectivity: ref.watch(connectivityStreamProvider),
    deviceIdGetter: () => ref.read(deviceIdProvider).value ?? 'unknown-device',
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
    deviceIdGetter: () => ref.read(deviceIdProvider).value ?? 'unknown-device',
    offlineFirstEnabled: () => ref.read(offlineFirstEnabledProvider),
    mapper: ref.watch(moodEntryMapperProvider),
    driftMapper: ref.watch(moodDriftMapperProvider),
  );
});

// Use case providers - domain classes themselves are pure Dart; only the
// Riverpod providers (which need flutter_riverpod) live here.

final saveMoodEntryUseCaseProvider = Provider<SaveMoodEntryUseCase>((ref) {
  return SaveMoodEntryUseCase(repository: ref.watch(moodRepositoryProvider));
});

final watchMyMoodsUseCaseProvider = Provider<WatchMyMoodsUseCase>((ref) {
  return WatchMyMoodsUseCase(repository: ref.watch(moodRepositoryProvider));
});

// Media - picker + Storage upload. Sibling to the entry repository so mood
// storage can evolve without touching media plumbing.

final imagePickerDatasourceProvider = Provider<ImagePickerDatasource>((ref) {
  return ImagePickerDatasource();
});

final moodStorageDatasourceProvider = Provider<MoodStorageDatasource>((ref) {
  return MoodStorageDatasource(ref.watch(firebaseStorageProvider));
});

final moodMediaRepositoryProvider = Provider<MoodMediaRepository>((ref) {
  return MoodMediaRepositoryImpl(
    picker: ref.watch(imagePickerDatasourceProvider),
    storage: ref.watch(moodStorageDatasourceProvider),
  );
});

final pickMoodMediaUseCaseProvider = Provider<PickMoodMediaUseCase>((ref) {
  return PickMoodMediaUseCase(
    repository: ref.watch(moodMediaRepositoryProvider),
  );
});

final uploadMoodMediaUseCaseProvider = Provider<UploadMoodMediaUseCase>((ref) {
  return UploadMoodMediaUseCase(
    repository: ref.watch(moodMediaRepositoryProvider),
  );
});

/// Stream of the signed-in user's mood entries, ordered newest-first.
/// Returns an empty stream when no user is signed in (router guarantees this
/// won't happen in practice, but defense-in-depth).
final myMoodsStreamProvider = StreamProvider<List<MoodEntry>>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
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
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return null;
  final result = await ref
      .watch(moodRepositoryProvider)
      .findById(userId: user.uid, id: id);
  return switch (result) {
    Ok(:final value) => value,
    Err<MoodEntry, MoodFailure>() => null,
  };
});

// AI analysis providers - `analyzeMoodText` proxy. Region must match the
// function's deploy target (asia-southeast1).

final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
);

final aiAnalysisFunctionsDatasourceProvider =
    Provider<AiAnalysisFunctionsDatasource>(
      (ref) =>
          AiAnalysisFunctionsDatasource(ref.watch(firebaseFunctionsProvider)),
    );

final analyzePatternsFunctionsDatasourceProvider =
    Provider<AnalyzePatternsFunctionsDatasource>(
      (ref) => AnalyzePatternsFunctionsDatasource(
        ref.watch(firebaseFunctionsProvider),
      ),
    );

final aiAnalysisRepositoryProvider = Provider<AIAnalysisRepository>(
  (ref) => AiAnalysisRepositoryImpl(
    datasource: ref.watch(aiAnalysisFunctionsDatasourceProvider),
    patternsDatasource: ref.watch(analyzePatternsFunctionsDatasourceProvider),
    patternAnalysisEnabled: ref
        .watch(featureFlagsProvider)
        .aiPatternAnalysisEnabled,
  ),
);

final analyzeMoodTextUseCaseProvider = Provider<AnalyzeMoodTextUseCase>(
  (ref) => AnalyzeMoodTextUseCase(
    repository: ref.watch(aiAnalysisRepositoryProvider),
  ),
);
