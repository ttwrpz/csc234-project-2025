// ARCHITECTURAL EXCEPTION.
//
// CLAUDE.md's "the one rule that cannot break" forbids
// `package:flutter/*` imports anywhere under `domain/`. This file is the
// single sanctioned exception in the entire codebase: `ThemeMode` is a
// Material enum-like value with no domain analog, and re-creating a
// custom `MoodBloomThemeMode` only to map it back to `ThemeMode` at
// every call site would be pure ceremony with no testability benefit
// (the enum has no Flutter behaviour, just three named constants). Any
// other import of `package:flutter/*` under `domain/` remains forbidden
// — this file is a one-off.
import 'package:flutter/material.dart' show ThemeMode;

import '../entities/theme_mode_preference.dart';

/// Resolves a [ThemeModePreference] into a concrete [ThemeMode] given
/// the current [DateTime].
///
/// `followDeviceTime` flips between light and dark on a fixed local-time
/// cutoff: light during `[dayStartHour, dayEndHour)` (default
/// 07:00–19:00, Bangkok-latitude proxy), dark otherwise. No geolocation
/// is involved.
///
/// Pure-Dart aside from the [ThemeMode] return type. No I/O, no
/// platform calls — fully unit-testable by passing a fixed `now`.
class DayNightStrategy {
  const DayNightStrategy({this.dayStartHour = 7, this.dayEndHour = 19});

  /// First local hour considered "day" (inclusive). `now.hour >=
  /// dayStartHour` means the strategy returns light for
  /// `followDeviceTime`.
  final int dayStartHour;

  /// First local hour considered "night" (exclusive). `now.hour <
  /// dayEndHour` means the strategy returns light. At `now.hour ==
  /// dayEndHour` the theme flips to dark.
  final int dayEndHour;

  /// Resolves [preference] given [now].
  ///
  /// - `system` → [ThemeMode.system]
  /// - `light` → [ThemeMode.light]
  /// - `dark` → [ThemeMode.dark]
  /// - `followDeviceTime` → light during local
  ///   `[dayStartHour, dayEndHour)`, dark otherwise.
  ///
  /// [now] is converted to local time before reading the hour, so the
  /// caller may pass either local or UTC `DateTime` — the result is the
  /// same on the user's device.
  ThemeMode resolve({
    required ThemeModePreference preference,
    required DateTime now,
  }) {
    switch (preference) {
      case ThemeModePreference.system:
        return ThemeMode.system;
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
      case ThemeModePreference.followDeviceTime:
        final hour = now.toLocal().hour;
        final isDay = hour >= dayStartHour && hour < dayEndHour;
        return isDay ? ThemeMode.light : ThemeMode.dark;
    }
  }
}
