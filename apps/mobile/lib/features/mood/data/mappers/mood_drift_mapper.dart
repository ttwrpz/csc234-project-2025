import 'package:core/core.dart';
import 'package:drift/drift.dart' show Value;

import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_type.dart';
import '../../domain/mood_failure.dart';
import '../local/mood_database.dart';

/// Pure-Dart bidirectional mapping between the Drift `MoodEntryRow` and the
/// domain `MoodEntry`. Lives in `data/` so the domain layer remains free of
/// any `package:drift` import (per the CLAUDE.md "domain layer purity" rule).
///
/// Provides the Row → Entity direction (for `watchAll` + `findById`) and the
/// Entity → Companion direction (for `save` + `update`). DTO ↔ Companion
/// continues to live inside `MoodSyncManager`'s private `_toCompanion` helper.
class MoodDriftMapper {
  const MoodDriftMapper();

  /// Maps a Drift row to the domain entity. Returns `Err(malformed)` when the
  /// row's `mood` column does not name a known [MoodType]; returns the failure
  /// surfaced by [MoodEntry.create] for any other invariant violation
  /// (intensity out of range, text > 500, empty id/userId).
  Result<MoodEntry, MoodFailure> rowToEntity(MoodEntryRow row) {
    final MoodType mood;
    try {
      mood = MoodType.values.byName(row.mood);
    } on ArgumentError {
      return Err(MoodFailure.malformed('unknown mood: ${row.mood}'));
    }
    return MoodEntry.create(
      id: row.id,
      userId: row.userId,
      mood: mood,
      intensity: row.intensity,
      text: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: row.updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.updatedAt!, isUtc: true),
      mediaRefs: row.mediaRefs,
    );
  }

  /// Maps a domain entity to a Drift companion suitable for
  /// `MoodDao.upsertFromLocal`. The caller supplies the per-install [deviceId]
  /// and the desired [syncState] (typically `pending` for a fresh local
  /// mutation). When [updatedAtOverride] is supplied it wins; otherwise the
  /// entity's own `updatedAt` is used. Times are stored as UTC epoch
  /// milliseconds.
  MoodEntriesCompanion entityToCompanion(
    MoodEntry entry, {
    required String deviceId,
    required String syncState,
    int? updatedAtOverride,
  }) {
    return MoodEntriesCompanion.insert(
      id: entry.id,
      userId: entry.userId,
      mood: entry.mood.name,
      intensity: entry.intensity,
      note: entry.text,
      createdAt: entry.createdAt.toUtc().millisecondsSinceEpoch,
      updatedAt: Value(
        updatedAtOverride ?? entry.updatedAt?.toUtc().millisecondsSinceEpoch,
      ),
      mediaRefs: Value(entry.mediaRefs),
      syncState: syncState,
      deviceId: deviceId,
    );
  }
}
