import 'package:flutter/painting.dart';

/// Colours and visual constants for [MoodScoreLineChart]. Pure data —
/// no Flutter widgets. Callers compose this from their theme so the
/// chart stays decoupled from `packages/design_system`.
///
/// `tierBandColors` index from `flourishing` (top) to `stormSeason`
/// (bottom). The chart paints them as horizontal bands keyed off the
/// EWMA `H_t` thresholds in spec §2.3:
///   * Flourishing  : H >=  +0.4
///   * Thriving     : +0.1 <= H <  +0.4
///   * Resting      : -0.1 <  H <  +0.1
///   * Weathering   : -0.4 <  H <= -0.1
///   * Storm Season :          H <= -0.4
class MoodScoreChartTheme {
  const MoodScoreChartTheme({
    required this.scoreLineColor,
    required this.healthLineColor,
    required this.gridColor,
    required this.axisLabelColor,
    required this.tierBandColors,
    this.scoreLineWidth = 2.0,
    this.healthLineWidth = 2.5,
    this.dotRadius = 3.0,
  });

  /// Primary "mood score `S_t`" line colour.
  final Color scoreLineColor;

  /// Overlay "Garden Health `H_t`" line colour.
  final Color healthLineColor;

  /// Grid + axis stroke colour.
  final Color gridColor;

  /// Axis label text colour.
  final Color axisLabelColor;

  /// 5 horizontal band colours, ordered top-to-bottom: flourishing →
  /// thriving → resting → weathering → stormSeason. Each is rendered at
  /// low alpha so the score line stays the dominant signal.
  final List<Color> tierBandColors;

  final double scoreLineWidth;
  final double healthLineWidth;
  final double dotRadius;
}
