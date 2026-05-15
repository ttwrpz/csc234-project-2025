import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pattern_engine/domain/entities/tier.dart';
import '../../domain/entities/daily_insight.dart';
import 'marker_detail_sheet.dart';
import 'recent_triggers_card.dart' show insightsFocusedDayIndexProvider;

/// Horizontal strip of small badge dots aligned to the chart's X axis,
/// one badge per [DailyInsight] day that fired a tier. Tier 1 = amber,
/// Tier 2 = coral, Tier 3 = the destructive coral-text colour. Days
/// without a trigger render a transparent placeholder so the dots stay
/// aligned with the chart's date ticks.
///
/// Each tier-trigger dot is a tap target. Tapping opens
/// [MarkerDetailSheet] — phone shows a modal bottom sheet, tablet and
/// desktop show a centred dialog. The popover surfaces the date, tier
/// name, plain-English reason, and (optionally) a link to the matching
/// intervention surface. Untriggered placeholder dots are NOT tappable.
///
/// HB-009 v1.5 cut: the band reads
/// [insightsFocusedDayIndexProvider] and scales the matching dot by
/// 1.6x for 600ms when the [RecentTriggersCard] focuses a day, giving
/// the user a visual anchor without re-implementing fl_chart focus.
/// Chart-line focus is deferred to v1.6 per HB-009 "Engineering notes" §2.
///
/// Every badge carries a `Semantics(label: ...)` so screen readers
/// announce "Tier N trigger on Mon May 10" rather than a bare dot.
class PatternMarkerBand extends ConsumerWidget {
  const PatternMarkerBand({super.key, required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final hasAny = insights.any((d) => d.triggeredTier != null);
    final focused = ref.watch(insightsFocusedDayIndexProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < insights.length; i++)
            Expanded(
              child: Center(
                child: _Marker(
                  insight: insights[i],
                  placeholderColor: hasAny ? mb.line : Colors.transparent,
                  isFocused: focused == i,
                  onTap: insights[i].triggeredTier == null
                      ? null
                      : () {
                          // The user picked this dot directly — clear
                          // any stale focus from the Recent Triggers
                          // list so the next tap on a list row still
                          // animates.
                          ref
                                  .read(
                                    insightsFocusedDayIndexProvider.notifier,
                                  )
                                  .state =
                              null;
                          MarkerDetailSheet.show(context, insights[i]);
                        },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.insight,
    required this.placeholderColor,
    required this.isFocused,
    required this.onTap,
  });

  final DailyInsight insight;
  final Color placeholderColor;
  final bool isFocused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tier = insight.triggeredTier;
    if (tier == null) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: placeholderColor,
          shape: BoxShape.circle,
        ),
      );
    }
    final color = _colorFor(tier);
    final tierLabel = _labelFor(tier);
    final dateLabel = _shortDate(insight.date);
    final dot = AnimatedScale(
      scale: isFocused ? 1.6 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    return Semantics(
      button: true,
      label: '$tierLabel trigger on $dateLabel',
      child: Tooltip(
        message: '$tierLabel · $dateLabel',
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(
            // Pad the hit target so the visible 10 dp dot still hands
            // a ~36 dp tap target to the user (a11y minimum).
            padding: const EdgeInsets.all(8),
            child: dot,
          ),
        ),
      ),
    );
  }

  static Color _colorFor(Tier tier) => switch (tier) {
    Tier.one => MoodBloomColors.amber,
    Tier.two => MoodBloomColors.coral,
    Tier.three => MoodBloomColors.coralText,
  };

  static String _labelFor(Tier tier) => switch (tier) {
    Tier.one => 'Tier 1',
    Tier.two => 'Tier 2',
    Tier.three => 'Tier 3',
  };

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
}
