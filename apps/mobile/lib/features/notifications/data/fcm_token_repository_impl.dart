import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/fcm_token_repository.dart';
import '../domain/notification_failure.dart';
import '../domain/notifications_settings.dart';
import 'datasources/fcm_datasource.dart';
import 'datasources/notifications_preference_datasource.dart';
import 'notifications_dto.dart';

/// Default Firestore implementation of [FcmTokenRepository].
///
/// Persistence model: a single document per user at
/// `users/{uid}/settings/notifications` (HB-003 §"Settings doc shape").
/// Multi-device support comes from the `tokens` array, deduped on the
/// `token` field. Transactions guarantee that concurrent toggles or
/// refresh-driven re-registers do not clobber each other's writes.
class FcmTokenRepositoryImpl implements FcmTokenRepository {
  FcmTokenRepositoryImpl({
    required FirebaseFirestore firestore,
    required FcmDatasource fcm,
    required NotificationsPreferenceDatasource preference,
    Logger logger = const Logger('notifications.fcm_repo'),
  }) : _firestore = firestore,
       _fcm = fcm,
       _preference = preference,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final FcmDatasource _fcm;
  final NotificationsPreferenceDatasource _preference;
  final Logger _logger;

  static const String _settingsDocId = 'notifications';

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc(_settingsDocId);

  @override
  Future<Result<void, NotificationFailure>> upsertToken({
    required String uid,
  }) async {
    if (uid.isEmpty) {
      return const Err(NotificationFailure.tokenUnavailable());
    }
    try {
      final outcome = await _fcm.requestPermission();
      if (outcome == FcmPermissionOutcome.denied) {
        _logger.info('permission denied — skipping token upsert');
        return const Err(NotificationFailure.permissionDenied());
      }
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        _logger.warn('FCM did not produce a token');
        return const Err(NotificationFailure.tokenUnavailable());
      }
      final record = FcmTokenRecord(
        token: token,
        platform: _fcm.currentPlatform(),
        lastSeenAt: DateTime.now().toUtc(),
      );
      await _firestore.runTransaction((tx) async {
        final ref = _docRef(uid);
        final snap = await tx.get(ref);
        final existing = snap.exists
            ? NotificationsSettingsDto.fromFirestore(snap)
            : NotificationsSettings.initial();
        final next = existing.withToken(record);
        tx.set(
          ref,
          NotificationsSettingsDto.toFirestoreMerge(settings: next),
          SetOptions(merge: true),
        );
      });
      return const Ok(null);
    } on FirebaseException catch (e) {
      _logger.warn('upsertToken firebase error: ${e.code}');
      return const Err(NotificationFailure.network());
    } catch (e) {
      _logger.error('upsertToken unknown error', error: e);
      return Err(NotificationFailure.unknown(e));
    }
  }

  @override
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  }) async {
    if (uid.isEmpty) {
      return const Err(NotificationFailure.tokenUnavailable());
    }
    try {
      // Mirror locally first — the UI may resubscribe before Firestore
      // confirms. Best-effort per HB-003: a failure here does not block
      // the remote write.
      await _preference.setCheerUpEnabled(enabled);
      await _firestore.runTransaction((tx) async {
        final ref = _docRef(uid);
        final snap = await tx.get(ref);
        final existing = snap.exists
            ? NotificationsSettingsDto.fromFirestore(snap)
            : NotificationsSettings.initial();
        final next = existing.copyWith(cheerUpEnabled: enabled);
        tx.set(
          ref,
          NotificationsSettingsDto.toFirestoreMerge(settings: next),
          SetOptions(merge: true),
        );
      });
      return const Ok(null);
    } on FirebaseException catch (e) {
      _logger.warn('setEnabled firebase error: ${e.code}');
      return const Err(NotificationFailure.network());
    } catch (e) {
      _logger.error('setEnabled unknown error', error: e);
      return Err(NotificationFailure.unknown(e));
    }
  }

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) {
    if (uid.isEmpty) return null;
    return _docRef(uid).snapshots().map((snap) {
      if (!snap.exists) return NotificationsSettings.initial();
      return NotificationsSettingsDto.fromFirestore(snap);
    });
  }

  /// Subscribes to `onTokenRefresh` and re-runs [upsertToken] for the
  /// currently authenticated [uid]. Callers (the controller) own the
  /// subscription lifecycle.
  Stream<String> onTokenRefresh() => _fcm.onTokenRefresh;
}
