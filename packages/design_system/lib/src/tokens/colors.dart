import 'package:flutter/material.dart';

/// MoodBloom color tokens. Soft, garden-coded palette.
abstract final class MoodBloomColors {
  // Brand
  static const Color seed = Color(0xFF5B8A72); // muted sage green
  static const Color seedDark = Color(0xFF3F6855);

  // Neutrals (light mode)
  static const Color surfaceCream = Color(
    0xFFFAF7F2,
  ); // warm off-white background
  static const Color surfaceDim = Color(0xFFEEE9DF);
  static const Color outline = Color(0xFFD7D0C2);
  static const Color onSurface = Color(0xFF2C2A26);
  static const Color onSurfaceMuted = Color(0xFF6E6A60);

  // Neutrals (dark mode — added in S4, WBS 6.2)
  /// Primary scaffold/surface in dark theme. Near-black with a warm
  /// undertone so it reads as the night-time counterpart of [surfaceCream]
  /// rather than a cold pure black.
  static const Color surfaceCreamDark = Color(0xFF1F1D1A);

  /// Deeper warm tone for elevated surfaces and shadow wells in dark theme.
  static const Color surfaceDimDark = Color(0xFF15130F);

  /// Muted warm outline for dividers and borders in dark theme.
  static const Color outlineDark = Color(0xFF4A463E);

  /// High-contrast warm white for primary text on dark surfaces.
  static const Color onSurfaceDark = Color(0xFFEDE7DE);

  /// Muted warm grey for secondary text and disabled glyphs in dark theme.
  static const Color onSurfaceMutedDark = Color(0xFFA8A095);

  // Semantic
  static const Color success = Color(0xFF5B8A72);
  static const Color warning = Color(0xFFC68A1E);
  static const Color error = Color(0xFFB3463A);

  // TODO(S5-a11y): tune mood-* colours for adequate dark-mode contrast
  // (see Sprint 5 a11y sweep). The S4 dark theme uses the same mood
  // palette as light; some hues drop below WCAG AA on dark surfaces.
  // Mood palette (consumed by S4 garden + S3 chart)
  // Positive
  static const Color moodHappy = Color(0xFFE8B84B); // warm yellow
  static const Color moodCalm = Color(0xFF7FB3A1); // sage teal
  // Neutral / mild negative
  static const Color moodOkay = Color(0xFFB0AEA6); // soft grey
  static const Color moodSad = Color(0xFF6E8FB5); // dusty blue
  // Strong negative
  static const Color moodAngry = Color(0xFFB3463A); // muted brick red
  static const Color moodAnxious = Color(0xFF8B6FA9); // muted lavender purple
}
