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

/// Thin wrapper around `firebase_messaging`. Centralises platform
/// detection and the permission-request → token-fetch flow so the
/// repository can stay free of platform conditionals.
class FcmDatasource {
  FcmDatasource(this._messaging);

  final FirebaseMessaging _messaging;

  /// Requests notification permission. On Android < 13 this returns
  /// `granted` immediately because permission is granted at install
  /// time. On Web this triggers the browser permission prompt.
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
  /// emulator without Play Services).
  Future<String?> getToken() => _messaging.getToken();

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
