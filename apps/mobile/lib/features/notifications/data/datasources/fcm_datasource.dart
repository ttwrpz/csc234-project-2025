import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../../domain/notifications_settings.dart';

/// Outcome of a [FcmDatasource.requestPermission] call.
///
/// Mirrors the subset of `AuthorizationStatus` that matters for the
/// toggle: granted vs. not. `provisional` (iOS) is treated as granted —
/// the user can still receive non-interruptive cheer-up pushes.
enum FcmPermissionOutcome { granted, denied }

/// Public VAPID key for web push subscriptions. Generate via Firebase
/// Console → Project Settings → Cloud Messaging → Web configuration →
/// "Generate key pair". The public half is safe to ship in client code
/// — the browser uses it to subscribe; the matching private half stays
/// in Firebase. Leave empty to fall back to platform-default behaviour
/// (Android only — web `getToken` will return `null`).
const String _kWebVapidPublicKey = '';

/// Thin wrapper around `firebase_messaging`. Centralises platform
/// detection and the permission-request → token-fetch flow so the
/// repository can stay free of platform conditionals.
class FcmDatasource {
  FcmDatasource(this._messaging);

  final FirebaseMessaging _messaging;

  /// Requests notification permission. On Android < 13 this returns
  /// `granted` immediately because permission is granted at install
  /// time. On Web this triggers the browser permission prompt — but
  /// only when `web/firebase-messaging-sw.js` is registered with a
  /// real Firebase config (the placeholder config silently denied the
  /// prompt; v1.5 polish fix).
  Future<FcmPermissionOutcome> requestPermission() async {
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
      case TargetPlatform.iOS:
        return NotificationPlatform.iOS;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return NotificationPlatform.android;
    }
  }
}
