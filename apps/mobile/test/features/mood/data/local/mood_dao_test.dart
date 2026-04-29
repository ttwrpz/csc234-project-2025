import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/local/mood_dao.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';

void main() {
  late MoodDatabase db;
  late MoodDao dao;

  const userA = 'userA';
  const deviceA = 'device-a';
  const deviceB = 'device-b';

  MoodEntriesCompanion sampleRow({
    required String id,
    String userId = userA,
    String mood = 'happy',
    int intensity = 3,
    String note = 'sunshine',
    int? createdAt,
    int? updatedAt,
    String syncState = MoodSyncState.synced,
    String deviceId = deviceA,
    int? deletedAt,
  }) {
    final c = createdAt ?? DateTime.utc(2026, 4, 29).millisecondsSinceEpoch;
    return MoodEntriesCompanion.insert(
      id: id,
      userId: userId,
      mood: mood,
      intensity: intensity,
      note: note,
      createdAt: c,
      updatedAt: Value(updatedAt ?? c),
      syncState: syncState,
      deviceId: deviceId,
      deletedAt: Value(deletedAt),
    );
  }

  setUp(() {
    db = MoodDatabase.forTesting(NativeDatabase.memory());
    dao = db.moodDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('MoodDao basic CRUD', () {
    test('upsertFromLocal then watchAllForUser returns the row', () async {
      await dao.upsertFromLocal(sampleRow(id: 'm1'));
      final rows = await dao.watchAllForUser(userA).first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'm1');
      // upsertFromLocal forces sync_state=pending regardless of input.
      expect(rows.first.syncState, MoodSyncState.pending);
    });

    test('watchAllForUser orders by created_at DESC', () async {
      await dao.upsertFromLocal(sampleRow(id: 'older', createdAt: 1000));
      await dao.upsertFromLocal(sampleRow(id: 'newer', createdAt: 2000));
      final rows = await dao.watchAllForUser(userA).first;
      expect(rows.map((r) => r.id), ['newer', 'older']);
    });

    test('softDelete hides the row from watchAllForUser', () async {
      await dao.upsertFromLocal(sampleRow(id: 'm1'));
      await dao.softDelete('m1', now: 9999);
      final rows = await dao.watchAllForUser(userA).first;
      expect(rows, isEmpty);
    });

    test('getById returns null for absent id, the row when present', () async {
      expect(await dao.getById('absent'), isNull);
      await dao.upsertFromLocal(sampleRow(id: 'm1'));
      final row = await dao.getById('m1');
      expect(row, isNotNull);
      expect(row!.id, 'm1');
    });

    test('isEmpty(userId) — true for fresh DB, false after one insert',
        () async {
      expect(await dao.isEmpty(userA), isTrue);
      await dao.upsertFromLocal(sampleRow(id: 'm1'));
      expect(await dao.isEmpty(userA), isFalse);
    });

    test('upsertFromLocal forces sync_state=pending', () async {
      // Even if caller passes synced, the DAO must re-stamp pending.
      await dao.upsertFromLocal(
        sampleRow(id: 'm1', syncState: MoodSyncState.synced),
      );
      final row = await dao.getById('m1');
      expect(row!.syncState, MoodSyncState.pending);
    });
  });

  group('MoodDao schema CHECK constraints', () {
    test('intensity = 0 is rejected', () async {
      expect(
        () => dao.upsertFromLocal(sampleRow(id: 'm1', intensity: 0)),
        throwsException,
      );
    });

    test('intensity = 6 is rejected', () async {
      expect(
        () => dao.upsertFromLocal(sampleRow(id: 'm1', intensity: 6)),
        throwsException,
      );
    });

    test('text > 500 chars is rejected', () async {
      expect(
        () => dao.upsertFromLocal(sampleRow(id: 'm1', note: 'x' * 501)),
        throwsException,
      );
    });
  });

  group('MoodDao LWW (upsertFromRemote — ADR-0005)', () {
    test('newer remote.updated_at overwrites local; sync_state=synced',
        () async {
      await dao.upsertFromLocal(
        sampleRow(id: 'm1', note: 'old', updatedAt: 1000),
      );
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'new',
          updatedAt: 2000,
          syncState: MoodSyncState.synced,
          deviceId: deviceA,
        ),
      );
      final row = await dao.getById('m1');
      expect(row!.note, 'new');
      expect(row.updatedAt, 2000);
      expect(row.syncState, MoodSyncState.synced);
    });

    test('older remote.updated_at is dropped; local wins', () async {
      // Seed a synced local row directly bypassing upsertFromLocal so its
      // sync_state stays `synced` (otherwise upsertFromLocal forces pending,
      // which triggers a different LWW branch).
      await db.into(db.moodEntries).insert(
            sampleRow(
              id: 'm1',
              note: 'fresh',
              updatedAt: 5000,
              syncState: MoodSyncState.synced,
            ),
          );
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'stale',
          updatedAt: 1000,
          syncState: MoodSyncState.synced,
        ),
      );
      final row = await dao.getById('m1');
      expect(row!.note, 'fresh');
      expect(row.updatedAt, 5000);
    });

    test('tie on updated_at: smaller device_id wins (overwrites local)',
        () async {
      await db.into(db.moodEntries).insert(
            sampleRow(
              id: 'm1',
              note: 'local',
              updatedAt: 5000,
              syncState: MoodSyncState.synced,
              deviceId: deviceB, // larger
            ),
          );
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'remote-from-smaller-device',
          updatedAt: 5000,
          syncState: MoodSyncState.synced,
          deviceId: deviceA, // smaller
        ),
      );
      final row = await dao.getById('m1');
      expect(row!.note, 'remote-from-smaller-device');
      expect(row.deviceId, deviceA);
    });

    test('tie on updated_at: larger device_id loses (local stays)', () async {
      await db.into(db.moodEntries).insert(
            sampleRow(
              id: 'm1',
              note: 'local',
              updatedAt: 5000,
              syncState: MoodSyncState.synced,
              deviceId: deviceA, // smaller
            ),
          );
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'remote-from-larger-device',
          updatedAt: 5000,
          syncState: MoodSyncState.synced,
          deviceId: deviceB, // larger
        ),
      );
      final row = await dao.getById('m1');
      expect(row!.note, 'local');
      expect(row.deviceId, deviceA);
    });

    test('local pending row is NOT clobbered by an equal-timestamp remote echo',
        () async {
      // Simulates a freshly-saved local row before the sync manager has
      // pushed it; the remote `snapshot()` listener must not overwrite the
      // user's in-flight mutation.
      await dao.upsertFromLocal(
        sampleRow(id: 'm1', note: 'in-flight', updatedAt: 5000),
      );
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'stale-snapshot',
          updatedAt: 5000,
          syncState: MoodSyncState.synced,
          deviceId: deviceB,
        ),
      );
      final row = await dao.getById('m1');
      expect(row!.note, 'in-flight');
      expect(row.syncState, MoodSyncState.pending);
    });

    test('remote insert when local is absent — inserts as synced', () async {
      await dao.upsertFromRemote(
        sampleRow(
          id: 'm1',
          note: 'fresh-from-remote',
          updatedAt: 1000,
          syncState: MoodSyncState.synced,
        ),
      );
      final row = await dao.getById('m1');
      expect(row, isNotNull);
      expect(row!.note, 'fresh-from-remote');
      expect(row.syncState, MoodSyncState.synced);
    });
  });
}
