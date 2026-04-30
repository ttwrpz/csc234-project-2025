import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/datasources/mood_firestore_datasource.dart';
import 'package:moodbloom/features/mood/data/dtos/mood_entry_dto.dart';
import 'package:moodbloom/features/mood/data/local/mood_dao.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/local/sync_queue_dao.dart';
import 'package:moodbloom/features/mood/data/mappers/mood_entry_mapper.dart';
import 'package:moodbloom/features/mood/data/mood_repository_impl.dart';
import 'package:moodbloom/features/mood/data/sync/mood_sync_manager.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Fake Firestore datasource that records every call and can be configured to
/// throw the next time a method is invoked. Modelled on the duplicate in
/// `mood_sync_manager_test.dart` — the architect's brief permits copy-paste at
/// S3 scope (DRY can come in S4).
class _FakeMoodFirestoreDatasource implements MoodFirestoreDatasource {
  final List<MoodEntryDto> createCalls = [];
  final List<MoodEntryDto> updateCalls = [];
  final List<({String userId, String id})> deleteCalls = [];
  final List<({String userId, String id})> findByIdCalls = [];

  Object? createThrows;
  Object? updateThrows;
  Object? deleteThrows;
  Object? findByIdThrows;

  // Per-uid simulated Firestore document store, keyed by entry id.
  final Map<String, Map<String, MoodEntryDto>> _store = {};

  MoodEntryDto? Function(String userId, String id)? findByIdHandler;

  void seed(MoodEntryDto dto) {
    _store.putIfAbsent(dto.userId, () => {})[dto.id] = dto;
  }

  @override
  Stream<List<MoodEntryDto>> watchAll(String userId) {
    final docs = _store[userId]?.values.toList() ?? const <MoodEntryDto>[];
    return Stream.value(docs);
  }

  @override
  Future<MoodEntryDto?> findById({
    required String userId,
    required String id,
  }) async {
    findByIdCalls.add((userId: userId, id: id));
    if (findByIdThrows != null) {
      final e = findByIdThrows!;
      findByIdThrows = null;
      throw e;
    }
    if (findByIdHandler != null) return findByIdHandler!(userId, id);
    return _store[userId]?[id];
  }

  @override
  Future<MoodEntryDto> create(MoodEntryDto dto) async {
    if (createThrows != null) {
      final e = createThrows!;
      createThrows = null;
      throw e;
    }
    createCalls.add(dto);
    final id = dto.id.isEmpty ? 'srv-${createCalls.length}' : dto.id;
    final stored = dto.copyWith(
      id: id,
      updatedAt: dto.updatedAt ?? dto.createdAt,
    );
    seed(stored);
    return stored;
  }

  @override
  Future<MoodEntryDto> update(MoodEntryDto dto) async {
    if (updateThrows != null) {
      final e = updateThrows!;
      updateThrows = null;
      throw e;
    }
    updateCalls.add(dto);
    final stored = dto.copyWith(
      updatedAt: Timestamp.fromMillisecondsSinceEpoch(
        dto.updatedAt?.millisecondsSinceEpoch ??
            dto.createdAt.millisecondsSinceEpoch,
      ),
    );
    seed(stored);
    return stored;
  }

  @override
  Future<void> delete({required String userId, required String id}) async {
    if (deleteThrows != null) {
      final e = deleteThrows!;
      deleteThrows = null;
      throw e;
    }
    deleteCalls.add((userId: userId, id: id));
    _store[userId]?.remove(id);
  }
}

/// Records `kick()` calls; bootstrap/shutdown are no-ops. The sync manager is a
/// concrete class (not abstract), so we extend it and override the public
/// surface — the constructor still requires the real machinery, so we hand it
/// the same in-memory database the repo uses to keep state consistent.
class _FakeMoodSyncManager extends MoodSyncManager {
  _FakeMoodSyncManager({
    required super.moodDao,
    required super.syncQueueDao,
    required super.remote,
    required super.connectivity,
    required super.deviceIdGetter,
    required super.prefs,
  }) : super(mapper: const MoodEntryMapper());

  int kickCount = 0;
  int bootstrapCount = 0;
  int shutdownCount = 0;

  @override
  void kick() {
    kickCount += 1;
    // Intentionally do NOT call super.kick() — we don't want the real drainer
    // to fire during these unit tests; mood_sync_manager_test covers that.
  }

  @override
  Future<void> bootstrap(String uid) async {
    bootstrapCount += 1;
  }

  @override
  Future<void> shutdown() async {
    shutdownCount += 1;
    // Cancel the parent's connectivity subscription + poll timer so test
    // teardown is clean.
    await super.shutdown();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _userA = 'userA';
const _deviceA = 'device-a';

DateTime _atHour(int hour) => DateTime.utc(2026, 4, 29, hour);

MoodEntry _entry({
  String id = 'm1',
  String userId = _userA,
  MoodType mood = MoodType.happy,
  int intensity = 3,
  String text = 'sunshine',
  DateTime? createdAt,
  DateTime? updatedAt,
  List<String> mediaRefs = const [],
}) {
  return MoodEntry(
    id: id,
    userId: userId,
    mood: mood,
    intensity: intensity,
    text: text,
    createdAt: createdAt ?? _atHour(10),
    updatedAt: updatedAt,
    mediaRefs: mediaRefs,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MoodDatabase db;
  late MoodDao moodDao;
  late SyncQueueDao queueDao;
  late _FakeMoodFirestoreDatasource fakeRemote;
  late _FakeMoodSyncManager fakeSync;
  late StreamController<bool> connectivity;
  late SharedPreferences prefs;
  late DateTime currentClock;

  setUp(() async {
    db = MoodDatabase.forTesting(NativeDatabase.memory());
    moodDao = db.moodDao;
    queueDao = db.syncQueueDao;
    fakeRemote = _FakeMoodFirestoreDatasource();
    connectivity = StreamController<bool>.broadcast();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeSync = _FakeMoodSyncManager(
      moodDao: moodDao,
      syncQueueDao: queueDao,
      remote: fakeRemote,
      connectivity: connectivity.stream,
      deviceIdGetter: () => _deviceA,
      prefs: prefs,
    );
    // The fake's superclass constructor starts a real periodic timer +
    // connectivity subscription; tear them down before the in-memory db is
    // closed so no late callback hits a closed executor.
    addTearDown(() async {
      await fakeSync.shutdown();
      await connectivity.close();
      await db.close();
    });
    currentClock = _atHour(12); // 2h after default entry createdAt — non-locked
  });

  MoodRepositoryImpl buildRepo({bool offlineFirst = true}) {
    return MoodRepositoryImpl(
      datasource: fakeRemote,
      moodDao: moodDao,
      syncQueueDao: queueDao,
      syncManager: fakeSync,
      deviceIdGetter: () => _deviceA,
      offlineFirstEnabled: () => offlineFirst,
      clock: () => currentClock,
    );
  }

  // -------------------------------------------------------------------------
  // Offline-first path (default — flag = true)
  // -------------------------------------------------------------------------

  group('offline-first path', () {
    test(
      'save() writes to Drift, enqueues create, no Firestore call',
      () async {
        final repo = buildRepo();
        final result = await repo.save(_entry(id: 'local-1'));

        expect(result, isA<Ok<MoodEntry, MoodFailure>>());
        final row = await moodDao.getById('local-1');
        expect(row, isNotNull);
        expect(row!.syncState, MoodSyncState.pending);
        expect(row.deviceId, _deviceA);
        // Sync queue contains exactly one create row.
        expect(await queueDao.length(), 1);
        final queued = await queueDao.peekNextDue(now: 1 << 60);
        expect(queued!.operation, SyncOperation.create);
        final payload = jsonDecode(queued.payload) as Map<String, dynamic>;
        expect(payload['id'], 'local-1');
        // No Firestore traffic on the offline-first happy path.
        expect(fakeRemote.createCalls, isEmpty);
        expect(fakeRemote.updateCalls, isEmpty);
        // Manager kicked once.
        expect(fakeSync.kickCount, 1);
      },
    );

    test(
      'save() returns Ok immediately even when network would fail',
      () async {
        // Even though the fake would throw on .create, the offline-first path
        // never calls it: the user write must succeed.
        fakeRemote.createThrows = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );

        final repo = buildRepo();
        final result = await repo.save(_entry(id: 'local-2'));
        expect(result, isA<Ok<MoodEntry, MoodFailure>>());
        expect(fakeRemote.createCalls, isEmpty);
        // Throw was never armed → still pending on the field (defensive
        // sanity check that the path didn't sneak a remote call).
        expect(fakeRemote.createThrows, isNotNull);
      },
    );

    test(
      'update() on non-locked entry writes Drift + enqueues update',
      () async {
        // Seed a row first so this is a real update.
        final saved = await buildRepo().save(_entry(id: 'm-up'));
        expect(saved, isA<Ok<MoodEntry, MoodFailure>>());
        // Drain the queue manually — clear the queue + reset kick counter so the
        // next assertion is clean.
        await queueDao.dequeue((await queueDao.peekNextDue(now: 1 << 60))!.id);
        fakeSync.kickCount = 0;

        final repo = buildRepo();
        final updated = _entry(
          id: 'm-up',
          text: 'edited',
          createdAt: _atHour(11),
        );
        final result = await repo.update(updated);
        expect(result, isA<Ok<MoodEntry, MoodFailure>>());

        final row = await moodDao.getById('m-up');
        expect(row!.note, 'edited');
        expect(row.syncState, MoodSyncState.pending);
        expect(await queueDao.length(), 1);
        final queued = await queueDao.peekNextDue(now: 1 << 60);
        expect(queued!.operation, SyncOperation.update);
        expect(fakeRemote.updateCalls, isEmpty);
        expect(fakeSync.kickCount, 1);
      },
    );

    test(
      'update() on locked entry returns Err(locked); Drift NOT touched',
      () async {
        // 25h-old entry → locked.
        currentClock = _atHour(10).add(const Duration(hours: 25));
        final repo = buildRepo();
        final lockedEntry = _entry(id: 'm-lock', createdAt: _atHour(10));
        final result = await repo.update(lockedEntry);
        expect(result, isA<Err<MoodEntry, MoodFailure>>());
        expect(
          (result as Err<MoodEntry, MoodFailure>).failure,
          isA<MoodFailure>(),
        );
        // Lock failure surface check: same `MoodFailure.locked()` instance type.
        expect(result.failure.message, contains('older than 24h'));
        // No Drift mutation.
        expect(await moodDao.getById('m-lock'), isNull);
        expect(await queueDao.length(), 0);
        expect(fakeSync.kickCount, 0);
      },
    );

    test(
      'delete() on non-locked entry: soft-deletes and enqueues delete',
      () async {
        // Seed.
        await buildRepo().save(_entry(id: 'm-del'));
        // Reset queue state so the assertions are clean.
        while ((await queueDao.length()) > 0) {
          final r = await queueDao.peekNextDue(now: 1 << 60);
          await queueDao.dequeue(r!.id);
        }
        fakeSync.kickCount = 0;

        final repo = buildRepo();
        final result = await repo.delete(userId: _userA, id: 'm-del');
        expect(result, isA<Ok<void, MoodFailure>>());
        // Soft-delete: the row still exists but is tombstoned.
        final row = await moodDao.getById('m-del');
        expect(row, isNotNull);
        expect(row!.deletedAt, isNotNull);
        // watchAllForUser excludes tombstoned rows.
        final live = await moodDao.watchAllForUser(_userA).first;
        expect(live.where((r) => r.id == 'm-del'), isEmpty);
        expect(await queueDao.length(), 1);
        final queued = await queueDao.peekNextDue(now: 1 << 60);
        expect(queued!.operation, SyncOperation.delete);
        expect(fakeRemote.deleteCalls, isEmpty);
        expect(fakeSync.kickCount, 1);
      },
    );

    test(
      'delete() on locked entry → Err(locked); Drift NOT touched (NEW COVERAGE)',
      () async {
        // Seed a fresh entry, then move the clock past 24h.
        await buildRepo().save(_entry(id: 'm-lock-del'));
        currentClock = _atHour(10).add(const Duration(hours: 25));

        final repo = buildRepo();
        final result = await repo.delete(userId: _userA, id: 'm-lock-del');
        expect(result, isA<Err<void, MoodFailure>>());
        expect(
          (result as Err<void, MoodFailure>).failure.message,
          contains('older than 24h'),
        );
        // Drift row NOT tombstoned.
        final row = await moodDao.getById('m-lock-del');
        expect(row, isNotNull);
        expect(row!.deletedAt, isNull);
        // No delete row queued.
        final queue = await queueDao.peekAllDue(now: 1 << 60);
        expect(
          queue.where((r) => r.operation == SyncOperation.delete),
          isEmpty,
        );
      },
    );

    test('delete() of non-existent id → Err(notFound)', () async {
      final repo = buildRepo();
      final result = await repo.delete(userId: _userA, id: 'ghost');
      expect(result, isA<Err<void, MoodFailure>>());
      final failure = (result as Err<void, MoodFailure>).failure;
      expect(failure.message, contains('not found'));
    });

    test(
      'watchAll() streams from Drift; rows inserted via DAO appear',
      () async {
        final repo = buildRepo();
        final emissions = <List<MoodEntry>>[];
        final sub = repo.watchAll(userId: _userA).listen(emissions.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);

        // Direct DAO insert — the repository must surface it.
        await moodDao.upsertFromLocal(
          MoodEntriesCompanion.insert(
            id: 'd1',
            userId: _userA,
            mood: 'calm',
            intensity: 2,
            note: 'breath',
            createdAt: _atHour(11).millisecondsSinceEpoch,
            updatedAt: Value(_atHour(11).millisecondsSinceEpoch),
            syncState: MoodSyncState.synced,
            deviceId: _deviceA,
          ),
        );

        // Drift's `watch` is async — give it a few microtasks.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final flat = emissions.expand((e) => e).toList();
        expect(
          flat.where((e) => e.id == 'd1'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      },
    );

    test('findById() reads from Drift; absent id → notFound', () async {
      await buildRepo().save(_entry(id: 'find-me'));
      final repo = buildRepo();

      final hit = await repo.findById(userId: _userA, id: 'find-me');
      expect(hit, isA<Ok<MoodEntry, MoodFailure>>());
      expect((hit as Ok<MoodEntry, MoodFailure>).value.id, 'find-me');
      // Firestore must not be queried.
      expect(fakeRemote.findByIdCalls, isEmpty);

      final miss = await repo.findById(userId: _userA, id: 'ghost');
      expect(miss, isA<Err<MoodEntry, MoodFailure>>());
      expect(
        (miss as Err<MoodEntry, MoodFailure>).failure.message,
        contains('not found'),
      );
    });

    test('save() rejects out-of-range intensity (defence-in-depth)', () async {
      final repo = buildRepo();
      // Bypass the create() factory by constructing the entity directly.
      final bogus = MoodEntry(
        id: 'bad',
        userId: _userA,
        mood: MoodType.happy,
        intensity: 9, // out of 1..5
        text: '',
        createdAt: _atHour(10),
      );
      final result = await repo.save(bogus);
      expect(result, isA<Err<MoodEntry, MoodFailure>>());
      expect(await moodDao.getById('bad'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Cloud-only fallback path (flag = false)
  // -------------------------------------------------------------------------

  group('cloud-only fallback (flag = false)', () {
    test('save() calls _datasource.create; Drift NOT touched', () async {
      final repo = buildRepo(offlineFirst: false);
      final result = await repo.save(_entry(id: 'cloud-1'));
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      expect(fakeRemote.createCalls, hasLength(1));
      expect(await moodDao.getById('cloud-1'), isNull);
      expect(await queueDao.length(), 0);
      expect(fakeSync.kickCount, 0);
    });

    test('update() on non-locked entry calls _datasource.update', () async {
      // Seed Firestore so update lands on something.
      fakeRemote.seed(
        MoodEntryDto(
          id: 'cu-1',
          userId: _userA,
          mood: 'happy',
          intensity: 3,
          text: 'before',
          createdAt: Timestamp.fromDate(_atHour(10)),
          updatedAt: Timestamp.fromDate(_atHour(10)),
          mediaRefs: const [],
        ),
      );
      final repo = buildRepo(offlineFirst: false);
      final result = await repo.update(
        _entry(id: 'cu-1', text: 'after', createdAt: _atHour(11)),
      );
      expect(result, isA<Ok<MoodEntry, MoodFailure>>());
      expect(fakeRemote.updateCalls, hasLength(1));
    });

    test(
      'update() on locked entry → Err(locked) (S2 behavior preserved)',
      () async {
        currentClock = _atHour(10).add(const Duration(hours: 25));
        final repo = buildRepo(offlineFirst: false);
        final result = await repo.update(
          _entry(id: 'cu-lock', createdAt: _atHour(10)),
        );
        expect(result, isA<Err<MoodEntry, MoodFailure>>());
        expect(fakeRemote.updateCalls, isEmpty);
      },
    );

    test(
      'delete() on locked entry → Err(locked) (NEW guard applies to BOTH paths)',
      () async {
        // Seed Firestore with a 25h-old entry so the cloud-side findById
        // returns a "locked" DTO.
        fakeRemote.seed(
          MoodEntryDto(
            id: 'cd-lock',
            userId: _userA,
            mood: 'happy',
            intensity: 3,
            text: '',
            createdAt: Timestamp.fromDate(_atHour(10)),
            updatedAt: Timestamp.fromDate(_atHour(10)),
            mediaRefs: const [],
          ),
        );
        currentClock = _atHour(10).add(const Duration(hours: 25));

        final repo = buildRepo(offlineFirst: false);
        final result = await repo.delete(userId: _userA, id: 'cd-lock');
        expect(result, isA<Err<void, MoodFailure>>());
        expect(
          (result as Err<void, MoodFailure>).failure.message,
          contains('older than 24h'),
        );
        // Cloud delete NOT called — guard rejected before the network hop.
        expect(fakeRemote.deleteCalls, isEmpty);
      },
    );

    test('delete() on non-locked entry calls _datasource.delete', () async {
      fakeRemote.seed(
        MoodEntryDto(
          id: 'cd-1',
          userId: _userA,
          mood: 'happy',
          intensity: 3,
          text: '',
          createdAt: Timestamp.fromDate(_atHour(11)),
          updatedAt: Timestamp.fromDate(_atHour(11)),
          mediaRefs: const [],
        ),
      );
      final repo = buildRepo(offlineFirst: false);
      final result = await repo.delete(userId: _userA, id: 'cd-1');
      expect(result, isA<Ok<void, MoodFailure>>());
      expect(fakeRemote.deleteCalls, hasLength(1));
      expect(fakeRemote.deleteCalls.first.id, 'cd-1');
    });

    test('delete() of non-existent id → Err(notFound)', () async {
      final repo = buildRepo(offlineFirst: false);
      final result = await repo.delete(userId: _userA, id: 'ghost');
      expect(result, isA<Err<void, MoodFailure>>());
      expect(fakeRemote.deleteCalls, isEmpty);
    });
  });
}
