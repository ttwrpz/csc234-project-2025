import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weekly_garden.dart';

/// Thin Firestore wrapper for the `users/{userId}/weeklyGardens/{weekId}`
/// collection.
///
/// One doc per ISO-8601 week; `weekId` IS the doc id, formatted
/// `YYYY-Www`. The collection is write-once-on-archive - the firestore
/// rule denies update + delete, so [createWeeklyGarden] is the only
/// permitted mutation. We use `set(merge: false)` (not `add`) so the
/// caller can pin the doc id to `weekId`, which the rule's regex
/// validates.
///
/// Uses `WeeklyGarden.toJson()` / `fromJson()` directly - the entity is
/// already JSON-serialisable, no separate DTO needed. The Firestore
/// document shape matches the entity's JSON shape 1:1.
///
/// Collisions: when the doc already exists, Firestore emits a
/// `'already-exists'` error code (the rule rejects the second
/// `allow create` because the resource already exists). The repository
/// impl maps that code to [HarvestFailure.alreadyArchived].
class WeeklyGardensFirestoreDatasource {
  const WeeklyGardensFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Writes a new archived week. Throws on Firestore errors; the
  /// repository impl translates them to [HarvestFailure].
  ///
  /// Implemented via a transaction that first verifies the doc does
  /// not already exist - without that pre-check, `set(merge: false)`
  /// on a device with relaxed rules would silently overwrite a
  /// previously-archived week. The transaction makes the write-once
  /// semantics enforceable in tests with a fake datasource that
  /// doesn't run firestore.rules.
  Future<void> createWeeklyGarden({
    required String userId,
    required WeeklyGarden garden,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyGardens')
        .doc(garden.weekId);

    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(ref);
      if (existing.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'weeklyGardens/${garden.weekId} already exists',
        );
      }
      txn.set(ref, garden.toJson(), SetOptions(merge: false));
    });
  }

  /// Streams the user's archive newest-first. The History tile feed
  /// reads this provider directly; subsequent harvests append a new doc
  /// which the snapshot listener picks up without a manual refresh.
  Stream<List<WeeklyGarden>> watchHistory({required String userId}) {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyGardens')
        .orderBy('archivedAt', descending: true);
    return col.snapshots().map(
      (snap) => snap.docs
          .map((doc) => WeeklyGarden.fromJson(doc.data()))
          .toList(growable: false),
    );
  }

  /// One-shot read of a single archived week. Returns `null` when the
  /// doc does not exist (e.g. a deep link to a week the user hasn't
  /// harvested yet - surfaces as `notFound` in the controller).
  Future<WeeklyGarden?> getByWeekId({
    required String userId,
    required String weekId,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyGardens')
        .doc(weekId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return null;
    return WeeklyGarden.fromJson(data);
  }
}
