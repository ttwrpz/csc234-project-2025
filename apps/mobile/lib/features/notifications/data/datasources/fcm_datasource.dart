import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/notifications_settings.dart';

/// Outcome of a [FcmDatasource.requestPermission] call.
///
/// Mirrors the subset of `AuthorizationStatus` that matters for the
/// toggle: granted vs. not. `provisional` (iOS) is treated as granted -
/// the user can still receive non-interruptive cheer-up pushes.
enum FcmPermissionOutcome { granted, denied }

/// Public VAPID key for web push subscriptions. Generate via Firebase
/// Console → Project Settings → Cloud Messaging → Web configuration →
/// "Generate key pair". The public half is safe to ship in client code
/// - the browser uses it to subscribe; the matching private half stays
/// in Firebase. Leave empty to fall back to platform-default behaviour
/// (Android only - web `getToken` will return `null`).
const String _kWebVapidPublicKey =
    'BOTljqdiD_OL2ti5FpqeG0e0g5LmRp9c8kx69VMMSJm26GYqX2Rn6SDnpnevIh3oxrXldoUGZguyuFah-PcCMw0';

/// Thin wrapper around `firebase_messaging`. Centralises platform
/// detection and the permission-request → token-fetch flow so the
/// repository can stay free of platform conditionals.
class FcmDatasource {
  FcmDatasource(this._messaging);

  final FirebaseMessaging _messaging;

  /// Requests notification permission. On Android < 13 this returns
  /// `granted` immediately because permission is granted at install
  /// time. On Web this triggers the browser permission prompt - but
  /// only when `web/firebase-messaging-sw.js` is registered with a
  /// real Firebase config (a placeholder config silently denies the
  /// prompt).
  ///
  /// **Android 13+ note:** `firebase_messaging.requestPermission()`
  /// does NOT show the runtime POST_NOTIFICATIONS dialog - the plugin
  /// only reads `NotificationManagerCompat.areNotificationsEnabled()`
  /// and returns `notDetermined`/`denied` without prompting. To
  /// actually surface the OS dialog we route through
  /// `flutter_local_notifications`'s Android-specific
  /// `requestNotificationsPermission()`, then fall back to
  /// `firebase_messaging` to register the FCM token routing. The
  /// matching AndroidManifest entry (`POST_NOTIFICATIONS`) is already
  /// declared in `apps/mobile/android/app/src/main/AndroidManifest.xml`.
  Future<FcmPermissionOutcome> requestPermission() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // `null` = Android < 13 (no runtime permission concept - already
      // granted at install). `true` = user just allowed. `false` =
      // user just denied. Fall through to firebase_messaging in the
      // first two cases so FCM's internal state stays consistent with
      // the OS state.
      final granted = await androidImpl?.requestNotificationsPermission();
      if (granted == false) return FcmPermissionOutcome.denied;
    }
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return FcmPermissionOutcome.granted;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        return FcmPermissionOutcome.denied;
    }
  }

  /// Reads the device's current permission state WITHOUT prompting.
  /// Used by the onboarding notifications slide so the UI can show
  /// "already granted" or "already denied" up front instead of
  /// firing the prompt on first paint. Returns `null` for the
  /// notDetermined case (so callers can render a neutral "Allow"
  /// CTA that opens the prompt on tap).
  Future<FcmPermissionOutcome?> currentPermission() async {
    final settings = await _messaging.getNotificationSettings();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return FcmPermissionOutcome.granted;
      case AuthorizationStatus.denied:
        return FcmPermissionOutcome.denied;
      case AuthorizationStatus.notDetermined:
        return null;
    }
  }

  /// Returns the device's current FCM registration token, or `null` if
  /// the platform did not produce one (e.g. Web missing VAPID config,
  /// emulator without Play Services). On web we forward the project's
  /// VAPID public key so the browser can subscribe to FCM's push
  /// endpoint; without it, `getToken()` resolves to `null` and the
  /// repository surfaces `tokenUnavailable` to the toggle UI.
  Future<String?> getToken() {
    if (kIsWeb && _kWebVapidPublicKey.isNotEmpty) {
      return _messaging.getToken(vapidKey: _kWebVapidPublicKey);
    }
    return _messaging.getToken();
  }

  /// Hot stream of refresh events: FCM occasionally rotates a device's
  /// token (server change, restore from backup). Subscribers should
  /// upsert the new value.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Best-effort platform classifier. Used to tag each registered
  /// token in Firestore so the Cloud Function can fan out per-platform
  /// when payload shape diverges.
  NotificationPlatform currentPlatform() {
    if (kIsWeb) return NotificationPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return NotificationPlatform.android;
    }
  }
}
