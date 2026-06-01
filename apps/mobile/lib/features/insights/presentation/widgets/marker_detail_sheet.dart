import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../intervention/data/providers.dart';
import '../../../intervention/domain/entities/intervention_record.dart';
import '../../../pattern_engine/domain/entities/tier.dart';
import '../../domain/entities/daily_insight.dart';
import '../../domain/entities/pattern_engine_trigger_kind.dart';

/// Marker tap target popover.
///
/// Renders a bottom sheet on phone, a centred dialog on tablet/desktop.
/// Surfaces, in order: the date, the tier name + matching colour swatch,
/// one plain-English reason mapped from [DailyInsight.triggerReasonKey],
/// and an optional "Open the gentle next step" link that routes to the
/// matching `/intervention/*` screen IF an intervention record exists
/// for the day. If no record exists (cooldown blocked, opt-out, or the
/// dispatcher never ran) the link is omitted so the popover never lands
/// in a dead-end CTA.
class MarkerDetailSheet extends ConsumerWidget {
  const MarkerDetailSheet({super.key, required this.insight});

  /// The day the user tapped on the marker band. Carries the tier and the
  /// plain-English reason key.
  final DailyInsight insight;

  /// Launches the popover with the chrome appropriate to the viewport
  /// width. Phone (< 600 dp) uses [showModalBottomSheet]; tablet and
  /// desktop use a centred [showDialog] so the content sits in the
  /// reading line, not at the bottom of a wide window.
  static Future<void> show(BuildContext context, DailyInsight insight) {
    final width = MediaQuery.sizeOf(context).width;
    final mb = Theme.of(context).extension<MbColors>()!;
    if (width < 600) {
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: mb.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        builder: (sheetContext) => MarkerDetailSheet(insight: insight),
      );
    }
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (dialogContext) => Dialog(
        backgroundColor: mb.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MarkerDetailSheet(insight: insight),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final tier = insight.triggeredTier;
    if (tier == null) {
      // Defensive: the band never renders a tap target on null-tier
      // days, but if a future caller invokes us directly we still
      // render a coherent popover.
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(insight.date),
              style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
            ),
            const SizedBox(height: 8),
            Text(
              'A quiet day - nothing flagged.',
              style: MbFonts.nunito(fontSize: 14, color: mb.text),
            ),
          ],
        ),
      );
    }

    // Read the intervention history once per build. We only need the
    // most-recent ~50 to find a match for the tapped day; the watcher
    // already paginates by `limit: 20` by default, but a longer window
    // is safe and keeps the result deterministic across slow networks.
    final recordsAsync = ref.watch(_recentInterventionsStreamProvider);
    final matched = recordsAsync.maybeWhen(
      data: (records) => _matchRecordForDay(records, insight.date, tier),
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(insight.date),
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _tierColor(tier, mb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tierName(tier),
                style: MbFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: mb.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _reasonCopy(insight.triggerReasonKey),
            style: MbFonts.nunito(fontSize: 13, color: mb.text),
          ),
          if (matched != null) ...[
            const SizedBox(height: 14),
            _NextStepLink(
              record: matched,
              onTap: () {
                // Close the popover before navigating so the user
                // does not return to a stale sheet.
                Navigator.of(context).maybePop();
                _navigateToIntervention(context, matched);
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static Color _tierColor(Tier tier, MbColors mb) => switch (tier) {
    Tier.one => MoodBloomColors.amber,
    Tier.two => MoodBloomColors.coral,
    Tier.three => mb.destructiveText,
  };

  /// Public-facing words for the three tiers - match the dispatcher's
  /// surface copy. Tier numbers are engineering jargon and
  /// stay out of the user-facing string.
  static String _tierName(Tier tier) => switch (tier) {
    Tier.one => 'A gentle nudge',
    Tier.two => 'An invitation to reflect',
    Tier.three => 'A care moment',
  };

  /// Plain-English copy keyed off the algorithm that fired. A null reason
  /// key collapses to the neutral observation copy so a
  /// graceful-degradation read of a legacy pattern doc still renders cleanly.
  static String _reasonCopy(PatternEngineTriggerKind? key) {
    return switch (key) {
      PatternEngineTriggerKind.mannKendall =>
        'Gradual decline across the past two weeks.',
      PatternEngineTriggerKind.sliding5of7 =>
        'Five quieter days out of the last seven.',
      PatternEngineTriggerKind.threeConsecutive =>
        'Three days in a row of heavier weather.',
      PatternEngineTriggerKind.zScore =>
        "Today's mood is unusually lower than your own typical.",
      PatternEngineTriggerKind.cusum =>
        'A sustained shift below your usual ground line.',
      null => 'A pattern your garden noticed on this day.',
    };
  }

  /// Walks the records list newest-first and picks the FIRST one whose
  /// `dispatchedAt` falls inside the local-midnight day for [day]. Tier
  /// is checked too so a Tier 1 marker doesn't mis-link to a Tier 3
  /// record dispatched the same day.
  static InterventionRecord? _matchRecordForDay(
    List<InterventionRecord> records,
    DateTime day,
    Tier markerTier,
  ) {
    final local = day.toLocal();
    final start = DateTime(local.year, local.month, local.day);
    final end = start.add(const Duration(days: 1));
    for (final r in records) {
      final at = r.dispatchedAt.toLocal();
      if (!at.isBefore(start) && at.isBefore(end) && r.tier == markerTier) {
        return r;
      }
    }
    return null;
  }

  static void _navigateToIntervention(
    BuildContext context,
    InterventionRecord record,
  ) {
    final name = switch (record.tier) {
      Tier.one => 'intervention.breathing',
      Tier.two => 'intervention.journal',
      Tier.three => 'intervention.crisis',
    };
    context.goNamed(name);
  }
}

/// One-line affordance link. The widget is private - callers always go
/// through [MarkerDetailSheet] so the conditional null-record branch
/// stays the single rendering decision point.
class _NextStepLink extends StatelessWidget {
  const _NextStepLink({required this.record, required this.onTap});

  final InterventionRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Open the gentle next step for this day',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Want to talk through it? Open the gentle next step',
                  style: MbFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streams the user's most-recent intervention records so the popover
/// can check whether a record exists for the tapped day. We pull a
/// generous window (50) so a user who logs frequently still finds
/// matches for a 30-day insight window without firing a custom query.
final _recentInterventionsStreamProvider =
    StreamProvider.autoDispose<List<InterventionRecord>>((ref) {
      final repo = ref.watch(interventionRepositoryProvider);
      return repo.watchHistory(limit: 50);
    });
