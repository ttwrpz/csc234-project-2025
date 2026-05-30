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
        // Slate-blue instead of amber so the "rolling rhythm" trend line
        // is visually distinct from the Tier 1 marker dots (which keep
        // amber). The previous duplicate hue made the legend show two
        // amber dots labelled differently and blurred the two signals on
        // the chart itself.
        healthLineColor: const Color(0xFF7A96AE),
        gridColor: mb.line,
        axisLabelColor: mb.textDim,
        // Plant-tier bands — top-to-bottom, top = healthiest. Each band
        // gets a distinct hue (deep green / light green / neutral / sand /
        // coral) rather than just different alphas of the same colour, so
        // adjacent tiers stay readable on light cream and don't bleed
        // into each other.
        tierBandColors: [
          MoodBloomColors.seed.withValues(alpha: 0.30), // flourishing
          MoodBloomColors.softGreen.withValues(alpha: 0.55), // thriving
          mb.line.withValues(alpha: 0.18), // resting (neutral)
          const Color(0xFFD4A56A).withValues(alpha: 0.40), // weathering
          MoodBloomColors.coral.withValues(alpha: 0.55), // storm season
        ],
      ),
    );
  }
}
