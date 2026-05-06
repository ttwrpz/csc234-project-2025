import 'package:core/core.dart';

import 'notification_failure.dart';
import 'notifications_settings.dart';

/// Contract for the cheer-up notifications subsystem.
///
/// Implementations live in `data/`; they wrap `firebase_messaging`,
/// `cloud_firestore` and `shared_preferences`. The domain layer never
/// imports any of those — see CLAUDE.md "the one rule that cannot
/// break".
///
/// All write methods return `Result<void, NotificationFailure>` so
/// callers (controllers, use cases) can pattern-match without try/catch.
abstract class FcmTokenRepository {
  /// Fetches the device's current FCM token (requesting permission first
  /// when the platform requires it) and writes it to
  /// `users/{uid}/settings/notifications.tokens`. Idempotent: re-running
  /// with an unchanged token simply refreshes its `lastSeenAt`.
  ///
  /// Returns [NotificationFailure.permissionDenied] if the user declined
  /// the OS prompt; [NotificationFailure.tokenUnavailable] if FCM did
  /// not produce a token (e.g. Web missing VAPID config).
  Future<Result<void, NotificationFailure>> upsertToken({required String uid});

  /// Toggles the cheer-up push channel on/off for [uid]. The Cloud
  /// Function check this flag before composing a payload (HB-003
  /// §"Notification fan-out").
  Future<Result<void, NotificationFailure>> setEnabled({
    required String uid,
    required bool enabled,
  });

  /// Streams the user's current notifications settings document, or
  /// `null` if no document exists yet (first-run state). Returns `null`
  /// from the method itself when [uid] is empty — callers gate on
  /// auth-state before subscribing.
  Stream<NotificationsSettings>? watchSettings({required String uid});
}
