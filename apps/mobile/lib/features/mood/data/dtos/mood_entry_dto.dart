import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_entry_dto.freezed.dart';

/// Wire-format mirror of the Firestore document at
/// `users/{uid}/moods/{moodId}`. Lives in `data/` only — domain entities never
/// see this type.
@freezed
class MoodEntryDto with _$MoodEntryDto {
  const factory MoodEntryDto({
    required String id,
    required String userId,
    required String mood, // MoodType.name
    required int intensity,
    required String text,
    required Timestamp createdAt,
    Timestamp? updatedAt,
    @Default(<String>[]) List<String> mediaRefs,
  }) = _MoodEntryDto;

  const MoodEntryDto._();

  factory MoodEntryDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MoodEntryDto(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      mood: data['mood'] as String? ?? 'okay',
      intensity: (data['intensity'] as num?)?.toInt() ?? 3,
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      mediaRefs: ((data['mediaRefs'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  /// Payload for `add()`. Server timestamps are used so the rules' check
  /// `createdAt == request.time` (S3) passes.
  Map<String, Object?> toFirestoreOnCreate() => {
    'userId': userId,
    'mood': mood,
    'intensity': intensity,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'mediaRefs': mediaRefs,
  };

  /// Payload for `update()`. Excludes `createdAt` (immutable per CLAUDE.md
  /// Firestore rules).
  Map<String, Object?> toFirestoreOnUpdate() => {
    'mood': mood,
    'intensity': intensity,
    'text': text,
    'updatedAt': FieldValue.serverTimestamp(),
    'mediaRefs': mediaRefs,
  };
}
