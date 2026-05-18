/// User-facing theme preference persisted to local storage.
///
/// Distinct from Material's `ThemeMode` (which is the OUTPUT consumed by
/// [MaterialApp.themeMode]) — this enum is what we PERSIST. The value
/// `followDeviceTime` lets the user auto-flip between light + dark
/// based on local clock instead of device settings.
///
/// The mapping `ThemeModePreference → ThemeMode` is owned by
/// `DayNightStrategy` in the same `domain/` folder.
enum ThemeModePreference {
  /// Mirrors the device-level light/dark setting (existing default).
  system,

  /// Always use the light theme, regardless of device or clock.
  light,

  /// Always use the dark theme, regardless of device or clock.
  dark,

  /// Use the light theme during local daytime (07:00–19:00) and the
  /// dark theme otherwise. No geolocation; the cutoff is a fixed
  /// Bangkok-latitude proxy.
  followDeviceTime,
}
