import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore wrapper for the
/// `users/{userId}.insightsDisclaimerAcked` boolean field.
///
/// The user doc itself is the carrier - there is no dedicated
/// sub-collection. We use `set(merge: true)` so writing this single
/// field never clobbers neighbouring profile fields (`displayName`,
/// `tokenBalance`, `unlockedSkins`, etc.).
///
/// Stream behaviour: emits `false` when the user doc is missing OR the
/// field is absent. New users always see `false` until the first ack,
/// matching the spec default. The downstream ack dialog drives that
/// transition; this datasource never writes `false`.
class DisclaimerFirestoreDatasource {
  const DisclaimerFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _fieldKey = 'insightsDisclaimerAcked';

  /// Streams the boolean ack state.
  Stream<bool> watchAckState({required String userId}) {
    final ref = _firestore.collection('users').doc(userId);
    return ref.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final raw = data[_fieldKey];
      return raw is bool ? raw : false;
    });
  }

  /// Writes `insightsDisclaimerAcked: true` via merge. Throws on
  /// Firestore errors; the repository impl translates them to
  /// `DisclaimerFailure`.
  Future<void> ack({required String userId}) async {
    final ref = _firestore.collection('users').doc(userId);
    await ref.set(const <String, Object?>{
      _fieldKey: true,
    }, SetOptions(merge: true));
  }
}
