import 'package:flutter/material.dart';

/// MoodBloom typography. Pairs system body and display fonts with the
/// "Sprint 2 Prototype" size/weight scale.
///
/// Originally this builder reached for `GoogleFonts.nunito*` / `fraunces`,
/// but the package's runtime fetcher throws under tests when the font
/// isn't bundled — and bundling 6 TTF assets is a heavier change than
/// this PR is scoped for. The size scale, weights, and letter spacing
/// are the prototype's; only the typeface family differs (system default
/// instead of Nunito + Fraunces). Switching back is a one-line restore +
/// adding the .ttf files under `apps/mobile/assets/fonts/` and
/// registering them in `pubspec.yaml`.
abstract final class MoodBloomTypography {
  /// Kept as `null` so each `TextStyle` uses the platform default
  /// (Roboto on Android, San Francisco on iOS, system on web).
  static const String? fontFamily = null;

  /// Returns a fully-resolved Material 3 text theme with the prototype's
  /// size/weight scale.
  static TextTheme buildTextTheme({required Color bodyColor}) {
    const base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    return base.apply(bodyColor: bodyColor, displayColor: bodyColor);
  }
}
