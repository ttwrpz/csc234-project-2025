import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore wrapper for the PIN hash sub-document.
///
/// Doc path: `users/{uid}/security/pin` (single doc). The fields are
/// fixed by the security rules' field allow-list - any new field
/// requires a rules change + security-reviewer pass.
///
/// This class deliberately speaks `Map<String, Object?>` rather than
/// any domain type. The repository owns the mapping in both directions.
class PinFirestoreDatasource {
  const PinFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Reference to the PIN hash doc for [userId].
  DocumentReference<Map<String, dynamic>> _ref(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('security')
      .doc('pin');

  /// Reads the PIN doc. Returns the raw field map, or `null` when the
  /// doc doesn't exist. Throws on permission-denied - the repository
  /// translates this into a [PinVerifyFailure.locked] when the rate
  /// limit gate fires.
  Future<Map<String, dynamic>?> read({required String userId}) async {
    final snap = await _ref(userId).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Writes the PIN doc. `set()` (not `update()`) is used so this works
  /// for both first-time setup and subsequent rotations / removals.
  /// The Firestore rule's field-allow-list ensures only the canonical
  /// fields land.
  Future<void> write({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return _ref(userId).set(data);
  }

  /// Increments `failedAttempts` (and optionally sets `lockedUntil`)
  /// atomically. Used by the verify path on wrong-PIN to bump the
  /// rate-limit anchor without re-deriving the hash.
  Future<void> bumpFailure({
    required String userId,
    required int newFailedAttempts,
    required DateTime? lockedUntil,
  }) {
    return _ref(userId).update({
      'failedAttempts': newFailedAttempts,
      'lockedUntil': lockedUntil == null
          ? null
          : Timestamp.fromDate(lockedUntil),
    });
  }

  /// Clears `failedAttempts` and `lockedUntil` after a successful
  /// verification.
  Future<void> clearFailures({required String userId}) {
    return _ref(userId).update({'failedAttempts': 0, 'lockedUntil': null});
  }
}
