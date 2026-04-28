import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../mood_failure.dart';
import 'mood_type.dart';

part 'mood_entry.freezed.dart';
part 'mood_entry.g.dart';

/// A persisted mood log. The pivot-feature invariants live here:
///  - `intensity` is 1..5 (validated by [create])
///  - `text` is at most 500 characters (validated by [create])
///  - the entry is locked 24 hours after [createdAt] (see [isLocked])
///
/// 24h lock *enforcement* (preventing edits/deletes) lands in S3; this entity
/// only ships the guard so callers can already query it.
@freezed
class MoodEntry with _$MoodEntry {
  const MoodEntry._();

  const factory MoodEntry({
    required String id,
    required String userId,
    required MoodType mood,
    required int intensity,
    required String text,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(<String>[]) List<String> mediaRefs,
  }) = _MoodEntry;

  factory MoodEntry.fromJson(Map<String, Object?> json) =>
      _$MoodEntryFromJson(json);

  /// Domain-level mutability guard. Returns `true` once the entry is at least
  /// 24 hours past its [createdAt]. Use [now] in tests for determinism.
  bool isLocked({DateTime? now}) =>
      (now ?? DateTime.now()).difference(createdAt).inHours >= 24;

  /// Validates inputs and returns a populated [MoodEntry] on success, or a
  /// [MoodFailure] on failure. Used by the SaveMoodEntry use case (lands in
  /// 3.2) so that controllers never construct invalid entries directly.
  static Result<MoodEntry, MoodFailure> create({
    required String id,
    required String userId,
    required MoodType mood,
    required int intensity,
    required String text,
    required DateTime createdAt,
    DateTime? updatedAt,
    List<String> mediaRefs = const [],
  }) {
    if (intensity < 1 || intensity > 5) {
      return Err(MoodFailure.invalidIntensity(intensity));
    }
    if (text.length > 500) {
      return Err(MoodFailure.textTooLong(text.length));
    }
    if (id.isEmpty || userId.isEmpty) {
      return const Err(
        MoodFailure.malformed('id and userId must be non-empty'),
      );
    }
    return Ok(
      MoodEntry(
        id: id,
        userId: userId,
        mood: mood,
        intensity: intensity,
        text: text,
        createdAt: createdAt,
        updatedAt: updatedAt,
        mediaRefs: mediaRefs,
      ),
    );
  }
}
