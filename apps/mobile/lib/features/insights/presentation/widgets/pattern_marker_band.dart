import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../pattern_engine/domain/entities/tier.dart';
import '../../domain/entities/daily_insight.dart';

/// Horizontal strip of small badge dots aligned to the chart's X axis,
/// one badge per [DailyInsight] day that fired a tier. Tier 1 = amber,
/// Tier 2 = coral, Tier 3 = the destructive coral-text colour. Days
/// without a trigger render a transparent placeholder so the dots stay
/// aligned with the chart's date ticks.
///
/// Every badge carries a `Semantics(label: ...)` so screen readers
/// announce "Tier N trigger on Mon May 10" rather than a bare dot.
class PatternMarkerBand extends StatelessWidget {
  const PatternMarkerBand({super.key, required this.insights});

  final List<DailyInsight> insights;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final hasAny = insights.any((d) => d.triggeredTier != null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (final d in insights)
            Expanded(
              child: Center(
                child: _Marker(
                  tier: d.triggeredTier,
                  date: d.date,
                  placeholderColor: hasAny ? mb.line : Colors.transparent,
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
    required this.tier,
    required this.date,
    required this.placeholderColor,
  });

  final Tier? tier;
  final DateTime date;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
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
    final color = _colorFor(tier!);
    final tierLabel = _labelFor(tier!);
    final dateLabel = _shortDate(date);
    return Semantics(
      label: '$tierLabel trigger on $dateLabel',
      child: Tooltip(
        message: '$tierLabel · $dateLabel',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
