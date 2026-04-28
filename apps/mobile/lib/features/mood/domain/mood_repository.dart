import 'package:core/core.dart';

import 'entities/mood_entry.dart';
import 'mood_failure.dart';

/// Contract for any backing store that persists mood entries.
///
/// Implementations live in `data/`; they may use Firestore, Drift, or a fake.
/// The 24h lock is a domain-level check — callers should call
/// `entry.isLocked()` before invoking [update]/[delete]; server-side
/// enforcement via Firestore rules lands in S3.
abstract class MoodRepository {
  /// Streams the user's mood entries ordered by `createdAt` desc.
  Stream<List<MoodEntry>> watchAll({required String userId});

  /// Fetches a single entry. Used by the entry detail screen.
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  });

  /// Persists a new entry. Implementation sets `id` (Firestore-generated) and
  /// `createdAt`/`updatedAt` (server timestamps). Returns the saved entry on
  /// success.
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry);

  /// Updates an existing entry. Domain-level immutability is the caller's
  /// responsibility — call `entry.isLocked()` first.
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry);

  /// Deletes an entry. Same caveat as [update].
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  });
}
