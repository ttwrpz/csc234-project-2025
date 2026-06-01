import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:core/core.dart';

import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_type.dart';
import '../../domain/mood_failure.dart';
import '../dtos/mood_entry_dto.dart';

/// Converts between the Firestore-shaped [MoodEntryDto] and the domain
/// [MoodEntry]. Validation is delegated to `MoodEntry.create`.
class MoodEntryMapper {
  const MoodEntryMapper();

  /// Domain-side construction. Falls back to [MoodType.okay] for unknown mood
  /// strings so a typo in Firestore never crashes the app.
  Result<MoodEntry, MoodFailure> toEntity(MoodEntryDto dto) {
    final mood = MoodType.values.firstWhere(
      (m) => m.name == dto.mood,
      orElse: () => MoodType.okay,
    );
    return MoodEntry.create(
      id: dto.id,
      userId: dto.userId,
      mood: mood,
      intensity: dto.intensity,
      text: dto.text,
      createdAt: dto.createdAt.toDate(),
      updatedAt: dto.updatedAt?.toDate(),
      mediaRefs: dto.mediaRefs,
    );
  }

  /// Builds a DTO ready to write. The `id` is empty until Firestore allocates
  /// one; the timestamps are placeholders - the actual server timestamps are
  /// applied by [MoodEntryDto.toFirestoreOnCreate].
  MoodEntryDto toDtoForCreate({
    required String userId,
    required MoodType mood,
    required int intensity,
    required String text,
    required List<String> mediaRefs,
  }) {
    final placeholder = Timestamp.now();
    return MoodEntryDto(
      id: '',
      userId: userId,
      mood: mood.name,
      intensity: intensity,
      text: text,
      createdAt: placeholder,
      updatedAt: placeholder,
      mediaRefs: mediaRefs,
    );
  }
}
