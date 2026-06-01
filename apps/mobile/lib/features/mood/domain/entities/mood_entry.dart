import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../mood_failure.dart';
import 'mood_type.dart';

part 'mood_entry.freezed.dart';
part 'mood_entry.g.dart';

/// A persisted mood log. The pivot-feature invariants live here:
///  - `intensity` is 1..5 (validated by [create])
///  - `text` is at most 500 characters (validated by [create])
///  - the entry is locked at the next local-midnight after [createdAt]
///    (see [isLocked]). Same-day edits/deletes are allowed; once the
///    calendar day rolls over, the entry becomes a record.
@freezed
abstract class MoodEntry with _$MoodEntry {
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

  /// Domain-level mutability guard. Returns `true` once the local
  /// calendar day of [createdAt] has passed - i.e. the entry is from
  /// yesterday or earlier in the user's local time. Same-day edits and
  /// deletes are allowed regardless of how many hours have elapsed.
  ///
  /// A calendar-day boundary is used rather than a flat "24 hours after
  /// createdAt" rule so that an 11pm entry doesn't become uneditable
  /// mid-evening the following day. Use [now] in tests for determinism.
  bool isLocked({DateTime? now}) {
    final n = (now ?? DateTime.now()).toLocal();
    final c = createdAt.toLocal();
    final today = DateTime(n.year, n.month, n.day);
    final created = DateTime(c.year, c.month, c.day);
    return today.isAfter(created);
  }

  /// Validates inputs and returns a populated [MoodEntry] on success, or a
  /// [MoodFailure] on failure. Used by the SaveMoodEntry use case so that
  /// controllers never construct invalid entries directly.
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
