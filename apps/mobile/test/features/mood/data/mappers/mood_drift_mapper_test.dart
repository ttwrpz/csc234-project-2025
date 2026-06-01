import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/mappers/mood_drift_mapper.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';

void main() {
  const mapper = MoodDriftMapper();

  // 2026-04-29 14:00 UTC - far enough back to test UTC stability across DST.
  final createdAt = DateTime.utc(2026, 4, 29, 14);
  final updatedAt = DateTime.utc(2026, 4, 29, 15);

  MoodEntryRow buildRow({
    String id = 'm1',
    String userId = 'u1',
    String mood = 'happy',
    int intensity = 3,
    String note = 'sunshine',
    int? updatedAtMs,
    List<String> mediaRefs = const [],
  }) {
    return MoodEntryRow(
      id: id,
      userId: userId,
      mood: mood,
      intensity: intensity,
      note: note,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAtMs ?? updatedAt.millisecondsSinceEpoch,
      mediaRefs: mediaRefs,
      syncState: 'synced',
      deviceId: 'device-a',
      deletedAt: null,
    );
  }

  group('rowToEntity', () {
    test('valid row → Ok with UTC-normalised timestamps', () {
      final row = buildRow();
      final result = mapper.rowToEntity(row);
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      final entity = (result as Ok<MoodEntry, MoodFailure>).value;
      expect(entity.id, 'm1');
      expect(entity.userId, 'u1');
      expect(entity.mood, MoodType.happy);
      expect(entity.intensity, 3);
      expect(entity.text, 'sunshine');
      expect(entity.createdAt.toUtc(), createdAt);
      expect(entity.updatedAt!.toUtc(), updatedAt);
      expect(entity.mediaRefs, isEmpty);
    });

    test('null updatedAt → entity.updatedAt is null', () {
      final row = MoodEntryRow(
        id: 'm1',
        userId: 'u1',
        mood: 'calm',
        intensity: 2,
        note: 'breath',
        createdAt: createdAt.millisecondsSinceEpoch,
        updatedAt: null,
        mediaRefs: const [],
        syncState: 'pending',
        deviceId: 'device-a',
        deletedAt: null,
      );
      final result = mapper.rowToEntity(row);
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      expect((result as Ok<MoodEntry, MoodFailure>).value.updatedAt, isNull);
    });

    test('unknown mood string → Err(malformed)', () {
      final row = buildRow(mood: 'euphoric'); // not a MoodType.values name
      final result = mapper.rowToEntity(row);
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      final failure = (result as Err<MoodEntry, MoodFailure>).failure;
      expect(failure, isA<MoodFailure>());
      expect(failure.message, contains('Malformed'));
    });

    test('intensity out of range → Err(invalidIntensity) from create()', () {
      // Schema CHECK would normally block this, but rowToEntity must still
      // surface a failure if a malformed row escapes (e.g., legacy data).
      final row = buildRow(intensity: 7);
      final result = mapper.rowToEntity(row);
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
    });
  });

  group('entityToCompanion', () {
    test('round-trips through a real database', () async {
      final db = MoodDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final entityResult = MoodEntry.create(
        id: 'm-rt',
        userId: 'u1',
        mood: MoodType.sad,
        intensity: 4,
        text: 'rough day',
        createdAt: createdAt,
        updatedAt: updatedAt,
        mediaRefs: const ['gs://bucket/img.png'],
      );
      final entity = (entityResult as Ok<MoodEntry, MoodFailure>).value;
      final companion = mapper.entityToCompanion(
        entity,
        deviceId: 'device-a',
        syncState: 'pending',
      );
      await db.moodDao.upsertFromLocal(companion);

      final row = await db.moodDao.getById('m-rt');
      expect(row, isNotNull);
      expect(row!.id, 'm-rt');
      expect(row.mood, 'sad');
      expect(row.intensity, 4);
      expect(row.note, 'rough day');
      expect(row.createdAt, createdAt.millisecondsSinceEpoch);
      expect(row.updatedAt, updatedAt.millisecondsSinceEpoch);
      expect(row.mediaRefs, ['gs://bucket/img.png']);
      expect(row.deviceId, 'device-a');
      // upsertFromLocal forces sync_state=pending (DAO contract).
      expect(row.syncState, 'pending');
    });

    test('updatedAtOverride wins over entity.updatedAt', () {
      final entityResult = MoodEntry.create(
        id: 'm1',
        userId: 'u1',
        mood: MoodType.okay,
        intensity: 3,
        text: 'meh',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final entity = (entityResult as Ok<MoodEntry, MoodFailure>).value;
      final overrideMs = DateTime.utc(2030, 1, 1).millisecondsSinceEpoch;
      final companion = mapper.entityToCompanion(
        entity,
        deviceId: 'device-a',
        syncState: 'pending',
        updatedAtOverride: overrideMs,
      );
      expect(companion.updatedAt.value, overrideMs);
    });
  });
}
