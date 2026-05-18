import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/theme_mode_preference.dart';

/// Thin synchronous wrapper that persists the user's
/// [ThemeModePreference] choice to SharedPreferences. Takes an
/// already-resolved [SharedPreferences] instance so the controller can
/// read/write without awaiting — the eager-resolve happens once in
/// `main.dart` so the first frame of the app picks up the persisted
/// preference without a flash-of-light.
///
/// Storage key: `settings.theme_mode`. Values:
/// `system | light | dark | follow_device_time`.
///
/// Backward compatible with the Sprint 3 storage format: existing users
/// on disk have one of `'system' / 'light' / 'dark'` and decode to the
/// matching new enum value. The new value `'follow_device_time'` is
/// only ever written when the user actively picks "Follow device time"
/// in Settings.
class ThemeModeStorage {
  const ThemeModeStorage(this._prefs);

  static const String _key = 'settings.theme_mode';

  final SharedPreferences _prefs;

  /// Reads the persisted preference. Defaults to
  /// [ThemeModePreference.light] on first launch — the warm cream
  /// surface is the brand-canonical first-touch and tests in dark mode
  /// always opt in explicitly. Malformed values fall back the same way.
  ThemeModePreference read() {
    switch (_prefs.getString(_key)) {
      case 'light':
        return ThemeModePreference.light;
      case 'dark':
        return ThemeModePreference.dark;
      case 'follow_device_time':
        return ThemeModePreference.followDeviceTime;
      case 'system':
        return ThemeModePreference.system;
      case null:
      default:
        return ThemeModePreference.light;
    }
  }

  /// Persists [preference]. Returns once the underlying write
  /// completes.
  Future<void> write(ThemeModePreference preference) async {
    await _prefs.setString(_key, _serialize(preference));
  }

  static String _serialize(ThemeModePreference preference) =>
      switch (preference) {
        ThemeModePreference.system => 'system',
        ThemeModePreference.light => 'light',
        ThemeModePreference.dark => 'dark',
        ThemeModePreference.followDeviceTime => 'follow_device_time',
      };
}
