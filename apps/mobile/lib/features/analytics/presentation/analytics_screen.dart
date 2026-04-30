import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/analytics_state.dart';
import '../../mood/domain/entities/mood_type.dart';
import 'controllers/analytics_controller.dart';
import 'widgets/mood_window_selector.dart';

/// Read-only analytics dashboard — pivot feature #3. Renders a fl_chart line
/// chart of mean intensity per local-time day, one line per mood category,
/// over a 7/30/90-day window selected by the user.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  MoodWindow _window = MoodWindow.month;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsControllerProvider(_window));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoodBloomSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: MoodWindowSelector(
                  value: _window,
                  onChanged: (w) => setState(() => _window = w),
                ),
              ),
              const SizedBox(height: MoodBloomSpacing.lg),
              Expanded(
                child: state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _ChartErrorView(theme: theme),
                  data: (analytics) =>
                      _ChartBody(analytics: analytics, window: _window),
                ),
              ),
              const SizedBox(height: MoodBloomSpacing.md),
              _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.analytics, required this.window});

  final AnalyticsState analytics;
  final MoodWindow window;

  @override
  Widget build(BuildContext context) {
    if (analytics.isEmpty) {
      return _EmptyView(theme: Theme.of(context));
    }
    final points = <MoodPoint>[
      for (final day in analytics.days)
        for (final entry in day.meanIntensityByCategory.entries)
          MoodPoint(
            day: day.day,
            category: _toChartCategory(entry.key),
            meanIntensity: entry.value,
          ),
    ];
    return MoodLineChart(
      points: points,
      window: window,
      theme: const MoodLineChartTheme(
        colorByCategory: {
          ChartMoodCategory.positive: MoodBloomColors.moodHappy,
          ChartMoodCategory.negativeMild: MoodBloomColors.moodSad,
          ChartMoodCategory.negativeStrong: MoodBloomColors.moodAngry,
        },
      ),
    );
  }

  /// Lifted to a free function so adding a new `MoodCategory` value triggers
  /// a switch-exhaustiveness warning at build time.
  static ChartMoodCategory _toChartCategory(MoodCategory c) => switch (c) {
    MoodCategory.positive => ChartMoodCategory.positive,
    MoodCategory.negativeMild => ChartMoodCategory.negativeMild,
    MoodCategory.negativeStrong => ChartMoodCategory.negativeStrong,
  };
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 96, color: theme.colorScheme.outline),
            const SizedBox(height: MoodBloomSpacing.lg),
            Text(
              'No moods logged in this window.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoodBloomSpacing.sm),
            Text(
              'Tap Log Mood to start.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartErrorView extends StatelessWidget {
  const _ChartErrorView({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.xl),
        child: Text(
          "We couldn't load your analytics right now.",
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Tiny color-key strip below the chart. Read-only — the user can't toggle
/// lines on/off (that's a future enhancement).
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color)>[
      ('Positive', MoodBloomColors.moodHappy),
      ('Mildly negative', MoodBloomColors.moodSad),
      ('Strongly negative', MoodBloomColors.moodAngry),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: MoodBloomSpacing.lg,
      runSpacing: MoodBloomSpacing.sm,
      children: [
        for (final (label, color) in entries)
          _LegendChip(label: label, color: color),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label line color key',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: MoodBloomSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
