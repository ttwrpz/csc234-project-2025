import 'package:flutter/material.dart';

import 'chart_mood_category.dart';

/// Visual theme for [MoodLineChart]. Lives in `packages/analytics` so the
/// chart widget can render without depending on `packages/design_system` —
/// callers (the analytics screen) pass MoodBloom palette colors in.
class MoodLineChartTheme {
  const MoodLineChartTheme({
    required this.colorByCategory,
    this.gridColor = const Color(0x14000000),
    this.axisLabelColor = const Color(0xFF6E6A60),
    this.lineWidth = 2.5,
    this.dotRadius = 3.0,
  });

  /// Falls back to plausible defaults for previewing without the design
  /// system. Production callers always pass an explicit
  /// [MoodLineChartTheme.colorByCategory].
  factory MoodLineChartTheme.fallback() => const MoodLineChartTheme(
    colorByCategory: {
      ChartMoodCategory.positive: Color(0xFFE8B84B),
      ChartMoodCategory.negativeMild: Color(0xFF6E8FB5),
      ChartMoodCategory.negativeStrong: Color(0xFFB3463A),
    },
  );

  /// One color per category line. All three categories should be mapped; if a
  /// category is missing the chart skips its line.
  final Map<ChartMoodCategory, Color> colorByCategory;

  /// Color of the gridlines and the chart border.
  final Color gridColor;

  /// Color of the day-of-month and intensity axis tick labels.
  final Color axisLabelColor;

  /// Stroke width of each category line.
  final double lineWidth;

  /// Radius of the per-day dots drawn at each sample.
  final double dotRadius;
}
