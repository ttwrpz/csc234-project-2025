import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_insight.dart';
import '../controllers/insights_controller.dart';
import '../widgets/chart_reading_guide.dart';
import '../widgets/insights_disclaimer_gate.dart';
import '../widgets/insights_layout.dart';
import '../widgets/insights_window_chips.dart';
import '../widgets/mood_score_chart.dart';
import '../widgets/pattern_marker_band.dart';
import '../widgets/recent_triggers_card.dart';
import '../widgets/tier_band_legend.dart';

/// (S5) Insights screen — visualises Pattern Engine output as a
/// mood-score time-series with a Garden-Health overlay and tier-trigger
/// markers. Gated behind a mandatory bipolar / medical disclaimer ack
/// on first view (spec §4, TC-36) — the chart is NEVER rendered until
/// `users/{uid}.insightsDisclaimerAcked == true`.
///
/// Persistence: the ack lives on the user doc, so a sign-out / reinstall
/// still sees the same `true` and skips the dialog (TC-37). The
/// non-dismissible `DisclaimerAckDialog` is the only path to flip the
/// flag from this screen.
///
/// Read-only — no writes happen here. The Pattern Engine runs
/// elsewhere (on every mood save in `LogMoodController`); this screen
/// visualises the persisted outputs.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      // The gate WIDGET handles the dialog scheduling; the
      // `insightsGateProvider` switch below handles the chart
      // visibility. Wrapping the body in the gate keeps the dialog
      // logic out of the build() flow.
      body: const InsightsDisclaimerGate(
        child: SafeArea(child: _InsightsBody()),
      ),
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(insightsWindowPresetProvider);
    final stream = ref.watch(insightsStreamProvider);
    final gate = ref.watch(insightsGateProvider);

    // Resolve the chart card once for all three layouts. The gate
    // dominates: until ack lands the chart slot shows the pre-ack card.
    Widget chartSlot;
    List<DailyInsight> insightsForRails;
    if (gate != InsightsGateState.ready) {
      chartSlot = const _PreAckCard();
      insightsForRails = const <DailyInsight>[];
    } else {
      chartSlot = stream.when(
        loading: () => const _LoadingCard(),
        error: (_, _) => const _ErrorCard(),
        data: (insights) => insights == null
            ? const _LoadingCard()
            : _ChartCard(insights: insights),
      );
      insightsForRails = stream.value ?? const <DailyInsight>[];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone =
            constraints.maxWidth < InsightsLayout.phoneTabletBreakpoint;
        return InsightsLayout(
          header: const _Header(),
          // Phone collapses the guide behind an expansion tile; the
          // larger layouts always show the guide expanded so the rail
          // never has a tap-to-reveal interaction.
          readingGuide: ChartReadingGuide(alwaysExpanded: !isPhone),
          windowChips: InsightsWindowChips(
            value: preset,
            onChanged: (p) =>
                ref.read(insightsWindowPresetProvider.notifier).state = p,
          ),
          chart: chartSlot,
          tierLegend: const TierBandLegend(),
          recentTriggers: RecentTriggersCard(insights: insightsForRails),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: MbFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // No clinical language; "notice / explore" verbs per CLAUDE.md
          // copy rules.
          'A gentle read of how your garden has been moving lately.',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
        ),
      ],
    );
  }
}

/// Card shown before the disclaimer ack lands. Renders no data — the
/// dialog (modal) covers the screen and the user must tap "I understand"
/// to continue. We still draw a soft placeholder so the layout doesn't
/// flash empty when the dialog is dismissed before ack.
class _PreAckCard extends StatelessWidget {
  const _PreAckCard();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Reviewing the small print first.',
            style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Loading your insights…',
            style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "We couldn't load your insights right now.",
            style: MbFonts.nunito(fontSize: 13, color: mb.text),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final hasAnyEntry = insights.any((d) => d.entryCount > 0);
    if (!hasAnyEntry) {
      return MbCard(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'Your insights will appear here as your garden grows.',
              style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
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
                'Mood score over time',
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
          SizedBox(height: 220, child: MoodScoreChart(insights: insights)),
          const SizedBox(height: 8),
          PatternMarkerBand(insights: insights),
          const SizedBox(height: 8),
          _ChartKeyRow(),
          const SizedBox(height: 6),
          Text(
            'Empty slots are quiet days — never a streak break.',
            style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
          ),
        ],
      ),
    );
  }
}

/// HB-009 Decision C-4 — inline "How to read this" footnote row,
/// directly under the marker band. Replaces the legacy `_LegendRow`
/// that used engineering jargon ("Tier 1 day"); the new copy maps
/// the tier numerals to the public-facing words ("gentle / invitation
/// / care") that match the dispatcher's surface copy.
class _ChartKeyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendDot(color: primary, label: 'Mood score'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Rolling rhythm'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Tier 1 gentle'),
        _LegendDot(color: MoodBloomColors.coral, label: 'Tier 2 invitation'),
        _LegendDot(color: MoodBloomColors.coralText, label: 'Tier 3 care'),
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
