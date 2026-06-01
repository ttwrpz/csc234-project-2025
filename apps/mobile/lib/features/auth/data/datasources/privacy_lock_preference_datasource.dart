import 'package:shared_preferences/shared_preferences.dart';

const String _privacyLockEnabledKey = 'auth.privacy_lock_enabled';

/// Tiny wrapper around [SharedPreferences] for the History privacy
/// gate's user-facing opt-in flag. Default OFF.
///
/// This is the local mirror of the user's intent; it stays in sync
/// with the PIN doc in Firestore (a user with the gate ON should have
/// a PIN set, and turning OFF invalidates the PIN). Stored locally
/// rather than in Firestore because a) the router redirect needs a
/// synchronous read, b) the toggle has no cross-device relevance -
/// if you sign in on a new device you re-opt-in.
class PrivacyLockPreferenceDatasource {
  const PrivacyLockPreferenceDatasource(this._prefs);

  final SharedPreferences _prefs;

  bool isEnabled() => _prefs.getBool(_privacyLockEnabledKey) ?? false;

  Future<void> setEnabled(bool enabled) =>
      _prefs.setBool(_privacyLockEnabledKey, enabled);
}
