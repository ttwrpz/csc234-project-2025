import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore wrapper for the `users/{uid}/interventionState/current`
/// document. Pulled out of [InterventionStateRepositoryImpl] so tests can
/// fake the cloud surface without instantiating a real
/// `FirebaseFirestore` (no `fake_cloud_firestore` dependency in the
/// mobile pubspec — see ADR-0004 / mood test fixtures for the pattern).
///
/// Returns raw `DateTime?` values rather than `Timestamp`s so the repo
/// stays free of cloud-types in its own logic. Throws on Firestore
/// errors; the repo catches and converts to `InterventionStateFailure`.
class InterventionStateFirestoreDatasource {
  const InterventionStateFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Schema version stamped on every write. Bump (and add a migration)
  /// only when the document shape itself changes.
  static const int schemaV = 1;

  static const String _docId = 'current';
  static const String _kLast = 'lastTriggeredAt';
  static const String _kFirst = 'firstTriggeredAt';
  static const String _kSchemaV = 'schemaV';

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('interventionState')
      .doc(_docId);

  Future<({DateTime? lastTriggeredAt, DateTime? firstTriggeredAt})> read(
    String uid,
  ) async {
    final snap = await _docRef(uid).get();
    final data = snap.data();
    if (data == null) return (lastTriggeredAt: null, firstTriggeredAt: null);
    final last = data[_kLast];
    final first = data[_kFirst];
    return (
      lastTriggeredAt: last is Timestamp ? last.toDate().toLocal() : null,
      firstTriggeredAt: first is Timestamp ? first.toDate().toLocal() : null,
    );
  }

  Future<void> writeLastTriggeredAt(String uid, DateTime now) async {
    await _docRef(uid).set({
      _kLast: Timestamp.fromDate(now.toUtc()),
      _kSchemaV: schemaV,
    }, SetOptions(merge: true));
  }

  /// Transactional conditional write — sets `firstTriggeredAt` only when
  /// the persisted value is `null`. Race-free across multiple devices.
  /// Returns the value that ended up persisted.
  Future<DateTime?> writeFirstTriggeredAtIfNull(
    String uid,
    DateTime now,
  ) async {
    final ref = _docRef(uid);
    return _firestore.runTransaction<DateTime?>((tx) async {
      final snap = await tx.get(ref);
      final existing = snap.data()?[_kFirst];
      if (existing is Timestamp) return existing.toDate().toLocal();
      tx.set(ref, {
        _kFirst: Timestamp.fromDate(now.toUtc()),
        _kSchemaV: schemaV,
      }, SetOptions(merge: true));
      return now;
    });
  }

  Future<void> clearFirstTriggeredAt(String uid) async {
    await _docRef(
      uid,
    ).set({_kFirst: null, _kSchemaV: schemaV}, SetOptions(merge: true));
  }
}
