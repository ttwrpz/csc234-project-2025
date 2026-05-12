import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/daily_insight.dart';

/// Thin app-side adapter around `analytics_pkg`'s [MoodScoreLineChart].
/// Translates the feature's [DailyInsight] list into the chart's
/// [MoodScorePoint] shape and supplies a theme that resolves to the
/// project's `MbColors` + plant-tier palette.
///
/// The chart itself lives in `packages/analytics/` so the design-system
/// dependency stays one-directional (app → packages, never the reverse).
class MoodScoreChart extends StatelessWidget {
  const MoodScoreChart({super.key, required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    final points = [
      for (final d in insights)
        MoodScorePoint(
          day: d.date,
          score: d.avgMoodScore,
          health: d.gardenHealthH,
        ),
    ];

    return MoodScoreLineChart(
      points: points,
      theme: MoodScoreChartTheme(
        scoreLineColor: theme.colorScheme.primary,
        healthLineColor: MoodBloomColors.amber,
        gridColor: mb.line,
        axisLabelColor: mb.textDim,
        // Plant-tier bands — top-to-bottom matches the colour vocabulary
        // garden_screen.dart already uses for the 5 alive ecosystem
        // states. Low alpha so the lines stay the dominant signal.
        tierBandColors: [
          MoodBloomColors.softGreen.withValues(alpha: 0.55), // flourishing
          MoodBloomColors.softGreen.withValues(alpha: 0.28), // thriving
          mb.line.withValues(alpha: 0.18), // resting (neutral)
          mb.softCoral.withValues(alpha: 0.45), // weathering
          MoodBloomColors.coral.withValues(alpha: 0.30), // storm season
        ],
      ),
    );
  }
}
