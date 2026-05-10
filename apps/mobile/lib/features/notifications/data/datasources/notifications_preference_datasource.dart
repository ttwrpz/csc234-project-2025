import 'package:shared_preferences/shared_preferences.dart';

const String _cheerUpEnabledKey = 'notifications.cheer_up_enabled';

/// Local mirror for the cheer-up toggle so the UI can render its initial
/// state without a Firestore round-trip on cold start.
///
/// **Default flipped to `false` in v1.0 polish (2026-05-10)** per the
/// user feedback "Cheer up reminder should be off until user allow
/// notification permission both on web and mobile". The original O13
/// opt-in-by-default behaviour was confusing on Web because the
/// browser permission prompt only fired on the user's first toggle
/// tap — until then, the toggle showed `enabled=true` but no FCM
/// token actually existed and no pushes would ever land. Off-by-
/// default makes the explicit opt-in flow (toggle → permission
/// prompt → token registration) the canonical first-touch path on
/// both Web and native.
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
}
