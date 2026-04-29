import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import '../datasources/mood_firestore_datasource.dart';
import '../dtos/mood_entry_dto.dart';
import '../local/mood_dao.dart';
import '../local/mood_database.dart';
import '../local/sync_queue_dao.dart';
import '../mappers/mood_entry_mapper.dart';

// Backoff and lifecycle constants per ADR-0004 §"Sync state machine".
const Duration _kPollInterval = Duration(seconds: 60);
const Duration _kSeedTimeout = Duration(seconds: 10);
const Duration _kBaseBackoff = Duration(seconds: 5);
const Duration _kMaxBackoff = Duration(hours: 1);
const int _kMaxAttempts = 12;

// Far-future epoch parking for poison-pill / terminal rows. The UI will later
// surface a "tap to retry" affordance that resets `retry_after`.
const Duration _kPoisonRetryAfter = Duration(days: 365);
const Duration _kManualRetryRequired = Duration(days: 365);

const int _kDrainBatchSize = 32;

/// Drift mutation queue drainer + Firestore listener owner.
///
/// PR-2 wires the manager but does **not** route reads through Drift — that's
/// PR-3 (`MoodRepositoryImpl` cutover). The manager runs on the main isolate;
/// `package:synchronized`'s [Lock] serialises drain attempts within this
/// isolate. Sprint 4's WorkManager hand-off must replace this with a SQLite
/// advisory lock so background isolates can claim queue rows safely.
class MoodSyncManager {
  MoodSyncManager({
    required MoodDao moodDao,
    required SyncQueueDao syncQueueDao,
    required MoodFirestoreDatasource remote,
    required MoodEntryMapper mapper,
    required Stream<bool> connectivity,
    required String Function() deviceIdGetter,
    required SharedPreferences prefs,
    DateTime Function() clock = _defaultClock,
    Random? random,
    Logger logger = const Logger('mood.sync'),
  }) : _moodDao = moodDao,
       _syncQueueDao = syncQueueDao,
       _remote = remote,
       _mapper = mapper,
       _deviceIdGetter = deviceIdGetter,
       _prefs = prefs,
       _clock = clock,
       _random = random ?? Random(),
       _logger = logger {
    // Connectivity edge `false → true` wakes the drain. Hold the subscription
    // for [shutdown] cancellation.
    _connectivitySub = connectivity.listen((online) {
      _isOnline = online;
      if (online) kick();
    });

    // Belt-and-braces: even with no events, drain every minute while the app
    // is in the foreground (Sprint 3 single-isolate constraint).
    _pollTimer = Timer.periodic(_kPollInterval, (_) => kick());
  }

  static DateTime _defaultClock() => DateTime.now();

  final MoodDao _moodDao;
  final SyncQueueDao _syncQueueDao;
  final MoodFirestoreDatasource _remote;
  // Mapper retained for future PR-3 wiring (entity reconstruction during
  // bootstrap diagnostics) and to keep the constructor signature stable.
  // ignore: unused_field
  final MoodEntryMapper _mapper;
  final String Function() _deviceIdGetter;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final Random _random;
  final Logger _logger;

  final Lock _lock = Lock();
  late final StreamSubscription<bool> _connectivitySub;
  late final Timer _pollTimer;

  /// Latest connectivity reading. Defaults to `true` so the first drain after
  /// boot proceeds; the connectivity listener corrects within milliseconds.
  bool _isOnline = true;

  String? _attachedUid;
  StreamSubscription<List<MoodEntryDto>>? _listenerSub;
  Set<String> _previousRemoteIds = const <String>{};

  bool _shutdown = false;

  // ---------------------------------------------------------------------------
  // Public surface
  // ---------------------------------------------------------------------------

  /// Idempotent. Call on sign-in, app resume, or whenever the manager needs to
  /// (re-)attach to a user's data. Detaches any existing listener for a
  /// different uid first.
  Future<void> bootstrap(String uid) async {
    if (_shutdown) return;
    if (_attachedUid == uid && _listenerSub != null) return;

    if (_listenerSub != null) {
      await _listenerSub!.cancel();
      _listenerSub = null;
      _previousRemoteIds = const <String>{};
    }

    _attachedUid = uid;

    // One-shot bootstrap seed (idempotent — the SharedPreferences flag is
    // checked first; `upsertFromRemote` is itself idempotent under LWW).
    final seededKey = 'mood.seeded.$uid';
    if (_prefs.getBool(seededKey) != true) {
      try {
        final firstSnapshot = await _remote
            .watchAll(uid)
            .first
            .timeout(_kSeedTimeout);
        final seededIds = <String>{};
        for (final dto in firstSnapshot) {
          seededIds.add(dto.id);
          await _moodDao.upsertFromRemote(
            _toCompanion(
              dto,
              deviceId: _deviceIdGetter(),
              syncState: MoodSyncState.synced,
            ),
          );
        }
        // Prime the diff baseline so the live listener's *next* emission can
        // detect remote-side removals against the seeded set.
        _previousRemoteIds = seededIds;
        await _prefs.setBool(seededKey, true);
      } on TimeoutException catch (_) {
        _logger.warn('bootstrap seed timed out; live listener will backfill');
      } catch (e) {
        _logger.warn(
          'bootstrap seed failed; live listener will backfill',
          data: e.runtimeType.toString(),
        );
      }
    }

    // Live listener.
    _listenerSub = _remote
        .watchAll(uid)
        .listen(
          (dtos) => unawaited(_applyRemoteSnapshot(dtos)),
          onError: (Object e, StackTrace st) {
            _logger.error('firestore listener error', error: e, stackTrace: st);
          },
        );

    // Drain anything that may have queued during the previous session.
    kick();
  }

  /// Cancel listener + timers. Safe to call multiple times.
  Future<void> shutdown() async {
    if (_shutdown) return;
    _shutdown = true;
    _pollTimer.cancel();
    await _connectivitySub.cancel();
    if (_listenerSub != null) {
      await _listenerSub!.cancel();
      _listenerSub = null;
    }
    _attachedUid = null;
    _previousRemoteIds = const <String>{};
  }

  /// Wake the drain loop. No-op if offline; reentrant calls await the in-flight
  /// drain via the [Lock].
  void kick() {
    if (_shutdown) return;
    unawaited(Future.microtask(_drain));
  }

  // ---------------------------------------------------------------------------
  // Drain
  // ---------------------------------------------------------------------------

  Future<void> _drain() => _lock.synchronized(_drainImpl);

  Future<void> _drainImpl() async {
    if (_shutdown) return;
    if (!_isOnline) return;

    // Loop until the queue is empty or every remaining row is parked in the
    // future (peekAllDue filters by retry_after <= now).
    while (true) {
      final now = _clock().millisecondsSinceEpoch;
      final batch = await _syncQueueDao.peekAllDue(
        now: now,
        limit: _kDrainBatchSize,
      );
      if (batch.isEmpty) return;

      for (final row in batch) {
        if (_shutdown) return;
        await _processRow(row);
      }
    }
  }

  Future<void> _processRow(SyncQueueRow row) async {
    final entryId = row.entryId;
    try {
      await _moodDao.markSyncing(entryId);
      switch (row.operation) {
        case SyncOperation.create:
          final dto = _decodeDto(row.payload);
          final saved = await _remote.create(dto);
          final updatedAt = _epochOf(saved.updatedAt ?? saved.createdAt);
          await _moodDao.markSynced(entryId, updatedAt: updatedAt);
          await _syncQueueDao.dequeue(row.id);
        case SyncOperation.update:
          final dto = _decodeDto(row.payload);
          final saved = await _remote.update(dto);
          final updatedAt = _epochOf(saved.updatedAt ?? saved.createdAt);
          await _moodDao.markSynced(entryId, updatedAt: updatedAt);
          await _syncQueueDao.dequeue(row.id);
        case SyncOperation.delete:
          final dto = _decodeDto(row.payload);
          await _remote.delete(userId: dto.userId, id: entryId);
          await _moodDao.hardDelete(entryId);
          await _syncQueueDao.dequeue(row.id);
        default:
          // Defensive: unknown op is parked, not retried.
          await _syncQueueDao.markFailed(
            row.id,
            retryAfter: _farFutureRetry(),
            code: 'unknown-operation',
            message: 'Unsupported operation: ${row.operation}',
          );
      }
    } on FirebaseException catch (e) {
      await _handleRowFailure(row, code: e.code, message: e.message ?? '');
    } catch (e) {
      await _handleRowFailure(row, code: 'unknown', message: e.toString());
    }
  }

  Future<void> _handleRowFailure(
    SyncQueueRow row, {
    required String code,
    required String message,
  }) async {
    // Poison pill: rules-rejected writes can never succeed without code or
    // permission changes; park indefinitely without bumping attempt_count.
    if (code == 'permission-denied') {
      _logger.warn('sync poison pill', data: 'code=$code id=${row.id}');
      await _moodDao.markError(row.entryId);
      await _syncQueueDao.markFailed(
        row.id,
        retryAfter: _farFutureRetry(),
        code: code,
        message: message,
        bumpAttempt: false,
      );
      return;
    }

    final nextAttemptCount = row.attemptCount + 1;
    if (nextAttemptCount >= _kMaxAttempts) {
      _logger.warn(
        'sync attempts exhausted',
        data: 'id=${row.id} attempt=$nextAttemptCount code=$code',
      );
      await _moodDao.markError(row.entryId);
      await _syncQueueDao.markFailed(
        row.id,
        retryAfter: _terminalRetry(),
        code: code,
        message: message,
      );
      return;
    }

    final delay = _backoff(row.attemptCount);
    _logger.warn(
      'sync attempt failed',
      data:
          'id=${row.id} attempt=${row.attemptCount} '
          'next=${row.attemptCount + 1} code=$code delayMs=${delay.inMilliseconds}',
    );
    await _moodDao.markError(row.entryId);
    await _syncQueueDao.markFailed(
      row.id,
      retryAfter: _clock().millisecondsSinceEpoch + delay.inMilliseconds,
      code: code,
      message: message,
    );
  }

  /// `min(2^attempt × 5s, 1h)` with full jitter in `[0.5 × delay, delay]`.
  Duration _backoff(int attempt) {
    final shift = attempt.clamp(0, 30); // avoid int overflow
    final raw = _kBaseBackoff * (1 << shift);
    final capped = raw > _kMaxBackoff ? _kMaxBackoff : raw;
    final cappedMs = capped.inMilliseconds;
    final lower = cappedMs ~/ 2;
    final span = cappedMs - lower;
    final jitterMs = lower + _random.nextInt(span <= 0 ? 1 : span + 1);
    return Duration(milliseconds: jitterMs);
  }

  int _farFutureRetry() =>
      _clock().millisecondsSinceEpoch + _kPoisonRetryAfter.inMilliseconds;

  int _terminalRetry() =>
      _clock().millisecondsSinceEpoch + _kManualRetryRequired.inMilliseconds;

  // ---------------------------------------------------------------------------
  // Remote snapshot diff
  // ---------------------------------------------------------------------------

  Future<void> _applyRemoteSnapshot(List<MoodEntryDto> dtos) async {
    if (_shutdown) return;
    final currentIds = <String>{};
    for (final dto in dtos) {
      currentIds.add(dto.id);
      try {
        await _moodDao.upsertFromRemote(
          _toCompanion(
            dto,
            deviceId: _deviceIdGetter(),
            syncState: MoodSyncState.synced,
          ),
        );
      } catch (e) {
        _logger.warn('listener upsert failed', data: 'type=${e.runtimeType}');
      }
    }

    // Removed = ids present in the previous emission but not the current one.
    final removed = _previousRemoteIds.difference(currentIds);
    for (final id in removed) {
      try {
        await _moodDao.hardDelete(id);
      } catch (e) {
        _logger.warn(
          'listener hardDelete failed',
          data: 'type=${e.runtimeType}',
        );
      }
    }
    _previousRemoteIds = currentIds;
  }

  // ---------------------------------------------------------------------------
  // DTO ↔ Drift
  // ---------------------------------------------------------------------------

  static int _epochOf(Timestamp ts) => ts.toDate().millisecondsSinceEpoch;

  MoodEntriesCompanion _toCompanion(
    MoodEntryDto dto, {
    required String deviceId,
    required String syncState,
  }) {
    return MoodEntriesCompanion(
      id: Value(dto.id),
      userId: Value(dto.userId),
      mood: Value(dto.mood),
      intensity: Value(dto.intensity),
      note: Value(dto.text),
      createdAt: Value(_epochOf(dto.createdAt)),
      updatedAt: Value(dto.updatedAt == null ? null : _epochOf(dto.updatedAt!)),
      mediaRefs: Value(dto.mediaRefs),
      syncState: Value(syncState),
      deviceId: Value(deviceId),
    );
  }

  /// JSON-decode a queue payload. Schema is owned by PR-3's repo, but PR-2
  /// must already understand it so the drain works.
  ///
  /// Expected fields: `id`, `userId`, `mood`, `intensity`, `text`, `createdAt`
  /// (epoch ms), `updatedAt` (epoch ms or null), `mediaRefs` (`List<String>`).
  MoodEntryDto _decodeDto(String payload) {
    final raw = jsonDecode(payload) as Map<String, dynamic>;
    final createdMs =
        (raw['createdAt'] as num?)?.toInt() ?? _clock().millisecondsSinceEpoch;
    final updatedMs = (raw['updatedAt'] as num?)?.toInt();
    return MoodEntryDto(
      id: raw['id'] as String? ?? '',
      userId: raw['userId'] as String? ?? '',
      mood: raw['mood'] as String? ?? 'okay',
      intensity: (raw['intensity'] as num?)?.toInt() ?? 3,
      text: raw['text'] as String? ?? '',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(createdMs),
      updatedAt: updatedMs == null
          ? null
          : Timestamp.fromMillisecondsSinceEpoch(updatedMs),
      mediaRefs: ((raw['mediaRefs'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
