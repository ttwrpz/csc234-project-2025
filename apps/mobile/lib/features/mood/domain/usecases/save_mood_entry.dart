import 'package:core/core.dart';
import 'package:uuid/uuid.dart';

import '../entities/mood_draft.dart';
import '../entities/mood_entry.dart';
import '../mood_failure.dart';
import '../mood_repository.dart';

/// Persists a [MoodDraft] as a new [MoodEntry].
///
/// Pure-Dart use case (no Flutter / Firebase imports). The Riverpod provider
/// for this class lives in `mood/data/providers.dart` so the domain layer
/// stays portable. Validation order:
///   1. `draft.mood == null` → `MoodFailure.malformed`.
///   2. Delegate to [MoodEntry.create], which enforces the intensity 1..5 and
///      text ≤ 500 invariants and returns the appropriate [MoodFailure].
///   3. Forward the populated entry to [MoodRepository.save] and return its
///      result directly.
///
/// Each new entry is stamped with a freshly generated client-side id at
/// creation time. This id is unique per log, so it doubles as the offline
/// Drift primary key and the Firestore doc id (the data layer reuses a
/// caller-supplied id as the doc id), which keeps cloud sync idempotent. A
/// shared constant id would make two same-day entries collide on the Drift
/// primary key and silently overwrite each other before they sync.
class SaveMoodEntryUseCase {
  const SaveMoodEntryUseCase({
    required MoodRepository repository,
    DateTime Function() now = DateTime.now,
    String Function() idGenerator = _defaultIdGenerator,
  }) : _repository = repository,
       _now = now,
       _idGenerator = idGenerator;

  final MoodRepository _repository;
  final DateTime Function() _now;
  final String Function() _idGenerator;

  /// Generates a unique id per new entry. A v4 UUID is a valid Firestore doc
  /// id and is collision-free across entries logged in the same day.
  static String _defaultIdGenerator() => const Uuid().v4();

  Future<Result<MoodEntry, MoodFailure>> call({
    required String userId,
    required MoodDraft draft,
  }) async {
    final mood = draft.mood;
    if (mood == null) {
      return const Err(MoodFailure.malformed('mood is required'));
    }
    final entryResult = MoodEntry.create(
      id: _idGenerator(),
      userId: userId,
      mood: mood,
      intensity: draft.intensity,
      text: draft.text,
      createdAt: _now(),
      mediaRefs: draft.mediaRefs,
    );
    return switch (entryResult) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => _repository.save(value),
    };
  }
}
