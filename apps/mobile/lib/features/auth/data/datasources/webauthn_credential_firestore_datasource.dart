import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/webauthn_credential.dart';

/// Watches the registered WebAuthn credential at
/// `users/{uid}/webauthn/{credentialId}`.
///
/// Single-credential per account, so the stream emits at most one
/// entry - the first doc in the collection, or `null` when the
/// collection is empty. The Privacy UI status tile and the PIN verify
/// screen both consume this stream.
///
/// **Field projection note:** the full credential doc carries
/// `publicKeyBase64`, `counter`, `aaguid`, and `transports` - all
/// server-managed and not used by the client. This datasource projects
/// onto the [WebauthnCredential] subset (credentialId / createdAt /
/// lastUsedAt / failedAttempts / lockedUntil) so the domain entity
/// stays minimal.
class WebauthnCredentialFirestoreDatasource {
  const WebauthnCredentialFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _credentialsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('webauthn');

  /// Streams the (single) registered credential for [userId].
  /// Returns null when no credential exists or after the user removes
  /// the one they had registered.
  Stream<WebauthnCredential?> watch({required String userId}) {
    return _credentialsRef(userId).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return _fromFirestoreDoc(snap.docs.first);
    });
  }

  WebauthnCredential _fromFirestoreDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return WebauthnCredential(
      credentialId: doc.id,
      createdAt: _toDate(data['createdAt']) ?? DateTime.now().toUtc(),
      lastUsedAt: _toDate(data['lastUsedAt']),
      failedAttempts: (data['failedAttempts'] as num?)?.toInt() ?? 0,
      lockedUntil: _toDate(data['lockedUntil']),
    );
  }

  static DateTime? _toDate(Object? v) {
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is String) return DateTime.tryParse(v)?.toUtc();
    return null;
  }
}
