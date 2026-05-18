import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../pattern_engine/domain/entities/tier.dart';
import '../../domain/entities/daily_insight.dart';
import '../../domain/entities/pattern_engine_trigger_kind.dart';
import 'marker_detail_sheet.dart';

/// Recent triggers — the last 5 days that fired any tier, newest first.
///
/// Each row reads `MMM D · tier-name · short reason`. Tapping a row
/// (a) publishes the day index to [insightsFocusedDayIndexProvider] so
/// the marker band animates a scale on that dot and (b) opens the
/// [MarkerDetailSheet] so the reader has the popover in front of them,
/// mirroring the gesture they would have made on the marker directly.
///
/// If the user has no trigger days yet the card collapses to a one-line
/// neutral message — no streak-shaming, per CLAUDE.md copy rules.
class RecentTriggersCard extends ConsumerWidget {
  const RecentTriggersCard({super.key, required this.insights});

  /// The same list the chart renders. We walk it once and pick the
  /// `triggeredTier != null` entries newest-first, capped at 5.
  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final triggers = _pickRecent(insights);

    return Semantics(
      container: true,
      label: 'Recent triggers',
      child: MbCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent triggers',
              style: MbFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: mb.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The last 5 days your garden noticed a pattern.',
              style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
            ),
            const SizedBox(height: 10),
            if (triggers.isEmpty)
              Text(
                'No triggers in this window yet — quiet days only.',
                style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              )
            else
              for (final t in triggers) ...[
                _TriggerRow(
                  entry: t,
                  onTap: () {
                    ref.read(insightsFocusedDayIndexProvider.notifier).state =
                        t.indexInWindow;
                    MarkerDetailSheet.show(context, t.insight);
                  },
                ),
                if (t != triggers.last) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  /// Walks the window once, keeps `triggeredTier != null` entries, and
  /// returns the newest 5 paired with their index inside the original
  /// window. The index lets the marker band locate the matching dot
  /// when the row is tapped.
  static List<_TriggerEntry> _pickRecent(List<DailyInsight> insights) {
    final hits = <_TriggerEntry>[];
    for (var i = 0; i < insights.length; i++) {
      if (insights[i].triggeredTier != null) {
        hits.add(_TriggerEntry(insight: insights[i], indexInWindow: i));
      }
    }
    // Newest first — the window is already date-ascending so reverse.
    final newestFirst = hits.reversed.toList();
    return newestFirst.take(5).toList();
  }
}

class _TriggerEntry {
  const _TriggerEntry({required this.insight, required this.indexInWindow});

  final DailyInsight insight;
  final int indexInWindow;
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({required this.entry, required this.onTap});

  final _TriggerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final tier = entry.insight.triggeredTier;
    return Semantics(
      button: true,
      label:
          '${_longDate(entry.insight.date)}, '
          '${_tierName(tier)}. '
          '${_reasonShort(entry.insight.triggerReasonKey)} '
          'Tap to focus.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _tierColor(tier, mb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: Text(
                  _shortDate(entry.insight.date),
                  style: MbFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mb.text,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _reasonShort(entry.insight.triggerReasonKey),
                  style: MbFonts.nunito(fontSize: 12, color: mb.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: mb.textDim),
            ],
          ),
        ),
      ),
    );
  }

  static Color _tierColor(Tier? tier, MbColors mb) => switch (tier) {
    Tier.one => MoodBloomColors.amber,
    Tier.two => MoodBloomColors.coral,
    Tier.three => mb.destructiveText,
    null => MoodBloomColors.onSurfaceMuted,
  };

  static String _tierName(Tier? tier) => switch (tier) {
    Tier.one => 'gentle nudge',
    Tier.two => 'invitation to reflect',
    Tier.three => 'care moment',
    null => 'quiet day',
  };

  /// Short reason copy — used inline in the row to keep the layout
  /// readable. Mirrors [MarkerDetailSheet]'s plain-English mapping but
  /// trimmed for a ~40-char column.
  static String _reasonShort(PatternEngineTriggerKind? key) {
    return switch (key) {
      PatternEngineTriggerKind.mannKendall => 'gradual decline (Mann-Kendall)',
      PatternEngineTriggerKind.sliding5of7 => '5 quieter days out of 7',
      PatternEngineTriggerKind.threeConsecutive => '3 days of heavier weather',
      PatternEngineTriggerKind.zScore => 'unusually lower than your typical',
      PatternEngineTriggerKind.cusum => 'sustained shift below ground line',
      null => 'a pattern noticed on this day',
    };
  }

  static String _shortDate(DateTime date) {
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
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }

  static String _longDate(DateTime date) {
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
}

/// The currently focused day index in the chart's window — published by
/// [RecentTriggersCard] taps so [PatternMarkerBand] can scale the
/// matching dot. Resets to `null` when the window changes or when the
/// user taps a marker directly.
final insightsFocusedDayIndexProvider = StateProvider<int?>((_) => null);
