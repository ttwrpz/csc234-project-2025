import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/intervention_state_repository.dart';
import 'intervention_state_storage.dart';

/// Firestore-primary implementation of [InterventionStateRepository].
///
/// Per ADR-0008, the cooldown / escalation anchors live in
/// `users/{uid}/interventionState/current` (single doc, schemaV: 1):
///
/// ```
/// {
///   lastTriggeredAt: Timestamp | null,
///   firstTriggeredAt: Timestamp | null,
///   schemaV: 1,
/// }
/// ```
///
/// `InterventionStateStorage` (SharedPreferences) is the offline-read mirror.
///
/// Read path:
///  1. Try Firestore (server-or-cache). On success → mirror locally, return.
///  2. On Firestore failure → fall back to the mirror, return its anchors.
///  3. On both failing → `Err(InterventionStateFailure)`.
///
/// Write path:
///  1. Hit Firestore first (`set(merge: true)` for plain writes; transactions
///     for the conditional `writeFirstTriggeredAtIfNull` so the read-then-
///     write is race-free across multiple devices).
///  2. On success → mirror locally, return `Ok`.
///  3. On Firestore failure → still mirror locally so the local detector is
///     correct, return `Err(InterventionStateFailure.network())`. The next
///     successful read will reconcile from cloud.
class InterventionStateRepositoryImpl implements InterventionStateRepository {
  InterventionStateRepositoryImpl({
    required FirebaseFirestore firestore,
    required InterventionStateStorage mirror,
    required String? Function() uidGetter,
    Logger logger = const Logger('garden.intervention.repo'),
  }) : _firestore = firestore,
       _mirror = mirror,
       _uidGetter = uidGetter,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final InterventionStateStorage _mirror;
  final String? Function() _uidGetter;
  final Logger _logger;

  /// Schema version stamped on every write. Bump (and add a migration) only
  /// when the document shape itself changes — not when fields are added in
  /// a backwards-compatible way.
  static const int _schemaV = 1;

  static const String _docId = 'current';
  static const String _kLast = 'lastTriggeredAt';
  static const String _kFirst = 'firstTriggeredAt';
  static const String _kSchemaV = 'schemaV';

  DocumentReference<Map<String, dynamic>>? _docRefFor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('interventionState')
        .doc(_docId);
  }

  @override
  Future<Result<InterventionAnchors, InterventionStateFailure>> read() async {
    final uid = _uidGetter();
    final ref = _docRefFor(uid);
    if (ref == null) {
      // No signed-in user → treat as fresh state (mirror is empty too on a
      // first-launch / signed-out path). This avoids surfacing a noisy
      // failure to the detector pipeline before auth completes.
      return Ok(_readMirror());
    }

    try {
      final snap = await ref.get();
      final anchors = _parseSnapshot(snap);
      // Mirror so the offline-read path stays warm on next cold start.
      await _writeMirror(anchors);
      return Ok(anchors);
    } on FirebaseException catch (e) {
      _logger.warn(
        'Firestore read failed; falling back to mirror',
        data: e.code,
      );
      return Ok(_readMirror());
    } catch (e) {
      _logger.warn('Unknown read failure; falling back to mirror');
      return Ok(_readMirror());
    }
  }

  @override
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  ) async {
    final uid = _uidGetter();
    final ref = _docRefFor(uid);
    // Mirror first when no uid (signed-out edge case): the local detector
    // still functions across cold launches even without a cloud copy.
    if (ref == null) {
      await _mirror.writeLastTriggeredAt(now);
      return const Err(InterventionStateFailure.network());
    }

    try {
      await ref.set({
        _kLast: Timestamp.fromDate(now.toUtc()),
        _kSchemaV: _schemaV,
      }, SetOptions(merge: true));
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
    final ref = _docRefFor(uid);
    if (ref == null) {
      // No-op cloud-side; only mirror if not already set so we keep
      // idempotency locally too.
      if (_mirror.readFirstTriggeredAt() == null) {
        await _mirror.writeFirstTriggeredAt(now);
      }
      return const Err(InterventionStateFailure.network());
    }

    try {
      // Transaction makes the read-then-write race-free: two devices both
      // calling `writeFirstTriggeredAtIfNull` within the same trigger cycle
      // will resolve to a single `firstTriggeredAt` value on the server.
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final existing = snap.data()?[_kFirst];
        if (existing is Timestamp) {
          // Already set — no-op to preserve the original anchor.
          return;
        }
        tx.set(ref, {
          _kFirst: Timestamp.fromDate(now.toUtc()),
          _kSchemaV: _schemaV,
        }, SetOptions(merge: true));
      });
      // Mirror the post-write state. Reading the doc back keeps the mirror
      // in step with whatever value won the transaction — that may NOT be
      // `now` if a concurrent device anchored first.
      final after = await ref.get();
      final anchors = _parseSnapshot(after);
      await _writeMirror(anchors);
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
    final ref = _docRefFor(uid);
    if (ref == null) {
      await _mirror.clearFirstTriggeredAt();
      return const Err(InterventionStateFailure.network());
    }

    try {
      await ref.set({
        _kFirst: null,
        _kSchemaV: _schemaV,
      }, SetOptions(merge: true));
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

  InterventionAnchors _parseSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data();
    if (data == null) return const InterventionAnchors();
    final last = data[_kLast];
    final first = data[_kFirst];
    return InterventionAnchors(
      lastTriggeredAt: last is Timestamp ? last.toDate().toLocal() : null,
      firstTriggeredAt: first is Timestamp ? first.toDate().toLocal() : null,
    );
  }

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
