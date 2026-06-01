import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/notifications_settings.dart';
import '../notifications_dto.dart';

/// Thin Firestore wrapper for `users/{uid}/settings/notifications`.
/// Centralises the transaction-based dedup-then-write semantics so the
/// repository stays free of Firestore types.
///
/// Also owns the one-time legacy-to-tiered settings migration. Docs
/// created before the per-tier opt-outs landed only carry
/// `cheerUpEnabled` + `tokens` + `updatedAt`. The first time such a doc
/// is read (via [watch] or the transaction inside [mutate]), we mirror
/// the legacy `cheerUpEnabled` value to the three new tier flags and
/// persist them back with `set(merge: true)`. Subsequent reads see all
/// four flags and skip the migration.
class NotificationsFirestoreDatasource {
  NotificationsFirestoreDatasource(
    this._firestore, {
    Logger logger = const Logger('notifications.firestore'),
  }) : _logger = logger;

  final FirebaseFirestore _firestore;
  final Logger _logger;

  static const String _settingsDocId = 'notifications';

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc(_settingsDocId);

  Stream<NotificationsSettings> watch(String uid) {
    return _docRef(uid).snapshots().asyncMap((snap) async {
      if (!snap.exists) return NotificationsSettings.initial();
      final data = snap.data();
      if (NotificationsSettingsDto.needsTierMigration(data)) {
        // Fire-and-forget the repair write; the stream still yields the
        // migrated entity immediately so the UI never sees the legacy
        // shape. `.set(merge: true)` is idempotent - a concurrent
        // mutate() that lands first will simply re-overwrite the same
        // four flags.
        final migrated = NotificationsSettingsDto.migratedFromLegacy(data!);
        try {
          await _docRef(uid).set(
            NotificationsSettingsDto.toFirestoreMerge(settings: migrated),
            SetOptions(merge: true),
          );
          // Log without uid per CLAUDE.md PII rules.
          _logger.info(
            'notifications.migration',
            data: {'migrated': true, 'cheerUpEnabled': migrated.cheerUpEnabled},
          );
        } on FirebaseException catch (e) {
          // Migration is best-effort: a denied / offline write must not
          // surface as a stream error. The next successful read retries
          // automatically because the doc still has the legacy shape.
          _logger.warn('notifications.migration write failed: ${e.code}');
        }
        return migrated;
      }
      return NotificationsSettingsDto.fromFirestore(snap);
    });
  }

  /// Reads-modifies-writes the settings doc atomically, applying [mutate]
  /// to the current document state (or [NotificationsSettings.initial] if
  /// the doc doesn't exist yet).
  ///
  /// If the existing doc is in the legacy shape, [mutate] sees the
  /// migrated entity (tier flags mirrored from `cheerUpEnabled`) and
  /// the merge-write writes the full four-flag schema. This keeps the
  /// migration in lock-step with any caller-initiated mutation - a user
  /// who toggles cheer-up off as their first post-update action gets
  /// the schema repaired in the same transaction.
  Future<void> mutate(
    String uid,
    NotificationsSettings Function(NotificationsSettings current) mutate,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _docRef(uid);
      final snap = await tx.get(ref);
      final existing = _existingFromSnap(snap);
      final next = mutate(existing);
      tx.set(
        ref,
        NotificationsSettingsDto.toFirestoreMerge(settings: next),
        SetOptions(merge: true),
      );
    });
  }

  NotificationsSettings _existingFromSnap(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    if (!snap.exists) return NotificationsSettings.initial();
    final data = snap.data();
    if (NotificationsSettingsDto.needsTierMigration(data)) {
      _logger.info(
        'notifications.migration',
        data: {'migrated': true, 'cheerUpEnabled': data!['cheerUpEnabled']},
      );
      return NotificationsSettingsDto.migratedFromLegacy(data);
    }
    return NotificationsSettingsDto.fromFirestore(snap);
  }
}
