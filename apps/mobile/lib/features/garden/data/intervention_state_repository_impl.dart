import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/intervention_state_repository.dart';
import 'datasources/intervention_state_firestore_datasource.dart';
import 'intervention_state_storage.dart';

/// Firestore-primary implementation of [InterventionStateRepository].
///
/// Per ADR-0008, the cooldown / escalation anchors live in
/// `users/{uid}/interventionState/current` (single doc, schemaV: 1).
/// `InterventionStateStorage` (SharedPreferences) is the offline-read
/// mirror.
///
/// Read path:
///  1. Try Firestore (server-or-cache). On success → mirror locally,
///     return the cloud copy.
///  2. On Firestore failure → fall back to the mirror.
///
/// Write path:
///  1. Hit Firestore first (`set(merge: true)` for plain writes;
///     transactions for the conditional `writeFirstTriggeredAtIfNull`
///     so the read-then-write is race-free across multiple devices).
///  2. On success → mirror locally, return `Ok`.
///  3. On Firestore failure → still mirror locally so the local
///     detector is correct, return `Err(InterventionStateFailure)`. The
///     next successful read will reconcile from cloud.
class InterventionStateRepositoryImpl implements InterventionStateRepository {
  InterventionStateRepositoryImpl({
    required InterventionStateFirestoreDatasource datasource,
    required InterventionStateStorage mirror,
    required String? Function() uidGetter,
    Logger logger = const Logger('garden.intervention.repo'),
  }) : _datasource = datasource,
       _mirror = mirror,
       _uidGetter = uidGetter,
       _logger = logger;

  final InterventionStateFirestoreDatasource _datasource;
  final InterventionStateStorage _mirror;
  final String? Function() _uidGetter;
  final Logger _logger;

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      // No signed-in user → treat as fresh state (mirror is empty too on
      // a first-launch / signed-out path). This avoids surfacing a noisy
      // failure to the detector pipeline before auth completes.
      return Ok(_readMirror());
    }

    try {
      final pair = await _datasource.read(uid);
      final anchors = InterventionAnchors(
        lastTriggeredAt: pair.lastTriggeredAt,
        firstTriggeredAt: pair.firstTriggeredAt,
      );
      // Mirror so the offline-read path stays warm on next cold start.
      await _writeMirror(anchors);
      return Ok(anchors);
    } on FirebaseException catch (e) {
      _logger.warn(
        'Firestore read failed; falling back to mirror',
        data: e.code,
      );
      return Ok(_readMirror());
    } catch (_) {
      _logger.warn('Unknown read failure; falling back to mirror');
      return Ok(_readMirror());
    }
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      // No uid → still mirror so the local detector keeps a valid
      // cooldown anchor across cold launches; surface Err so the caller
      // can decide whether to retry once auth resolves.
      await _mirror.writeLastTriggeredAt(now);
      return const Err(InterventionStateFailure.network());
    }

    try {
      await _datasource.writeLastTriggeredAt(uid, now);
      await _mirror.writeLastTriggeredAt(now);
      return const Ok(null);
    } on FirebaseException catch (e) {
      // Always update mirror even on cloud failure so the local detector
      // honours the cooldown gate. Caller decides whether to retry.
      await _mirror.writeLastTriggeredAt(now);
      return Err(_failureFor(e));
    } catch (e) {
      await _mirror.writeLastTriggeredAt(now);
      return Err(InterventionStateFailure.unknown(e));
    }
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  ) async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      if (_mirror.readFirstTriggeredAt() == null) {
        await _mirror.writeFirstTriggeredAt(now);
      }
      return const Err(InterventionStateFailure.network());
    }

    try {
      final persisted = await _datasource.writeFirstTriggeredAtIfNull(uid, now);
      // Mirror with whatever value won the transaction — that may NOT
      // be `now` if a concurrent device anchored first.
      if (persisted != null) {
        await _mirror.writeFirstTriggeredAt(persisted);
      }
      return const Ok(null);
    } on FirebaseException catch (e) {
      if (_mirror.readFirstTriggeredAt() == null) {
        await _mirror.writeFirstTriggeredAt(now);
      }
      return Err(_failureFor(e));
    } catch (e) {
      if (_mirror.readFirstTriggeredAt() == null) {
        await _mirror.writeFirstTriggeredAt(now);
      }
      return Err(InterventionStateFailure.unknown(e));
    }
  }

  @override
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt() async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      await _mirror.clearFirstTriggeredAt();
      return const Err(InterventionStateFailure.network());
    }

    try {
      await _datasource.clearFirstTriggeredAt(uid);
      await _mirror.clearFirstTriggeredAt();
      return const Ok(null);
    } on FirebaseException catch (e) {
      await _mirror.clearFirstTriggeredAt();
      return Err(_failureFor(e));
    } catch (e) {
      await _mirror.clearFirstTriggeredAt();
      return Err(InterventionStateFailure.unknown(e));
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────

  InterventionAnchors _readMirror() => InterventionAnchors(
    lastTriggeredAt: _mirror.readLastTriggeredAt(),
    firstTriggeredAt: _mirror.readFirstTriggeredAt(),
  );

  Future<void> _writeMirror(InterventionAnchors anchors) async {
    final last = anchors.lastTriggeredAt;
    if (last != null) {
      await _mirror.writeLastTriggeredAt(last);
    }
    final first = anchors.firstTriggeredAt;
    if (first != null) {
      await _mirror.writeFirstTriggeredAt(first);
    } else {
      // Cloud says null → reflect that locally too. Keeps escalation gate
      // honest across cold-launches after a 48h-clear.
      await _mirror.clearFirstTriggeredAt();
    }
  }

  InterventionStateFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const InterventionStateFailure.permission();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const InterventionStateFailure.network();
      default:
        return InterventionStateFailure.unknown(e);
    }
  }
}
