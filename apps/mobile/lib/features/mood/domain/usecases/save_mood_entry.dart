import 'package:core/core.dart';

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
///      result directly. The repo overwrites the sentinel `id` with the
///      Firestore-allocated id and applies server timestamps on the round
///      trip.
class SaveMoodEntryUseCase {
  const SaveMoodEntryUseCase({
    required MoodRepository repository,
    DateTime Function() now = DateTime.now,
  }) : _repository = repository,
       _now = now;

  final MoodRepository _repository;
  final DateTime Function() _now;

  /// Sentinel id passed to [MoodEntry.create] for transient drafts. The
  /// non-empty value satisfies the entity invariant; the data layer replaces
  /// it with the Firestore-allocated id when the document is created.
  static const String _pendingId = 'pending';

  Future<Result<MoodEntry, MoodFailure>> call({
    required String userId,
    required MoodDraft draft,
  }) async {
    final mood = draft.mood;
    if (mood == null) {
      return const Err(MoodFailure.malformed('mood is required'));
    }
    final entryResult = MoodEntry.create(
      id: _pendingId,
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
