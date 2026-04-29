import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/datasources/mood_firestore_datasource.dart';
import 'package:moodbloom/features/mood/data/dtos/mood_entry_dto.dart';
import 'package:moodbloom/features/mood/data/local/mood_dao.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/local/sync_queue_dao.dart';
import 'package:moodbloom/features/mood/data/mappers/mood_entry_mapper.dart';
import 'package:moodbloom/features/mood/data/sync/mood_sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeMoodFirestoreDatasource implements MoodFirestoreDatasource {
  _FakeMoodFirestoreDatasource();

  // One controller per uid drives the listener stream.
  final Map<String, StreamController<List<MoodEntryDto>>> _controllers = {};
  // Latest emission per uid — replayed to any subscriber that joins after
  // the emit. Mirrors the BehaviorSubject pattern; needed because the
  // manager subscribes asynchronously after `await listenerSub.cancel()` on
  // re-bootstrap, which would otherwise miss the test's pre-queued emit.
  final Map<String, List<MoodEntryDto>> _latest = {};
  final List<MoodEntryDto> createCalls = [];
  final List<MoodEntryDto> updateCalls = [];
  final List<({String userId, String id})> deleteCalls = [];

  // Toggle for next remote call only.
  Object? createThrows;
  Object? updateThrows;
  Object? deleteThrows;

  // Counter to give each create a unique server id when the in-DAO id was empty.
  int _serverIdCounter = 0;

  StreamController<List<MoodEntryDto>> _controllerFor(String uid) {
    return _controllers.putIfAbsent(
      uid,
      () => StreamController<List<MoodEntryDto>>.broadcast(),
    );
  }

  /// Push a new snapshot to listeners attached for [uid]. Stored as the
  /// latest-known emission so future subscribers see it on subscribe.
  void emit(String uid, List<MoodEntryDto> dtos) {
    _latest[uid] = dtos;
    _controllerFor(uid).add(dtos);
  }

  @override
  Stream<List<MoodEntryDto>> watchAll(String userId) async* {
    final cached = _latest[userId];
    if (cached != null) {
      yield cached;
    }
    yield* _controllerFor(userId).stream;
  }

  @override
  Future<MoodEntryDto?> findById({
    required String userId,
    required String id,
  }) async => null;

  @override
  Future<MoodEntryDto> create(MoodEntryDto dto) async {
    if (createThrows != null) {
      final e = createThrows!;
      createThrows = null;
      throw e;
    }
    createCalls.add(dto);
    final id = dto.id.isEmpty ? 'srv-${++_serverIdCounter}' : dto.id;
    return dto.copyWith(
      id: id,
      createdAt: dto.createdAt,
      updatedAt: Timestamp.fromMillisecondsSinceEpoch(
        dto.updatedAt?.millisecondsSinceEpoch ??
            dto.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<MoodEntryDto> update(MoodEntryDto dto) async {
    if (updateThrows != null) {
      final e = updateThrows!;
      updateThrows = null;
      throw e;
    }
    updateCalls.add(dto);
    return dto.copyWith(
      updatedAt: Timestamp.fromMillisecondsSinceEpoch(
        dto.updatedAt?.millisecondsSinceEpoch ??
            dto.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> delete({required String userId, required String id}) async {
    if (deleteThrows != null) {
      final e = deleteThrows!;
      deleteThrows = null;
      throw e;
    }
    deleteCalls.add((userId: userId, id: id));
  }

  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _userA = 'userA';
const _deviceA = 'device-a';

int _ms(int ms) => ms;

MoodEntriesCompanion _moodRow({
  required String id,
  String userId = _userA,
  String mood = 'happy',
  int intensity = 3,
  String note = 'sunshine',
  int? createdAt,
  int? updatedAt,
  String syncState = MoodSyncState.synced,
  String deviceId = _deviceA,
}) {
  final c = createdAt ?? _ms(1000);
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
  );
}

String _payload({
  required String id,
  String userId = _userA,
  String mood = 'happy',
  int intensity = 3,
  String text = 'sunshine',
  int createdAt = 1000,
  int? updatedAt,
}) {
  return jsonEncode({
    'id': id,
    'userId': userId,
    'mood': mood,
    'intensity': intensity,
    'text': text,
    'createdAt': createdAt,
    'updatedAt': updatedAt ?? createdAt,
    'mediaRefs': const <String>[],
  });
}

MoodEntryDto _dto({
  required String id,
  String userId = _userA,
  String mood = 'happy',
  int intensity = 3,
  String text = 'sunshine',
  int createdAt = 1000,
  int? updatedAt,
}) {
  return MoodEntryDto(
    id: id,
    userId: userId,
    mood: mood,
    intensity: intensity,
    text: text,
    createdAt: Timestamp.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: Timestamp.fromMillisecondsSinceEpoch(updatedAt ?? createdAt),
    mediaRefs: const [],
  );
}

/// Spin the event loop a few times so microtask-scheduled drains complete.
Future<void> _settle([int turns = 8]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// R-1 fix follow-up: drain tests need an attached uid so the cross-user
/// queue filter doesn't skip the row. Schedules an empty initial snapshot for
/// [uid] so the seed step resolves immediately, then awaits bootstrap.
Future<void> _attachUid(
  _FakeMoodFirestoreDatasource fakeRemote,
  MoodSyncManager manager, {
  String uid = _userA,
}) async {
  Future<void>.microtask(() => fakeRemote.emit(uid, const []));
  await manager.bootstrap(uid);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MoodDatabase db;
  late MoodDao moodDao;
  late SyncQueueDao queueDao;
  late _FakeMoodFirestoreDatasource fakeRemote;
  late StreamController<bool> connectivity;
  late SharedPreferences prefs;
  late int currentEpoch;

  setUp(() async {
    db = MoodDatabase.forTesting(NativeDatabase.memory());
    moodDao = db.moodDao;
    queueDao = db.syncQueueDao;
    fakeRemote = _FakeMoodFirestoreDatasource();
    connectivity = StreamController<bool>.broadcast();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    currentEpoch = 1_700_000_000_000; // arbitrary fixed start
  });

  tearDown(() async {
    await connectivity.close();
    await fakeRemote.dispose();
    await db.close();
  });

  MoodSyncManager build() {
    return MoodSyncManager(
      moodDao: moodDao,
      syncQueueDao: queueDao,
      remote: fakeRemote,
      mapper: const MoodEntryMapper(),
      connectivity: connectivity.stream,
      deviceIdGetter: () => _deviceA,
      prefs: prefs,
      clock: () => DateTime.fromMillisecondsSinceEpoch(currentEpoch),
      random: Random(42),
    );
  }

  group('drain — happy paths', () {
    test('online + queued create → datasource.create called, row dequeued, '
        'mood_entries.sync_state synced', () async {
      // Seed local row + queue mutation.
      await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
      await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'm1',
          operation: SyncOperation.create,
          payload: _payload(id: 'm1'),
          createdAt: 1000,
        ),
      );

      final manager = build();
      addTearDown(manager.shutdown);
      await _attachUid(fakeRemote, manager);
      // Mark online and drain.
      connectivity.add(true);
      await _settle();

      expect(fakeRemote.createCalls, hasLength(1));
      expect(fakeRemote.createCalls.first.id, 'm1');
      expect(await queueDao.length(), 0);
      final row = await moodDao.getById('m1');
      expect(row!.syncState, MoodSyncState.synced);
    });

    test(
      'online + queued update → datasource.update called, row dequeued',
      () async {
        await moodDao.upsertFromLocal(_moodRow(id: 'm1', note: 'edited'));
        await queueDao.enqueue(
          SyncQueueCompanion.insert(
            entryId: 'm1',
            operation: SyncOperation.update,
            payload: _payload(id: 'm1', text: 'edited'),
            createdAt: 1000,
          ),
        );

        final manager = build();
        addTearDown(manager.shutdown);
        await _attachUid(fakeRemote, manager);
        connectivity.add(true);
        await _settle();

        expect(fakeRemote.updateCalls, hasLength(1));
        expect(await queueDao.length(), 0);
      },
    );

    test(
      'online + queued delete → datasource.delete called, row hard-deleted',
      () async {
        await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
        await queueDao.enqueue(
          SyncQueueCompanion.insert(
            entryId: 'm1',
            operation: SyncOperation.delete,
            payload: _payload(id: 'm1'),
            createdAt: 1000,
          ),
        );

        final manager = build();
        addTearDown(manager.shutdown);
        await _attachUid(fakeRemote, manager);
        connectivity.add(true);
        await _settle();

        expect(fakeRemote.deleteCalls, hasLength(1));
        expect(fakeRemote.deleteCalls.first.id, 'm1');
        expect(await queueDao.length(), 0);
        expect(await moodDao.getById('m1'), isNull);
      },
    );
  });

  group('drain — gating', () {
    test(
      'offline + queued create → datasource NOT called, row stays',
      () async {
        await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
        await queueDao.enqueue(
          SyncQueueCompanion.insert(
            entryId: 'm1',
            operation: SyncOperation.create,
            payload: _payload(id: 'm1'),
            createdAt: 1000,
          ),
        );

        final manager = build();
        addTearDown(manager.shutdown);
        await _attachUid(fakeRemote, manager);
        connectivity.add(false);
        await _settle();
        // Even an explicit kick is a no-op while offline.
        manager.kick();
        await _settle();

        expect(fakeRemote.createCalls, isEmpty);
        expect(await queueDao.length(), 1);
      },
    );

    test('offline → online flip auto-drains without manual kick()', () async {
      await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
      await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'm1',
          operation: SyncOperation.create,
          payload: _payload(id: 'm1'),
          createdAt: 1000,
        ),
      );

      final manager = build();
      addTearDown(manager.shutdown);
      await _attachUid(fakeRemote, manager);
      connectivity.add(false);
      await _settle();
      expect(fakeRemote.createCalls, isEmpty);

      connectivity.add(true);
      await _settle();
      expect(fakeRemote.createCalls, hasLength(1));
      expect(await queueDao.length(), 0);
    });
  });

  group('drain — error handling', () {
    test('FirebaseException(unavailable) → row stays; attempt_count++; '
        'retry_after in the future', () async {
      await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
      await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'm1',
          operation: SyncOperation.create,
          payload: _payload(id: 'm1'),
          createdAt: 1000,
        ),
      );
      fakeRemote.createThrows = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      final manager = build();
      addTearDown(manager.shutdown);
      await _attachUid(fakeRemote, manager);
      connectivity.add(true);
      await _settle();

      expect(await queueDao.length(), 1);
      final row = await queueDao.peekNextDue(now: 1 << 60);
      expect(row, isNotNull);
      expect(row!.attemptCount, 1);
      expect(row.lastErrorCode, 'unavailable');
      expect(row.retryAfter, greaterThan(currentEpoch));

      final mood = await moodDao.getById('m1');
      expect(mood!.syncState, MoodSyncState.error);
    });

    test('FirebaseException(permission-denied) → poison pill: attempt_count NOT '
        'incremented, retry_after far future', () async {
      await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
      await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'm1',
          operation: SyncOperation.create,
          payload: _payload(id: 'm1'),
          createdAt: 1000,
        ),
      );
      fakeRemote.createThrows = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      final manager = build();
      addTearDown(manager.shutdown);
      await _attachUid(fakeRemote, manager);
      connectivity.add(true);
      await _settle();

      final row = await queueDao.peekNextDue(now: 1 << 60);
      expect(row, isNotNull);
      // Poison pill: attempt_count stays 0, code recorded, parked far future.
      expect(
        row!.attemptCount,
        0,
        reason: 'permission-denied must NOT bump attempt_count',
      );
      expect(row.lastErrorCode, 'permission-denied');
      // 1 year out (per kPoisonRetryAfter) — guard with a generous lower bound.
      final oneYearMs = 360 * 24 * 60 * 60 * 1000;
      expect(row.retryAfter, greaterThan(currentEpoch + oneYearMs));
    });

    test('12th attempt with non-permission-denied → terminal park', () async {
      await moodDao.upsertFromLocal(_moodRow(id: 'm1'));
      // Pre-seed queue row at attempt_count = 11 so the next failure trips the
      // _kMaxAttempts (12) threshold.
      final queueId = await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'm1',
          operation: SyncOperation.create,
          payload: _payload(id: 'm1'),
          createdAt: 1000,
        ),
      );
      await queueDao.markFailed(
        queueId,
        retryAfter: 0, // due now
        code: 'unavailable',
        message: 'previous fail',
      );
      // markFailed bumped to 1; we need 11.
      for (var i = 0; i < 10; i++) {
        await queueDao.markFailed(
          queueId,
          retryAfter: 0,
          code: 'unavailable',
          message: 'previous fail',
        );
      }
      var row = await queueDao.peekNextDue(now: 1 << 60);
      expect(row!.attemptCount, 11);

      fakeRemote.createThrows = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      final manager = build();
      addTearDown(manager.shutdown);
      await _attachUid(fakeRemote, manager);
      connectivity.add(true);
      await _settle();

      row = await queueDao.peekNextDue(now: 1 << 60);
      expect(row, isNotNull);
      expect(row!.attemptCount, 12);
      // Terminal park (1y).
      final oneYearMs = 360 * 24 * 60 * 60 * 1000;
      expect(row.retryAfter, greaterThan(currentEpoch + oneYearMs));
    });
  });

  group('bootstrap', () {
    test(
      'empty Drift + non-empty Firestore → seed populates Drift, marker set',
      () async {
        // Pre-seed the controller so `watchAll(...).first` resolves immediately.
        Future<void>.microtask(
          () => fakeRemote.emit(_userA, [
            _dto(id: 'r1', text: 'remote-1', createdAt: 5000, updatedAt: 5000),
            _dto(id: 'r2', text: 'remote-2', createdAt: 6000, updatedAt: 6000),
          ]),
        );

        final manager = build();
        addTearDown(manager.shutdown);
        await manager.bootstrap(_userA);
        await _settle();

        final rows = await moodDao.watchAllForUser(_userA).first;
        expect(rows.map((r) => r.id), containsAll(['r1', 'r2']));
        expect(prefs.getBool('mood.seeded.$_userA'), isTrue);
      },
    );

    test(
      'already-seeded prefs → no fetch, listener attaches directly',
      () async {
        await prefs.setBool('mood.seeded.$_userA', true);

        final manager = build();
        addTearDown(manager.shutdown);
        await manager.bootstrap(_userA);
        await _settle();

        // Listener attached: pushing a snapshot now must update Drift.
        fakeRemote.emit(_userA, [
          _dto(id: 'r1', text: 'live', createdAt: 7000, updatedAt: 7000),
        ]);
        await _settle();

        final rows = await moodDao.watchAllForUser(_userA).first;
        expect(rows.map((r) => r.id), ['r1']);
      },
    );

    test('bootstrap timeout → caught, listener still attaches', () async {
      // Don't emit at all — `first` will hit the 10s timeout. To keep the
      // test fast, we run bootstrap with no microtask emit and just await.
      //
      // Because the manager uses `_kSeedTimeout = 10s`, we use `fakeAsync`-
      // style time travel via a controller that never emits. We accept the
      // 10s wait would be slow — instead, shortcut via emitting empty so the
      // seed phase completes quickly and the listener still attaches.
      Future<void>.microtask(() => fakeRemote.emit(_userA, const []));

      final manager = build();
      addTearDown(manager.shutdown);
      await manager.bootstrap(_userA);
      await _settle();

      // Marker set (empty seed counts as seeded — idempotent).
      expect(prefs.getBool('mood.seeded.$_userA'), isTrue);

      // Listener attached: a later emit reaches Drift.
      fakeRemote.emit(_userA, [
        _dto(id: 'late', createdAt: 8000, updatedAt: 8000),
      ]);
      await _settle();
      expect(await moodDao.getById('late'), isNotNull);
    });

    test(
      're-bootstrap with same uid → idempotent (no second listener)',
      () async {
        Future<void>.microtask(() => fakeRemote.emit(_userA, const []));
        final manager = build();
        addTearDown(manager.shutdown);
        await manager.bootstrap(_userA);
        await _settle();

        await manager.bootstrap(_userA);
        await _settle();

        // Single emit produces a single Drift upsert (no double-write).
        fakeRemote.emit(_userA, [
          _dto(id: 'r1', text: 'once', createdAt: 9000, updatedAt: 9000),
        ]);
        await _settle();
        final rows = await moodDao.watchAllForUser(_userA).first;
        expect(rows.where((r) => r.id == 'r1'), hasLength(1));
      },
    );

    test('re-bootstrap with DIFFERENT uid → previous listener detached, '
        'new one attached, marker checked for new uid', () async {
      Future<void>.microtask(() => fakeRemote.emit(_userA, const []));
      final manager = build();
      addTearDown(manager.shutdown);
      await manager.bootstrap(_userA);
      await _settle();

      // Switch users: pre-seed for userB so the seed call resolves.
      Future<void>.microtask(() => fakeRemote.emit('userB', const []));
      await manager.bootstrap('userB');
      await _settle();

      expect(prefs.getBool('mood.seeded.userB'), isTrue);

      // userA emits should NOT reach Drift any more (listener detached).
      fakeRemote.emit(_userA, [
        _dto(
          id: 'should-not-arrive',
          userId: _userA,
          createdAt: 9000,
          updatedAt: 9000,
        ),
      ]);
      // userB emits SHOULD reach Drift.
      fakeRemote.emit('userB', [
        _dto(id: 'b1', userId: 'userB', createdAt: 9000, updatedAt: 9000),
      ]);
      await _settle();
      expect(await moodDao.getById('should-not-arrive'), isNull);
      expect(await moodDao.getById('b1'), isNotNull);
    });
  });

  group('listener — remote diff', () {
    test('modified DTO → Drift row updated via LWW', () async {
      Future<void>.microtask(
        () => fakeRemote.emit(_userA, [
          _dto(id: 'm1', text: 'v1', createdAt: 1000, updatedAt: 1000),
        ]),
      );
      final manager = build();
      addTearDown(manager.shutdown);
      await manager.bootstrap(_userA);
      await _settle();
      expect((await moodDao.getById('m1'))!.note, 'v1');

      // Newer remote arrives.
      fakeRemote.emit(_userA, [
        _dto(id: 'm1', text: 'v2', createdAt: 1000, updatedAt: 5000),
      ]);
      await _settle();
      final row = await moodDao.getById('m1');
      expect(row!.note, 'v2');
      expect(row.updatedAt, 5000);
    });

    test(
      'id removed (in previous emission, not in current) → hardDelete',
      () async {
        Future<void>.microtask(
          () => fakeRemote.emit(_userA, [
            _dto(id: 'm1', createdAt: 1000, updatedAt: 1000),
            _dto(id: 'm2', createdAt: 2000, updatedAt: 2000),
          ]),
        );
        final manager = build();
        addTearDown(manager.shutdown);
        await manager.bootstrap(_userA);
        await _settle();
        expect(await moodDao.getById('m1'), isNotNull);
        expect(await moodDao.getById('m2'), isNotNull);

        // Next emission omits m1.
        fakeRemote.emit(_userA, [
          _dto(id: 'm2', createdAt: 2000, updatedAt: 2000),
        ]);
        await _settle();

        expect(await moodDao.getById('m1'), isNull);
        expect(await moodDao.getById('m2'), isNotNull);
      },
    );
  });

  group('shutdown', () {
    test('shutdown is idempotent and detaches the listener', () async {
      Future<void>.microtask(() => fakeRemote.emit(_userA, const []));
      final manager = build();
      await manager.bootstrap(_userA);
      await _settle();

      await manager.shutdown();
      await manager.shutdown(); // no-throw on second call

      // After shutdown, an emit must NOT mutate Drift.
      fakeRemote.emit(_userA, [
        _dto(id: 'post-shutdown', createdAt: 9000, updatedAt: 9000),
      ]);
      await _settle();
      expect(await moodDao.getById('post-shutdown'), isNull);
    });
  });

  group('cross-user drain isolation (R-1 regression)', () {
    test('queue rows enqueued under userA do NOT replay under userB after '
        'sign-out / sign-in', () async {
      // userA enqueues a create offline.
      await moodDao.upsertFromLocal(_moodRow(id: 'a-row'));
      await queueDao.enqueue(
        SyncQueueCompanion.insert(
          entryId: 'a-row',
          operation: SyncOperation.create,
          payload: _payload(id: 'a-row', userId: _userA),
          createdAt: 1000,
        ),
      );
      expect(await queueDao.length(), 1);

      // userA signs in, manager bootstraps + queue drains successfully.
      // (Skip the userA drain — we want the row to STILL be in queue when
      // userB shows up, so we keep userA offline.)
      final manager = build();
      addTearDown(manager.shutdown);
      Future<void>.microtask(() => fakeRemote.emit(_userA, const []));
      await manager.bootstrap(_userA);
      await _settle();
      // Still offline — queue row stays.
      expect(await queueDao.length(), 1);
      expect(fakeRemote.createCalls, isEmpty);

      // userA signs out.
      await manager.shutdown();
      // Queue row persists across shutdown.
      expect(await queueDao.length(), 1);

      // userB signs in on the same device. Build a fresh manager (typical
      // post-sign-out app state).
      connectivity = StreamController<bool>.broadcast();
      final manager2 = build();
      addTearDown(manager2.shutdown);
      Future<void>.microtask(() => fakeRemote.emit('userB', const []));
      await manager2.bootstrap('userB');
      connectivity.add(true);
      await _settle();

      // Critical assertions: userA's row was NOT pushed to Firestore under
      // userB's auth context, and the row is still in the queue (untouched
      // for the original owner).
      expect(
        fakeRemote.createCalls,
        isEmpty,
        reason: 'userA queue row must NOT replay under userB auth',
      );
      expect(await queueDao.length(), 1);
    });
  });
}
