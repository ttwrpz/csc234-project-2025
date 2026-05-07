import 'package:shared_preferences/shared_preferences.dart';

const String _cheerUpEnabledKey = 'notifications.cheer_up_enabled';

/// Local mirror for the cheer-up toggle so the UI can render its initial
/// state without a Firestore round-trip on cold start. Default is `true`
/// per O13 — first-run users opt in by default and discover the toggle
/// from settings if they want to opt out.
///
/// Mirror writes are best-effort; Firestore is the source of truth.
class NotificationsPreferenceDatasource {
  const NotificationsPreferenceDatasource(this._prefs);

  final SharedPreferences _prefs;

  bool isCheerUpEnabled() {
    return _prefs.getBool(_cheerUpEnabledKey) ?? true;
  }

  Future<void> setCheerUpEnabled(bool enabled) async {
    await _prefs.setBool(_cheerUpEnabledKey, enabled);
  }
}
