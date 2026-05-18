import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/entities/mood_entry.dart';
import '../domain/mood_failure.dart';
import '../domain/mood_repository.dart';
import 'datasources/mood_firestore_datasource.dart';
import 'local/mood_dao.dart';
import 'local/mood_database.dart';
import 'local/sync_queue_dao.dart';
import 'mappers/mood_drift_mapper.dart';
import 'mappers/mood_entry_mapper.dart';
import 'sync/mood_sync_manager.dart';

/// Repository for mood entries.
///
/// When [offlineFirstEnabled] returns `true` (the default), reads stream from
/// Drift and writes go to Drift + the sync queue, with the `MoodSyncManager`
/// draining the queue to Firestore. The cloud is never the UI's source of
/// truth on this path — the user always sees their own writes instantly, and
/// offline writes succeed.
///
/// When the flag is `false`, the implementation falls back to the
/// Firestore-only path so the cutover is reversible without a hotfix (canary
/// rollback). The 24h-lock guard applies to BOTH paths on update *and* delete.
class MoodRepositoryImpl implements MoodRepository {
  MoodRepositoryImpl({
    required MoodFirestoreDatasource datasource,
    required MoodDao moodDao,
    required SyncQueueDao syncQueueDao,
    required MoodSyncManager syncManager,
    required String Function() deviceIdGetter,
    bool Function() offlineFirstEnabled = _alwaysOfflineFirst,
    MoodEntryMapper mapper = const MoodEntryMapper(),
    MoodDriftMapper driftMapper = const MoodDriftMapper(),
    Logger logger = const Logger('mood.repo'),
    DateTime Function() clock = DateTime.now,
  }) : _datasource = datasource,
       _moodDao = moodDao,
       _syncQueueDao = syncQueueDao,
       _syncManager = syncManager,
       _deviceIdGetter = deviceIdGetter,
       _offlineFirstEnabled = offlineFirstEnabled,
       _mapper = mapper,
       _driftMapper = driftMapper,
       _logger = logger,
       _clock = clock;

  final MoodFirestoreDatasource _datasource;
  final MoodDao _moodDao;
  final SyncQueueDao _syncQueueDao;
  final MoodSyncManager _syncManager;
  final String Function() _deviceIdGetter;
  final bool Function() _offlineFirstEnabled;
  final MoodEntryMapper _mapper;
  final MoodDriftMapper _driftMapper;
  final Logger _logger;
  final DateTime Function() _clock;

  static bool _alwaysOfflineFirst() => true;

  // ---------------------------------------------------------------------------
  // watchAll
  // ---------------------------------------------------------------------------

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) {
    if (_offlineFirstEnabled()) {
      return _moodDao.watchAllForUser(userId).map((rows) {
        // Filter out malformed rows; never throw from a stream so the UI
        // doesn't blow up if one row's mood column was hand-edited or a
        // future schema introduces an unknown enum value.
        final entries = <MoodEntry>[];
        for (final row in rows) {
          final result = _driftMapper.rowToEntity(row);
          switch (result) {
            case Ok(:final value):
              entries.add(value);
            case Err(:final failure):
              // PII rule: log only the failure category, never the entry text
              // or userId+text correlation.
              _logger.warn('skipping malformed row', data: failure.message);
          }
        }
        return entries;
      });
    }
    return _datasource.watchAll(userId).map((dtos) {
      final entries = <MoodEntry>[];
      for (final dto in dtos) {
        final result = _mapper.toEntity(dto);
        switch (result) {
          case Ok(:final value):
            entries.add(value);
          case Err(:final failure):
            _logger.warn('skipping malformed entry', data: failure.message);
        }
      }
      return entries;
    });
  }

  // ---------------------------------------------------------------------------
  // findById
  // ---------------------------------------------------------------------------

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) async {
    if (_offlineFirstEnabled()) {
      try {
        final row = await _moodDao.getById(id);
        if (row == null) return Err(MoodFailure.notFound(id));
        return _driftMapper.rowToEntity(row);
      } catch (e) {
        return Err(MoodFailure.unknown(e));
      }
    }
    try {
      final dto = await _datasource.findById(userId: userId, id: id);
      if (dto == null) return Err(MoodFailure.notFound(id));
      return _mapper.toEntity(dto);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  // ---------------------------------------------------------------------------
  // save
  // ---------------------------------------------------------------------------

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async {
    // Defence-in-depth: the entity factory blocks invalid values, but the data
    // layer guards anyway — a hand-built entity instance from a non-factory
    // call site shouldn't reach Drift unchecked.
    if (entry.intensity < 1 || entry.intensity > 5) {
      return Err(MoodFailure.invalidIntensity(entry.intensity));
    }
    if (entry.text.length > 500) {
      return Err(MoodFailure.textTooLong(entry.text.length));
    }

    if (_offlineFirstEnabled()) {
      return _writeLocal(entry, operation: SyncOperation.create);
    }

    try {
      final dto = _mapper.toDtoForCreate(
        userId: entry.userId,
        mood: entry.mood,
        intensity: entry.intensity,
        text: entry.text,
        mediaRefs: entry.mediaRefs,
      );
      final saved = await _datasource.create(dto);
      return _mapper.toEntity(saved);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  // ---------------------------------------------------------------------------
  // update
  // ---------------------------------------------------------------------------

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async {
    if (entry.isLocked(now: _clock())) {
      return const Err(MoodFailure.locked());
    }
    if (entry.intensity < 1 || entry.intensity > 5) {
      return Err(MoodFailure.invalidIntensity(entry.intensity));
    }
    if (entry.text.length > 500) {
      return Err(MoodFailure.textTooLong(entry.text.length));
    }

    if (_offlineFirstEnabled()) {
      return _writeLocal(entry, operation: SyncOperation.update);
    }

    try {
      final dto = _mapper
          .toDtoForCreate(
            userId: entry.userId,
            mood: entry.mood,
            intensity: entry.intensity,
            text: entry.text,
            mediaRefs: entry.mediaRefs,
          )
          .copyWith(id: entry.id);
      final saved = await _datasource.update(dto);
      return _mapper.toEntity(saved);
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  // ---------------------------------------------------------------------------
  // delete — lock guard applies to BOTH paths.
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async {
    if (_offlineFirstEnabled()) {
      try {
        final row = await _moodDao.getById(id);
        if (row == null) return Err(MoodFailure.notFound(id));

        final entityResult = _driftMapper.rowToEntity(row);
        switch (entityResult) {
          case Err(:final failure):
            _logger.warn('delete: malformed row', data: failure.message);
            return Err(failure);
          case Ok(:final value):
            if (value.isLocked(now: _clock())) {
              return const Err(MoodFailure.locked());
            }
            final nowMs = _clock().toUtc().millisecondsSinceEpoch;
            await _moodDao.transaction(() async {
              await _moodDao.softDelete(id, now: nowMs);
              await _syncQueueDao.enqueue(
                SyncQueueCompanion.insert(
                  entryId: id,
                  operation: SyncOperation.delete,
                  payload: jsonEncode({'userId': userId, 'id': id}),
                  createdAt: nowMs,
                ),
              );
            });
            _syncManager.kick();
            return const Ok(null);
        }
      } catch (e) {
        return Err(MoodFailure.unknown(e));
      }
    }

    // Cloud-only fallback: also gated by the lock guard.
    try {
      final dto = await _datasource.findById(userId: userId, id: id);
      if (dto == null) return Err(MoodFailure.notFound(id));
      final entityResult = _mapper.toEntity(dto);
      switch (entityResult) {
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value):
          if (value.isLocked(now: _clock())) {
            return const Err(MoodFailure.locked());
          }
          await _datasource.delete(userId: userId, id: id);
          return const Ok(null);
      }
    } on FirebaseException catch (e) {
      return Err(_firebaseToFailure(e));
    } catch (e) {
      return Err(MoodFailure.unknown(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Drift-first write path shared by `save` and `update`. Writes the row and
  /// enqueues the mutation in a single transaction so a crash between the two
  /// can never produce an in-memory entry that the cloud never hears about.
  Future<Result<MoodEntry, MoodFailure>> _writeLocal(
    MoodEntry entry, {
    required String operation,
  }) async {
    try {
      final nowMs = _clock().toUtc().millisecondsSinceEpoch;
      final companion = _driftMapper.entityToCompanion(
        entry,
        deviceId: _deviceIdGetter(),
        syncState: MoodSyncState.pending,
        updatedAtOverride: nowMs,
      );
      final payload = jsonEncode(_payloadForQueue(entry, updatedAtMs: nowMs));

      await _moodDao.transaction(() async {
        await _moodDao.upsertFromLocal(companion);
        await _syncQueueDao.enqueue(
          SyncQueueCompanion.insert(
            entryId: entry.id,
            operation: operation,
            payload: payload,
            createdAt: nowMs,
          ),
        );
      });
      _syncManager.kick();
      // Return the entity with the freshly-stamped updatedAt so callers (the
      // UI controller) reflect the same instant.
      return Ok(
        entry.copyWith(
          updatedAt: DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
        ),
      );
    } catch (e) {
      _logger.warn(
        'local write failed',
        data: 'op=$operation type=${e.runtimeType} msg=${e.toString()}',
      );
      return Err(MoodFailure.unknown(e));
    }
  }

  /// Build the JSON payload the sync worker will reconstitute into a
  /// `MoodEntryDto`. The wire-side `updatedAt` is overwritten by Firestore's
  /// `serverTimestamp()` inside `MoodEntryDto.toFirestoreOnUpdate()`, so the
  /// queue snapshot is fine using a plain client-clock epoch.
  Map<String, Object?> _payloadForQueue(
    MoodEntry entry, {
    required int updatedAtMs,
  }) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'mood': entry.mood.name,
      'intensity': entry.intensity,
      'text': entry.text,
      'createdAt': entry.createdAt.toUtc().millisecondsSinceEpoch,
      'updatedAt': updatedAtMs,
      'mediaRefs': entry.mediaRefs,
    };
  }

  MoodFailure _firebaseToFailure(FirebaseException e) {
    if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      return const MoodFailure.network();
    }
    return MoodFailure.server(e.code);
  }
}
