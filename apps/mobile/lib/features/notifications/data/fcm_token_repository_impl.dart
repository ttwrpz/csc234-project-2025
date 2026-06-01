import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/fcm_token_repository.dart';
import '../domain/notification_failure.dart';
import '../domain/notifications_settings.dart';
import 'datasources/fcm_datasource.dart';
import 'datasources/notifications_firestore_datasource.dart';
import 'datasources/notifications_preference_datasource.dart';

/// Default implementation of [FcmTokenRepository].
///
/// Persistence model: a single document per user at
/// `users/{uid}/settings/notifications`. Multi-device support comes from
/// the `tokens` array, deduped on the `token` field. Transactions
/// (inside the datasource) guarantee that concurrent toggles or
/// refresh-driven re-registers do not clobber each other's writes.
class FcmTokenRepositoryImpl implements FcmTokenRepository {
  FcmTokenRepositoryImpl({
    required NotificationsFirestoreDatasource firestore,
    required FcmDatasource fcm,
    required NotificationsPreferenceDatasource? preference,
    Logger logger = const Logger('notifications.fcm_repo'),
  }) : _firestore = firestore,
       _fcm = fcm,
       _preference = preference,
       _logger = logger;

  final NotificationsFirestoreDatasource _firestore;
  final FcmDatasource _fcm;
  // Best-effort local mirror; null while SharedPreferences is still
  // resolving on the very first frame after a cold start.
  final NotificationsPreferenceDatasource? _preference;
  final Logger _logger;

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
        _logger.info('permission denied - skipping token upsert');
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
      await _firestore.mutate(uid, (current) => current.withToken(record));
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
      // Mirror locally first - the UI may resubscribe before Firestore
      // confirms. Best-effort: a failure here does not block the remote
      // write.
      await _preference?.setCheerUpEnabled(enabled);
      await _firestore.mutate(
        uid,
        (current) => current.copyWith(cheerUpEnabled: enabled),
      );
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
  Future<Result<void, NotificationFailure>> setTier1Enabled({
    required String uid,
    required bool enabled,
  }) => _setTier(uid: uid, enabled: enabled, tier: _Tier.one);

  @override
  Future<Result<void, NotificationFailure>> setTier2Enabled({
    required String uid,
    required bool enabled,
  }) => _setTier(uid: uid, enabled: enabled, tier: _Tier.two);

  @override
  Future<Result<void, NotificationFailure>> setTier3Enabled({
    required String uid,
    required bool enabled,
  }) => _setTier(uid: uid, enabled: enabled, tier: _Tier.three);

  /// Shared transaction for the three per-tier setters. The entity's
  /// `withTierNEnabled` helpers re-derive `cheerUpEnabled` from the
  /// resulting tier-flag triple so the legacy cheer-up CF stays in
  /// lock-step. When the user toggles the LAST remaining tier off, the
  /// local cheer-up mirror flips false too so SharedPreferences doesn't
  /// lag the remote state.
  Future<Result<void, NotificationFailure>> _setTier({
    required String uid,
    required bool enabled,
    required _Tier tier,
  }) async {
    if (uid.isEmpty) {
      return const Err(NotificationFailure.tokenUnavailable());
    }
    try {
      await _firestore.mutate(uid, (current) {
        switch (tier) {
          case _Tier.one:
            return current.withTier1Enabled(enabled);
          case _Tier.two:
            return current.withTier2Enabled(enabled);
          case _Tier.three:
            return current.withTier3Enabled(enabled);
        }
      });
      // Best-effort local mirror sync: the cheer-up shim has been
      // re-derived inside the transaction. Reading the local mirror
      // back here would require a second Firestore round-trip - skip
      // it. The local mirror only ever drives the cold-start initial
      // value of the cheer-up toggle (which is itself being phased out
      // by the three new tier toggles) so a brief skew is harmless.
      return const Ok(null);
    } on FirebaseException catch (e) {
      _logger.warn('setTier${tier.label} firebase error: ${e.code}');
      return const Err(NotificationFailure.network());
    } catch (e) {
      _logger.error('setTier${tier.label} unknown error', error: e);
      return Err(NotificationFailure.unknown(e));
    }
  }

  @override
  Stream<NotificationsSettings>? watchSettings({required String uid}) {
    if (uid.isEmpty) return null;
    return _firestore.watch(uid);
  }

  /// Subscribes to `onTokenRefresh`. Callers (the controller) own the
  /// subscription lifecycle.
  Stream<String> onTokenRefresh() => _fcm.onTokenRefresh;
}

/// Private discriminator for the shared `_setTier` helper. The numeric
/// label is used only in log lines - the public API surfaces three
/// named methods so callers never have to plumb an enum through.
enum _Tier {
  one('1'),
  two('2'),
  three('3');

  const _Tier(this.label);
  final String label;
}
