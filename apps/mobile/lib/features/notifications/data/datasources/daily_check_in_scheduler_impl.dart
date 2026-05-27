import 'package:core/core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/daily_check_in_schedule.dart';
import '../../domain/daily_check_in_scheduler.dart';

/// Stable notification id for the self-set daily check-in. Distinct from
/// the debug ping (9001) and the FCM message-id-derived cheer-up ids so a
/// re-schedule cancels exactly this one reminder and nothing else.
const int dailyCheckInNotificationId = 9100;

/// Android channel for the daily check-in. Separate from the FCM
/// `cheer_up` channel so the user can mute one without the other and so
/// the system-settings channel label reads as a self-set reminder, not a
/// support nudge.
const String _channelId = 'daily_check_in';
const String _channelName = 'Daily check-in';
const String _channelDescription =
    'A reminder you set yourself to log how you feel.';

const _logger = Logger('DailyCheckInScheduler');

/// Real platform-bound [DailyCheckInScheduler] backed by
/// `flutter_local_notifications` + `timezone`.
///
/// Self-guards on Web (no plugin impl) and lazily initialises the plugin,
/// the Android channel, and the tz database on first use so it never
/// assumes `main.dart` ran a particular bootstrap step. PII-safe: the
/// notification copy is static and nothing about the user is logged.
class LocalDailyCheckInScheduler implements DailyCheckInScheduler {
  LocalDailyCheckInScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _pluginReady = false;
  bool _timezoneReady = false;

  @override
  Future<bool> schedule({required int hour, required int minute}) async {
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Non-Android native targets aren't a deliverable here (the app ships
    // Android + Web). Bail cleanly rather than half-scheduling.
    if (android == null) return false;

    await _ensurePluginInitialized();

    final granted = await android.requestNotificationsPermission() ?? false;
    if (!granted) {
      _logger.info('Daily check-in not armed: notifications permission denied');
      return false;
    }

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );

    final tzDate = _nextOccurrence(hour: hour, minute: minute);

    // Cancel-then-arm so changing the time never leaves two reminders.
    await _plugin.cancel(dailyCheckInNotificationId);
    await _plugin.zonedSchedule(
      dailyCheckInNotificationId,
      "How's your garden today?",
      'A quiet moment to log how you feel.',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // Inexact lets Android batch the alarm and avoids the restricted
      // SCHEDULE_EXACT_ALARM runtime grant for a gentle once-a-day nudge.
      // `allowWhileIdle` ensures it still lands when the device is dozing.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Repeat daily by matching only the time-of-day component.
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _logger.info('Daily check-in armed for $hour:$minute (local)');
    return true;
  }

  @override
  Future<void> cancel() async {
    if (kIsWeb) return;
    await _plugin.cancel(dailyCheckInNotificationId);
    _logger.info('Daily check-in cancelled');
  }

  /// Computes the next fire time in the device's local timezone. Defers
  /// the roll-forward rule to the pure-Dart [DailyCheckInSchedule] so the
  /// only thing this method adds is the tz wrapping.
  tz.TZDateTime _nextOccurrence({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    final next = DailyCheckInSchedule(
      enabled: true,
      hour: hour,
      minute: minute,
    ).nextOccurrenceAfter(now);
    return tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );
  }

  Future<void> _ensurePluginInitialized() async {
    if (!_timezoneReady) {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (e) {
        // Unknown or unresolvable zone name: fall back to UTC rather than
        // throwing. The reminder still fires daily; only the absolute
        // first-fire offset could drift by the UTC delta.
        _logger.warn('Falling back to UTC for daily check-in zone', data: e);
      }
      _timezoneReady = true;
    }
    if (!_pluginReady) {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _pluginReady = true;
    }
  }
}

/// Provider exposing the platform-bound scheduler. Constructs a fresh
/// plugin handle (cheap — it's a thin platform-channel wrapper), mirroring
/// `localNotificationDatasourceProvider`. Tests override this with a fake
/// recorder so no platform channel is ever touched.
final dailyCheckInSchedulerProvider = Provider<DailyCheckInScheduler>(
  (_) => LocalDailyCheckInScheduler(FlutterLocalNotificationsPlugin()),
);
