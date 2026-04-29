import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/mood_failure.dart';
import '../domain/mood_repository.dart';
import '../domain/repositories/mood_media_repository.dart';
import '../domain/usecases/pick_mood_media.dart';
import '../domain/usecases/save_mood_entry.dart';
import '../domain/usecases/upload_mood_media.dart';
import '../domain/usecases/watch_my_moods.dart';
import 'datasources/image_picker_datasource.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'datasources/mood_storage_datasource.dart';
import 'mood_repository_impl.dart';
import 'repositories/mood_media_repository_impl.dart';

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

// Media (WBS 3.3) — picker + Storage upload. Sibling to the entry repository
// so the Drift cutover (WBS 3.5) can rewrite mood storage without touching
// media plumbing.

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
