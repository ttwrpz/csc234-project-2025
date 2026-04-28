import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/mood_repository.dart';
import '../domain/usecases/save_mood_entry.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'mood_repository_impl.dart';

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
