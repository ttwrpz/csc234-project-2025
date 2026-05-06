import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/notifications_settings.dart';
import '../notifications_dto.dart';

/// Thin Firestore wrapper for `users/{uid}/settings/notifications`.
/// Centralises the transaction-based dedup-then-write semantics so the
/// repository stays free of Firestore types.
class NotificationsFirestoreDatasource {
  const NotificationsFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _settingsDocId = 'notifications';

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc(_settingsDocId);

  Stream<NotificationsSettings> watch(String uid) {
    return _docRef(uid).snapshots().map((snap) {
      if (!snap.exists) return NotificationsSettings.initial();
      return NotificationsSettingsDto.fromFirestore(snap);
    });
  }

  /// Reads-modifies-writes the settings doc atomically, applying [mutate]
  /// to the current document state (or [NotificationsSettings.initial] if
  /// the doc doesn't exist yet).
  Future<void> mutate(
    String uid,
    NotificationsSettings Function(NotificationsSettings current) mutate,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _docRef(uid);
      final snap = await tx.get(ref);
      final existing = snap.exists
          ? NotificationsSettingsDto.fromFirestore(snap)
          : NotificationsSettings.initial();
      final next = mutate(existing);
      tx.set(
        ref,
        NotificationsSettingsDto.toFirestoreMerge(settings: next),
        SetOptions(merge: true),
      );
    });
  }
}
