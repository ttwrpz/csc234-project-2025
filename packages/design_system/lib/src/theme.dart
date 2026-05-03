import 'widgets/mb_fonts.dart';
import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';

/// Builds the MoodBloom light theme from the "Sprint 2 Prototype" tokens.
ThemeData buildLightTheme() {
  final mb = MbColors.light();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MoodBloomColors.seed,
    brightness: Brightness.light,
    surface: mb.bg,
    surfaceContainer: mb.card,
    onSurface: mb.text,
    onSurfaceVariant: mb.textDim,
    outline: mb.line,
    primary: MoodBloomColors.seed,
    error: MoodBloomColors.coral,
  );
  return _buildTheme(colorScheme: colorScheme, mb: mb);
}

/// Builds the MoodBloom dark theme from the "Sprint 2 Prototype" tokens.
ThemeData buildDarkTheme() {
  final mb = MbColors.dark();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MoodBloomColors.seed,
    brightness: Brightness.dark,
    surface: mb.bg,
    surfaceContainer: mb.card,
    onSurface: mb.text,
    onSurfaceVariant: mb.textDim,
    outline: mb.line,
    primary: MoodBloomColors.seed,
    error: MoodBloomColors.coral,
  );
  return _buildTheme(colorScheme: colorScheme, mb: mb);
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required MbColors mb,
}) {
  final textTheme = MoodBloomTypography.buildTextTheme(bodyColor: mb.text);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: mb.bg,
    fontFamily: MoodBloomTypography.fontFamily,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[mb, MbMoodPalette.shared],
    appBarTheme: AppBarTheme(
      backgroundColor: mb.bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: MbFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
      iconTheme: IconThemeData(color: mb.text),
    ),
    cardTheme: CardThemeData(
      color: mb.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        side: BorderSide(color: mb.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusButton),
        ),
        textStyle: MbFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: mb.card,
        foregroundColor: mb.text,
        side: BorderSide(color: mb.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusButton),
        ),
        textStyle: MbFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mb.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
        borderSide: BorderSide(color: mb.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
        borderSide: BorderSide(color: mb.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: mb.bg,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
    ),
    dividerTheme: DividerThemeData(color: mb.line, thickness: 1),
  );
}
