import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin synchronous wrapper that persists the user's `ThemeMode` choice
/// to SharedPreferences. Takes an already-resolved [SharedPreferences]
/// instance so the controller can read/write without awaiting — the
/// eager-resolve happens once in `main.dart` so the first frame of the
/// app picks up the persisted theme without a flash-of-light.
///
/// Storage key: `settings.theme_mode`. Values: `system|light|dark`.
class ThemeModeStorage {
  const ThemeModeStorage(this._prefs);

  static const String _key = 'settings.theme_mode';

  final SharedPreferences _prefs;

  /// Reads the persisted theme mode. Defaults to [ThemeMode.system] when
  /// no value has been written yet (first launch) or when the stored
  /// value is malformed.
  ThemeMode read() {
    switch (_prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      case null:
      default:
        return ThemeMode.system;
    }
  }

  /// Persists [mode]. Returns once the underlying write completes.
  Future<void> write(ThemeMode mode) async {
    await _prefs.setString(_key, _serialize(mode));
  }

  static String _serialize(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };
}
