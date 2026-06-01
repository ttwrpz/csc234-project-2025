import 'package:shared_preferences/shared_preferences.dart';

const String _biometricEnabledKey = 'auth.biometric_enabled';

/// Tiny wrapper around [SharedPreferences] for the biometric opt-in flag.
/// Default is `false` - biometric is opt-in, not opt-out.
class BiometricPreferenceDatasource {
  const BiometricPreferenceDatasource(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> isOptedIn() async {
    return _prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setOptIn(bool enabled) async {
    await _prefs.setBool(_biometricEnabledKey, enabled);
  }
}
