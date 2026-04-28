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
