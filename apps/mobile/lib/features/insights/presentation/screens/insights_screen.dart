import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_insight.dart';
import '../controllers/insights_controller.dart';
import '../widgets/insights_disclaimer_gate.dart';
import '../widgets/insights_window_chips.dart';
import '../widgets/mood_score_chart.dart';
import '../widgets/pattern_marker_band.dart';

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
    final mb = Theme.of(context).extension<MbColors>()!;
    final gate = ref.watch(insightsGateProvider);
    final preset = ref.watch(insightsWindowPresetProvider);
    final stream = ref.watch(insightsStreamProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
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
        const SizedBox(height: MoodBloomSpacing.md),
        InsightsWindowChips(
          value: preset,
          onChanged: (p) =>
              ref.read(insightsWindowPresetProvider.notifier).state = p,
        ),
        const SizedBox(height: MoodBloomSpacing.md),
        // Gate dominates: if the user has not acknowledged the
        // disclaimer, the chart card never renders, regardless of
        // whether the stream has data. The dialog scheduler is the
        // sibling `InsightsDisclaimerGate` above.
        if (gate != InsightsGateState.ready)
          const _PreAckCard()
        else
          stream.when(
            loading: () => const _LoadingCard(),
            error: (_, _) => const _ErrorCard(),
            data: (insights) => insights == null
                ? const _LoadingCard()
                : _ChartCard(insights: insights),
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
          _LegendRow(),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendDot(color: primary, label: 'Mood score'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Garden health'),
        _LegendDot(color: MoodBloomColors.amber, label: 'Tier 1 day'),
        _LegendDot(color: MoodBloomColors.coral, label: 'Tier 2 day'),
        _LegendDot(color: MoodBloomColors.coralText, label: 'Tier 3 day'),
        const SizedBox.shrink(),
        Text(
          'Empty slots are quiet days — never a streak break.',
          style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
        ),
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
