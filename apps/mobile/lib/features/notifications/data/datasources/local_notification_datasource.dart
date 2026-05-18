import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around `flutter_local_notifications` for the cheer-up
/// channel. The intervention flow drives real notifications via FCM in
/// production; this datasource exists so the Settings debug zone can fire
/// a one-shot local notification to verify the system tray rendering
/// without waiting for a server push.
///
/// Web is a no-op: `flutter_local_notifications` has no Web impl, and
/// the browser FCM service worker owns its own permission flow. Callers
/// observe the returned `false` and surface an explanatory snackbar.
class LocalNotificationDatasource {
  LocalNotificationDatasource(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Notification id reserved for the debug ping. Picked deliberately
  /// high so it never collides with the FCM-dispatched cheer-up ids
  /// (which are message-id derived).
  static const int _debugNotificationId = 9001;

  Future<bool> fireDebugNotification() async {
    if (kIsWeb) return false;
    await _plugin.show(
      _debugNotificationId,
      'MoodBloom',
      'Test notification — this is what real cheer-up notifications look '
          'like.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cheer_up',
          'Cheer-up check-ins',
          channelDescription: 'Gentle reminders during heavier stretches.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
    return true;
  }
}

/// Provider exposing a fresh `FlutterLocalNotificationsPlugin` wrapped in
/// the debug datasource. The plugin is a thin handle around the platform
/// channel — constructing a new instance is cheap and avoids coupling
/// the debug surface to `main.dart`'s channel-registration plugin.
final localNotificationDatasourceProvider =
    Provider<LocalNotificationDatasource>(
      (_) => LocalNotificationDatasource(FlutterLocalNotificationsPlugin()),
    );
