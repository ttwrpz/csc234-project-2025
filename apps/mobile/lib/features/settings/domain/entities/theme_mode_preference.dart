/// User-facing theme preference persisted to local storage.
///
/// Distinct from Material's `ThemeMode` (which is the OUTPUT consumed by
/// [MaterialApp.themeMode]) — this enum is what we PERSIST. Day-4 Track
/// 4.4 / 7.2 added the fourth value `followDeviceTime` so the user can
/// auto-flip between light + dark based on local clock instead of device
/// settings.
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
  /// Bangkok-latitude proxy. See ADR-0010 follow-up: a sunrise/sunset
  /// table is a v1.x replacement.
  followDeviceTime,
}
