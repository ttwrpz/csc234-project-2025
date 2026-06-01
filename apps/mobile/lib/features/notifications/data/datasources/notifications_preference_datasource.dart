import 'package:shared_preferences/shared_preferences.dart';

const String _cheerUpEnabledKey = 'notifications.cheer_up_enabled';
const String _dailyCheckInEnabledKey = 'notifications.daily_check_in_enabled';
const String _dailyCheckInHourKey = 'notifications.daily_check_in_hour';
const String _dailyCheckInMinuteKey = 'notifications.daily_check_in_minute';

/// Onboarding prototype default - a quiet 21:30 evening nudge. Used when
/// the user has never set a time. Kept here (not in the UI layer) so the
/// persisted default and the read-back default are the same value.
const int defaultDailyCheckInHour = 21;
const int defaultDailyCheckInMinute = 30;

/// Local mirror for the cheer-up toggle so the UI can render its initial
/// state without a Firestore round-trip on cold start.
///
/// **Off by default.** Opt-in-by-default was confusing on Web because
/// the browser permission prompt only fires on the user's first toggle
/// tap - until then, the toggle showed `enabled=true` but no FCM token
/// actually existed and no pushes would ever land. Off-by-default makes
/// the explicit opt-in flow (toggle → permission prompt → token
/// registration) the canonical first-touch path on both Web and native.
///
/// Mirror writes are best-effort; Firestore is the source of truth.
class NotificationsPreferenceDatasource {
  const NotificationsPreferenceDatasource(this._prefs);

  final SharedPreferences _prefs;

  bool isCheerUpEnabled() {
    return _prefs.getBool(_cheerUpEnabledKey) ?? false;
  }

  Future<void> setCheerUpEnabled(bool enabled) async {
    await _prefs.setBool(_cheerUpEnabledKey, enabled);
  }

  /// Whether the self-set daily check-in reminder is on. Off by default:
  /// the local notification (and its OS permission prompt) only arms once
  /// the user explicitly toggles it on in Settings.
  bool isDailyCheckInEnabled() {
    return _prefs.getBool(_dailyCheckInEnabledKey) ?? false;
  }

  Future<void> setDailyCheckInEnabled(bool enabled) async {
    await _prefs.setBool(_dailyCheckInEnabledKey, enabled);
  }

  /// The persisted reminder hour (0..23). Falls back to the onboarding
  /// default ([defaultDailyCheckInHour]) when never set.
  int dailyCheckInHour() {
    return _prefs.getInt(_dailyCheckInHourKey) ?? defaultDailyCheckInHour;
  }

  /// The persisted reminder minute (0..59). Falls back to the onboarding
  /// default ([defaultDailyCheckInMinute]) when never set.
  int dailyCheckInMinute() {
    return _prefs.getInt(_dailyCheckInMinuteKey) ?? defaultDailyCheckInMinute;
  }

  Future<void> setDailyCheckInTime({
    required int hour,
    required int minute,
  }) async {
    await _prefs.setInt(_dailyCheckInHourKey, hour);
    await _prefs.setInt(_dailyCheckInMinuteKey, minute);
  }
}
