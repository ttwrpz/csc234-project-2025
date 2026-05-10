import 'package:flutter/material.dart';

/// MoodBloom raw color tokens. Soft, garden-coded palette plus the
/// "Sprint 2 Prototype" surface family. Names are preserved so existing
/// consumers (e.g. `MoodBloomColors.moodHappy`) keep compiling; only the
/// hex values for the 6 mood swatches and the cream surface have shifted.
abstract final class MoodBloomColors {
  // Brand
  static const Color seed = Color(0xFF2E7D5B); // primary deep-green
  static const Color seedDark = Color(0xFF1F5A41); // primary deep
  static const Color softGreen = Color(0xFFE8F3ED);
  static const Color amber = Color(0xFFE8A23B);
  static const Color coral = Color(0xFFF4A78C);

  /// Deeper coral suitable for destructive TEXT on a cream surface.
  /// `coral` (0xFFF4A78C, luminance ~0.50) gives a ~2.2:1 contrast
  /// ratio against `surfaceCream` and fails WCAG AA. This deeper tone
  /// (luminance ~0.13) lands at ~7:1 — passes AAA — while staying in
  /// the warm coral hue family. Use [coralText] for ListTile titles,
  /// `Sign out` / `Wipe…` labels, snackbar copy, etc. Filled buttons
  /// can keep `coral` as their background since the foreground there
  /// is white (ratio is fine on white).
  static const Color coralText = Color(0xFFA63B2E);

  // Neutrals (light mode)
  /// Warm cream scaffold. Updated to the prototype value `#FBFAF6`.
  static const Color surfaceCream = Color(0xFFFBFAF6);
  static const Color surfaceDim = Color(0xFFEEE9DF);
  static const Color outline = Color(0xFFECE7DC);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceMuted = Color(0xFF6B7280);

  // Neutrals (dark mode)
  /// Primary scaffold/surface in dark theme. Cool navy from the prototype.
  static const Color surfaceCreamDark = Color(0xFF161F2C);
  static const Color surfaceDimDark = Color(0xFF22303F);
  static const Color outlineDark = Color(0xFF2E3B4B);
  static const Color onSurfaceDark = Color(0xFFF0F3F7);
  static const Color onSurfaceMutedDark = Color(0xFFA6B2C2);

  // Semantic
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFC68A1E);
  static const Color error = Color(0xFFF4A78C);

  // Mood palette (re-skinned for the prototype; names preserved)
  static const Color moodHappy = Color(0xFFF6C45A);
  static const Color moodCalm = Color(0xFF8FBFA3);
  static const Color moodOkay = Color(0xFFA7B3A9);
  static const Color moodSad = Color(0xFF7A96AE);
  static const Color moodAngry = Color(0xFF8B6F63);
  static const Color moodAnxious = Color(0xFFB8A15E);
}

/// Semantic surface tokens carried as a `ThemeExtension` so widgets can
/// resolve them via `Theme.of(context).extension<MbColors>()!` instead of
/// reaching for raw constants.
@immutable
class MbColors extends ThemeExtension<MbColors> {
  const MbColors({
    required this.bg,
    required this.card,
    required this.line,
    required this.text,
    required this.textDim,
    required this.skyTop,
    required this.skyMid,
    required this.skyBot,
    required this.sun1,
    required this.sun2,
    required this.ground,
    required this.ground2,
    required this.grass,
    required this.navBg,
    required this.softCoral,
    required this.aiBg,
    required this.aiBd,
  });

  /// Light-mode token set from the "Sprint 2 Prototype".
  factory MbColors.light() => const MbColors(
    bg: Color(0xFFFBFAF6),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFECE7DC),
    text: Color(0xFF1F2937),
    textDim: Color(0xFF6B7280),
    skyTop: Color(0xFFFFE4D1),
    skyMid: Color(0xFFF5E9DA),
    skyBot: Color(0xFFE8F3ED),
    sun1: Color(0xFFFFD9A6),
    sun2: Color(0xFFFFC98C),
    ground: Color(0xFF8FBFA3),
    ground2: Color(0xFF7AAF92),
    grass: Color(0xFF4C8B6A),
    navBg: Color(0xE6FFFFFF), // rgba(255,255,255,0.9)
    softCoral: Color(0xFFFFF1E9),
    aiBg: Color(0xFFF5F2EA),
    aiBd: Color(0xFFE6DFCC),
  );

  /// Dark-mode token set from the "Sprint 2 Prototype".
  factory MbColors.dark() => const MbColors(
    bg: Color(0xFF161F2C),
    card: Color(0xFF22303F),
    line: Color(0xFF2E3B4B),
    text: Color(0xFFF0F3F7),
    textDim: Color(0xFFA6B2C2),
    skyTop: Color(0xFF2B3A52),
    skyMid: Color(0xFF25334A),
    skyBot: Color(0xFF1F3A2E),
    sun1: Color(0xFFD9D4A0),
    sun2: Color(0xFFA6A07A),
    ground: Color(0xFF1F3A2E),
    ground2: Color(0xFF183325),
    grass: Color(0xFF2E5541),
    navBg: Color(0xE622303F), // rgba(34,48,63,0.9)
    softCoral: Color(0xFF3B2A24),
    aiBg: Color(0xFF1E2A3A),
    aiBd: Color(0xFF304056),
  );

  final Color bg;
  final Color card;
  final Color line;
  final Color text;
  final Color textDim;
  final Color skyTop;
  final Color skyMid;
  final Color skyBot;
  final Color sun1;
  final Color sun2;
  final Color ground;
  final Color ground2;
  final Color grass;
  final Color navBg;
  final Color softCoral;
  final Color aiBg;
  final Color aiBd;

  @override
  MbColors copyWith({
    Color? bg,
    Color? card,
    Color? line,
    Color? text,
    Color? textDim,
    Color? skyTop,
    Color? skyMid,
    Color? skyBot,
    Color? sun1,
    Color? sun2,
    Color? ground,
    Color? ground2,
    Color? grass,
    Color? navBg,
    Color? softCoral,
    Color? aiBg,
    Color? aiBd,
  }) {
    return MbColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      line: line ?? this.line,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      skyTop: skyTop ?? this.skyTop,
      skyMid: skyMid ?? this.skyMid,
      skyBot: skyBot ?? this.skyBot,
      sun1: sun1 ?? this.sun1,
      sun2: sun2 ?? this.sun2,
      ground: ground ?? this.ground,
      ground2: ground2 ?? this.ground2,
      grass: grass ?? this.grass,
      navBg: navBg ?? this.navBg,
      softCoral: softCoral ?? this.softCoral,
      aiBg: aiBg ?? this.aiBg,
      aiBd: aiBd ?? this.aiBd,
    );
  }

  @override
  MbColors lerp(ThemeExtension<MbColors>? other, double t) {
    if (other is! MbColors) return this;
    return MbColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      skyTop: Color.lerp(skyTop, other.skyTop, t)!,
      skyMid: Color.lerp(skyMid, other.skyMid, t)!,
      skyBot: Color.lerp(skyBot, other.skyBot, t)!,
      sun1: Color.lerp(sun1, other.sun1, t)!,
      sun2: Color.lerp(sun2, other.sun2, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      ground2: Color.lerp(ground2, other.ground2, t)!,
      grass: Color.lerp(grass, other.grass, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      softCoral: Color.lerp(softCoral, other.softCoral, t)!,
      aiBg: Color.lerp(aiBg, other.aiBg, t)!,
      aiBd: Color.lerp(aiBd, other.aiBd, t)!,
    );
  }
}

/// Design-system mirror of the domain `MoodType`. Kept here so the
/// design_system package never depends on `apps/mobile`. Phase C adds a
/// small adapter at the screen edge that maps `MoodType` → `MbMoodKind`.
enum MbMoodKind { happy, calm, okay, sad, angry, anxious }

/// Mood swatch + emoji lookup carried as a `ThemeExtension`. The values do
/// not depend on brightness, so a single shared instance is fine; we still
/// implement `copyWith` and `lerp` to honor the `ThemeExtension` contract.
@immutable
class MbMoodPalette extends ThemeExtension<MbMoodPalette> {
  const MbMoodPalette._();

  /// Singleton shared by light and dark themes.
  static const MbMoodPalette shared = MbMoodPalette._();

  /// Brand color for a mood. Maps to the prototype hex.
  Color colorOf(MbMoodKind mood) => switch (mood) {
    MbMoodKind.happy => MoodBloomColors.moodHappy,
    MbMoodKind.calm => MoodBloomColors.moodCalm,
    MbMoodKind.okay => MoodBloomColors.moodOkay,
    MbMoodKind.sad => MoodBloomColors.moodSad,
    MbMoodKind.angry => MoodBloomColors.moodAngry,
    MbMoodKind.anxious => MoodBloomColors.moodAnxious,
  };

  /// Single-glyph emoji label for a mood.
  String emojiOf(MbMoodKind mood) => switch (mood) {
    MbMoodKind.happy => '🌻',
    MbMoodKind.calm => '🌱',
    MbMoodKind.okay => '🌿',
    MbMoodKind.sad => '💧',
    MbMoodKind.angry => '⛈️',
    MbMoodKind.anxious => '🌾',
  };

  @override
  MbMoodPalette copyWith() => this;

  @override
  MbMoodPalette lerp(ThemeExtension<MbMoodPalette>? other, double t) => this;
}
