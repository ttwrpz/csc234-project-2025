import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'tokens/typography.dart';

/// Builds the MoodBloom light theme from design tokens.
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MoodBloomColors.seed,
    brightness: Brightness.light,
    surface: MoodBloomColors.surfaceCream,
    error: MoodBloomColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MoodBloomColors.surfaceCream,
    fontFamily: MoodBloomTypography.fontFamily,
    textTheme: MoodBloomTypography.textTheme.apply(
      bodyColor: MoodBloomColors.onSurface,
      displayColor: MoodBloomColors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: MoodBloomColors.surfaceCream,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: MoodBloomTypography.textTheme.titleLarge?.copyWith(
        color: MoodBloomColors.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MoodBloomColors.surfaceCream,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        MoodBloomTypography.textTheme.labelMedium,
      ),
    ),
  );
}

/// Builds the MoodBloom dark theme from design tokens. Dark variant of
/// [buildLightTheme] using the warm-dark surface family — the night-time
/// counterpart of cream rather than a cold pure black. Mood palette is
/// unchanged from light in S4; Sprint 5 a11y sweep tunes hue contrast.
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MoodBloomColors.seedDark,
    brightness: Brightness.dark,
    surface: MoodBloomColors.surfaceCreamDark,
    error: MoodBloomColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MoodBloomColors.surfaceCreamDark,
    fontFamily: MoodBloomTypography.fontFamily,
    textTheme: MoodBloomTypography.textTheme.apply(
      bodyColor: MoodBloomColors.onSurfaceDark,
      displayColor: MoodBloomColors.onSurfaceDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: MoodBloomColors.surfaceCreamDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: MoodBloomTypography.textTheme.titleLarge?.copyWith(
        color: MoodBloomColors.onSurfaceDark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MoodBloomColors.surfaceCreamDark,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        MoodBloomTypography.textTheme.labelMedium,
      ),
    ),
  );
}
