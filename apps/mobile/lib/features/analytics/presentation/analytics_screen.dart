import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../../disclaimer/presentation/widgets/disclaimer_ack_dialog.dart';
import '../../insights/domain/entities/daily_insight.dart';
import '../../insights/domain/entities/insight_window.dart';
import '../../insights/presentation/controllers/insights_controller.dart';
import '../../insights/presentation/widgets/chart_reading_guide.dart';
import '../../insights/presentation/widgets/mood_score_chart.dart';
import '../../insights/presentation/widgets/pattern_marker_band.dart';
import '../../insights/presentation/widgets/recent_triggers_card.dart';
import '../../insights/presentation/widgets/tier_band_legend.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import 'widgets/pattern_insight_card.dart';

/// Patterns — the unified read-only dashboard, refreshed for v1.6 per
/// `PatternsScreen` in `prototype/screens-extra.jsx`.
///
/// v1.5.1 merged the former separate `/analytics` and `/analytics/insights`
/// screens into this single surface. v1.6 then:
/// - swapped the window picker labels to **7d / 14d / 30d** (the user's
///   locked decision; the underlying enum dropped `quarter`)
/// - added an "MOOD SCORE · LAST {N} DAYS" eyebrow above the chart
/// - paired the eyebrow with an [MbConfidenceBadge]
/// - added a date-range caption under the chart
/// - upgraded the chart-reading guide to a static card on tablet / desktop
///   and an [ExpansionTile] on phone
///
/// Render order (top -> bottom):
///   1. "Patterns" header (Fraunces) + subtitle
///   2. Window chips (7d / 14d / 30d)
///   3. Mood-score chart card (eyebrow + confidence + chart + date range)
///   4. Disclaimer banner [pre-ack] OR pattern-markers + chart-key [post-ack]
///   5. AI PatternInsightCard (Remote Config gated, separate concern)
///   6. Quick stats row (3 cards — always visible)
///   7. Responsive rail: chart reading guide / tier legend / recent
///      triggers (phone = stack, tablet = 2-col, desktop = 3-col)
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final preset = ref.watch(insightsWindowPresetProvider);
    final stream = ref.watch(insightsStreamProvider);
    final gate = ref.watch(insightsGateProvider);
    final entries = ref.watch(myMoodsStreamProvider).value ?? const [];
    final flags = ref.watch(featureFlagsProvider);

    final insights = stream.value ?? const <DailyInsight>[];
    final isReady = gate == InsightsGateState.ready;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isPhone = width < MbBreakpoints.insightsTablet;
            final isDesktop = width >= MbBreakpoints.insightsDesktop;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                MoodBloomSpacing.pagePadding,
                MoodBloomSpacing.pagePadding,
                MoodBloomSpacing.pagePadding,
                MoodBloomSpacing.lg,
              ),
              children: [
                const _Header(),
                const SizedBox(height: MoodBloomSpacing.md),
                _WindowChips(
                  value: preset,
                  onChanged: (p) =>
                      ref.read(insightsWindowPresetProvider.notifier).state = p,
                ),
                const SizedBox(height: MoodBloomSpacing.md),
                _ChartCard(
                  isReady: isReady,
                  stream: stream,
                  insights: insights,
                  preset: preset,
                ),
                const SizedBox(height: MoodBloomSpacing.md),
                // Disclaimer gate is INLINE now: pre-ack shows an
                // explanatory banner inviting the user to read the
                // small print; tapping opens the ack dialog. Post-ack
                // the same slot holds the Pattern-Engine tier markers
                // + the chart-key legend.
                if (!isReady)
                  const _DisclaimerBanner()
                else if (insights.isNotEmpty &&
                    insights.any((d) => d.entryCount > 0)) ...[
                  _PatternCheckInsCard(insights: insights),
                  const SizedBox(height: MoodBloomSpacing.md),
                ],
                // AI-assisted Gemini summary. Remote Config kill-switch
                // hides it without code change if quote generation
                // misbehaves.
                if (flags.aiPatternAnalysisEnabled) ...[
                  const PatternInsightCard(),
                  const SizedBox(height: MoodBloomSpacing.md),
                ],
                _QuickStatsRow(entries: entries, window: preset),
                const SizedBox(height: MoodBloomSpacing.md),
                _BottomRail(
                  isPhone: isPhone,
                  isDesktop: isDesktop,
                  showTriggers: isReady,
                  insights: insights,
                ),
                const SizedBox(height: MoodBloomSpacing.md),
                Text(
                  'MoodBloom is not a medical device. Not a substitute for '
                  'professional care.',
                  style: MbFonts.nunito(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: mb.textDim,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patterns',
          style: MbFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A gentle read of how your garden has been moving lately.',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
        ),
      ],
    );
  }
}

/// 7d / 14d / 30d segmented chips per the v1.6 prototype.
class _WindowChips extends StatelessWidget {
  const _WindowChips({required this.value, required this.onChanged});

  final InsightWindowPreset value;
  final ValueChanged<InsightWindowPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return MbSegmentedToggle<InsightWindowPreset>(
      items: const [
        MbSegmentedItem(value: InsightWindowPreset.week, label: '7d'),
        MbSegmentedItem(value: InsightWindowPreset.fortnight, label: '14d'),
        MbSegmentedItem(value: InsightWindowPreset.month, label: '30d'),
      ],
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Mood-score chart card per the v1.6 prototype: eyebrow + confidence
/// badge above the chart, the chart itself, and a date-range caption
/// below.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.isReady,
    required this.stream,
    required this.insights,
    required this.preset,
  });

  final bool isReady;
  final AsyncValue<List<DailyInsight>?> stream;
  final List<DailyInsight> insights;
  final InsightWindowPreset preset;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MbSectionLabel('MOOD SCORE · LAST ${preset.days} DAYS'),
              ),
              MbConfidenceBadge(level: _confidenceFor(insights)),
            ],
          ),
          const SizedBox(height: MoodBloomSpacing.md),
          SizedBox(height: 220, child: _chartBody(context, mb)),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: MoodBloomSpacing.sm),
            _DateRangeCaption(insights: insights),
          ],
        ],
      ),
    );
  }

  Widget _chartBody(BuildContext context, MbColors mb) {
    if (!isReady) {
      return stream.when(
        loading: () => Center(
          child: Text(
            'Loading your patterns…',
            style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
          ),
        ),
        error: (_, _) => _errorText(mb),
        data: (_) => MoodScoreChart(insights: insights),
      );
    }
    if (insights.isEmpty) {
      return Center(
        child: Text(
          'Loading your patterns…',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
        ),
      );
    }
    final hasAnyEntry = insights.any((d) => d.entryCount > 0);
    if (!hasAnyEntry) {
      return Center(
        child: Text(
          'Your insights will appear here as your garden grows.',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
          textAlign: TextAlign.center,
        ),
      );
    }
    return MoodScoreChart(insights: insights);
  }

  Widget _errorText(MbColors mb) => Center(
    child: Text(
      "We couldn't load your patterns right now.",
      style: MbFonts.nunito(fontSize: 13, color: mb.text),
      textAlign: TextAlign.center,
    ),
  );

  /// Confidence band derived from the entry density inside the window.
  /// More entries -> more confidence. A pure-presentation heuristic; the
  /// real model lives downstream in pattern engine and is exposed via
  /// `MarkerDetailSheet`.
  static MbConfidenceLevel _confidenceFor(List<DailyInsight> insights) {
    if (insights.isEmpty) return MbConfidenceLevel.low;
    final entryDays = insights.where((d) => d.entryCount > 0).length;
    final ratio = entryDays / insights.length;
    if (ratio >= 0.7) return MbConfidenceLevel.high;
    if (ratio >= 0.4) return MbConfidenceLevel.medium;
    return MbConfidenceLevel.low;
  }
}

/// Three-column caption under the chart showing the window's start / mid
/// / end dates ("Apr 14 ... Apr 21 ... Apr 28").
class _DateRangeCaption extends StatelessWidget {
  const _DateRangeCaption({required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final first = insights.first.date;
    final last = insights.last.date;
    final mid = insights[insights.length ~/ 2].date;
    final style = MbFonts.nunito(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: mb.textDim,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_shortDate(first), style: style),
        Text(_shortDate(mid), style: style),
        Text(_shortDate(last), style: style),
      ],
    );
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = d.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }
}

/// Post-ack pattern check-ins card: tier-marker band + chart-key legend
/// + "empty slots are quiet days" reassurance line.
class _PatternCheckInsCard extends StatelessWidget {
  const _PatternCheckInsCard({required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MbSectionLabel('PATTERN CHECK-INS'),
          const SizedBox(height: MoodBloomSpacing.md),
          PatternMarkerBand(insights: insights),
          const SizedBox(height: 10),
          const _ChartKeyRow(),
          const SizedBox(height: 6),
          Text(
            'Empty slots are quiet days - never a streak break.',
            style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
          ),
        ],
      ),
    );
  }
}

/// Inline disclaimer banner replacing the old route-level modal gate.
/// Tapping opens [DisclaimerAckDialog]; on success the
/// `disclaimerAckStreamProvider` flips to `true`, the `insightsGate`
/// transitions to `ready`, and this banner is swapped out for the
/// PatternMarkerBand + RecentTriggersCard slot above.
class _DisclaimerBanner extends ConsumerWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          'Read the medical disclaimer to unlock pattern check-ins. '
          'MoodBloom is not a medical device.',
      child: MbCard(
        padding: const EdgeInsets.all(MoodBloomSpacing.lg),
        onTap: () => _openDialog(context, ref),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.medical_information_outlined,
              color: mb.textDim,
              size: 24,
            ),
            const SizedBox(width: MoodBloomSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unlock pattern check-ins',
                    style: MbFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MoodBloom is not a medical device. Tap to read the '
                    "small print, then we'll show your tier check-ins "
                    'and recent triggers below the chart.',
                    style: MbFonts.nunito(
                      fontSize: 12,
                      height: 1.45,
                      color: mb.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    await DisclaimerAckDialog.show(context, userId: user.uid);
  }
}

/// "How to read this" footnote row, directly under the marker band.
/// Maps the tier numerals to the public-facing words ("gentle /
/// invitation / care") that match the dispatcher's surface copy.
class _ChartKeyRow extends StatelessWidget {
  const _ChartKeyRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final mb = theme.extension<MbColors>()!;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendDot(color: primary, label: 'Mood score'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Rolling rhythm'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Tier 1 gentle'),
        _LegendDot(color: MoodBloomColors.coral, label: 'Tier 2 invitation'),
        _LegendDot(color: mb.destructiveText, label: 'Tier 3 care'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: MbFonts.nunito(fontSize: 11, color: mb.text)),
      ],
    );
  }
}

/// Responsive bottom rail. Phone stacks the chart-reading guide / tier
/// legend / (optional) recent triggers card one-per-row. Tablet renders
/// them in a 2-col grid. Desktop unlocks a 3-col row.
class _BottomRail extends StatelessWidget {
  const _BottomRail({
    required this.isPhone,
    required this.isDesktop,
    required this.showTriggers,
    required this.insights,
  });

  final bool isPhone;
  final bool isDesktop;
  final bool showTriggers;
  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final readingGuide = ChartReadingGuide(alwaysExpanded: !isPhone);
    const tierLegend = TierBandLegend();
    final triggers = showTriggers
        ? RecentTriggersCard(insights: insights)
        : null;

    if (isPhone) {
      return Column(
        children: [
          readingGuide,
          const SizedBox(height: MoodBloomSpacing.md),
          tierLegend,
          if (triggers != null) ...[
            const SizedBox(height: MoodBloomSpacing.md),
            triggers,
          ],
        ],
      );
    }

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: readingGuide),
            const SizedBox(width: MoodBloomSpacing.md),
            const Expanded(child: tierLegend),
            if (triggers != null) ...[
              const SizedBox(width: MoodBloomSpacing.md),
              Expanded(child: triggers),
            ],
          ],
        ),
      );
    }

    // Tablet: 2-col grid. Reading guide + tier legend on the first
    // row; recent triggers (if shown) gets a full-width second row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: readingGuide),
              const SizedBox(width: MoodBloomSpacing.md),
              const Expanded(child: tierLegend),
            ],
          ),
        ),
        if (triggers != null) ...[
          const SizedBox(height: MoodBloomSpacing.md),
          triggers,
        ],
      ],
    );
  }
}

/// Three at-a-glance stats: most-frequent mood, average intensity, and
/// day-streak. Stats are computed at presentation time from the entries
/// list using the same window the chart is showing.
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.entries, required this.window});

  final List<MoodEntry> entries;
  final InsightWindowPreset window;

  int get _windowDays => switch (window) {
    InsightWindowPreset.week => 7,
    InsightWindowPreset.fortnight => 14,
    InsightWindowPreset.month => 30,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final inWindow = entries
        .where((e) => now.difference(e.createdAt).inDays < _windowDays)
        .toList();
    final mostFrequent = _mostFrequentMood(inWindow);
    final avgIntensity = _avgIntensity(inWindow);
    final streak = _dayStreak(entries, now);

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message:
                'The mood you logged most often in the last $_windowDays days.',
            child: _MostFrequentCard(mood: mostFrequent),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message:
                'Average of the intensity sliders (1-5) across '
                '${inWindow.length} ${inWindow.length == 1 ? "entry" : "entries"}.',
            child: _NumberStatCard(
              value: avgIntensity == null
                  ? '-'
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
  /// walking back from today until a gap. Empty entries -> 0.
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
    final label = mood == null ? '-' : mood!.name;
    return MbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          mood == null
              ? Text(
                  '-',
                  style: MbFonts.nunito(fontSize: 22, color: mb.textDim),
                )
              : MbMoodSvg(
                  mood: mood!.mbKind,
                  size: 22,
                  color: palette.colorOf(mood!.mbKind),
                ),
          const SizedBox(height: 4),
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
            style: MbFonts.fraunces(
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
