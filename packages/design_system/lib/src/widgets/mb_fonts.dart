import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers. v1.6 bundles Fraunces (display/title) and Nunito
/// (body/label) via `google_fonts` to match the Claude Design handoff.
///
/// Call-site API is unchanged from earlier versions - the helpers still
/// accept the same `(fontSize, fontWeight, color, height, letterSpacing,
/// ...)` knobs and an optional `textStyle` base that's merged first.
/// Only the underlying font resolution moved from "platform default"
/// to "google_fonts cached download."
///
/// Cold-start cost: one async HTTP fetch per family on first launch,
/// served from the device cache afterwards. Both families ship a small
/// subset of weights (400, 500, 600, 700) to keep the cache footprint
/// modest.
abstract final class MbFonts {
  /// Display / headline / title roles. Resolves to Fraunces.
  static TextStyle fraunces({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => GoogleFonts.fraunces(
    textStyle: textStyle,
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );

  /// Body / label roles. Resolves to Nunito.
  static TextStyle nunito({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => GoogleFonts.nunito(
    textStyle: textStyle,
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );
}
