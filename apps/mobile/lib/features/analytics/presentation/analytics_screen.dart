import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../domain/entities/analytics_state.dart';
import 'controllers/analytics_controller.dart';
import 'widgets/mood_window_selector.dart';
import 'widgets/pattern_insight_card.dart';

/// Read-only analytics dashboard — pivot feature #3. Restyled to the
/// Sprint 2 Prototype: Fraunces-headed "Patterns" title, segmented
/// 7/30/90 toggle, an [MbCard] holding the line chart, the
/// [PatternInsightCard], and a row of three quick-stat [MbCard]s.
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
    final entries = ref.watch(myMoodsStreamProvider).value ?? const [];
    final mb = Theme.of(context).extension<MbColors>()!;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
          ),
          children: [
            _Header(),
            const SizedBox(height: MoodBloomSpacing.md),
            MoodWindowSelector(
              value: _window,
              onChanged: (w) => setState(() => _window = w),
            ),
            const SizedBox(height: MoodBloomSpacing.md),
            _ChartCard(state: state, window: _window),
            const SizedBox(height: MoodBloomSpacing.md),
            // Defence in depth: hide the slot when the flag is off so
            // the card consumes zero layout space — the widget also
            // self-hides via `SizedBox.shrink()`.
            if (ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled) ...[
              const PatternInsightCard(),
              const SizedBox(height: MoodBloomSpacing.md),
            ],
            _QuickStatsRow(entries: entries, window: _window),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      'Patterns',
      style: MbFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
    );
  }
}

/// `MbCard` r20 wrapping the fl_chart line chart. Fixed 180 dp inner
/// chart height per the prototype.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.state, required this.window});

  final AsyncValue<AnalyticsState> state;
  final MoodWindow window;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    return MbCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Mood over time',
                style: MbFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              const Spacer(),
              Text(
                'higher = brighter',
                style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  "We couldn't load your analytics right now.",
                  style: MbFonts.nunito(fontSize: 13, color: mb.text),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (analytics) => _ChartBody(
                analytics: analytics,
                window: window,
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.analytics,
    required this.window,
    required this.theme,
  });

  final AnalyticsState analytics;
  final MoodWindow window;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    if (analytics.isEmpty) {
      return Center(
        child: Text(
          'No moods logged in this window.',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
          textAlign: TextAlign.center,
        ),
      );
    }
    final primary = theme.colorScheme.primary;
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
      theme: MoodLineChartTheme(
        colorByCategory: {
          ChartMoodCategory.positive: primary,
          ChartMoodCategory.negativeMild: MoodBloomColors.moodSad,
          ChartMoodCategory.negativeStrong: MoodBloomColors.moodAngry,
        },
        gridColor: mb.line,
        axisLabelColor: mb.textDim,
        dashedGridLine: true,
        areaFillBelowGradient: [
          primary.withAlpha(0x59),
          primary.withAlpha(0x05),
        ],
        // Use the high-contrast mb.text color as the tooltip surface so
        // hover values read clearly against either cream (light) or navy
        // (dark) chart backgrounds. The chart auto-picks white/dark fg by
        // luminance.
        tooltipBgColor: mb.text,
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

/// Three at-a-glance stats: most-frequent mood, average intensity, and
/// day-streak. Stats are computed at presentation time from the entries
/// list; they are read-only and don't write back to any controller.
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.entries, required this.window});

  final List<MoodEntry> entries;
  final MoodWindow window;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final inWindow = entries
        .where((e) => now.difference(e.createdAt).inDays < window.days)
        .toList();
    final mostFrequent = _mostFrequentMood(inWindow);
    final avgIntensity = _avgIntensity(inWindow);
    final streak = _dayStreak(entries, now);

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message:
                'The mood you logged most often in the last ${window.days} days.',
            child: _MostFrequentCard(mood: mostFrequent),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message:
                'Average of the intensity sliders (1–5) across '
                '${inWindow.length} ${inWindow.length == 1 ? "entry" : "entries"}.',
            child: _NumberStatCard(
              value: avgIntensity == null
                  ? '—'
                  : avgIntensity.toStringAsFixed(1),
              label: 'avg intensity',
              sub: '${inWindow.length} entries',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: 'Days in a row with at least one mood entry.',
            child: _NumberStatCard(
              value: '$streak',
              label: 'day streak',
              sub: 'gentle rhythm',
            ),
          ),
        ),
      ],
    );
  }

  static MoodType? _mostFrequentMood(List<MoodEntry> entries) {
    if (entries.isEmpty) return null;
    final counts = <MoodType, int>{};
    for (final e in entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static double? _avgIntensity(List<MoodEntry> entries) {
    if (entries.isEmpty) return null;
    final sum = entries.fold<int>(0, (a, e) => a + e.intensity);
    return sum / entries.length;
  }

  /// Consecutive trailing-day streak: counts days with at least one entry,
  /// walking back from today until a gap. Empty entries → 0.
  static int _dayStreak(List<MoodEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;
    final daysWithEntry = <DateTime>{};
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      daysWithEntry.add(DateTime(local.year, local.month, local.day));
    }
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    while (daysWithEntry.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _MostFrequentCard extends StatelessWidget {
  const _MostFrequentCard({required this.mood});

  final MoodType? mood;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final emoji = mood == null ? '—' : palette.emojiOf(mood!.mbKind);
    final label = mood == null ? '—' : mood!.name;
    return MbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            'most frequent',
            style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: MbFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NumberStatCard extends StatelessWidget {
  const _NumberStatCard({
    required this.value,
    required this.label,
    required this.sub,
  });

  final String value;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    return MbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: MbFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: MbFonts.nunito(fontSize: 11, color: mb.textDim)),
          const SizedBox(height: 2),
          Text(
            sub,
            style: MbFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: mb.text,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
