import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/garden_state.dart';

/// Horizontal 7-cell bar showing the dominant mood for each of the last 7
/// days. Today is on the right; six days ago is on the left.
///
/// S3 only renders two states per cell:
///  * [DayBloomKind.bloom] — at least one positive mood that day, painted
///    with the warm "happy" hue.
///  * [DayBloomKind.empty] — no positive mood (or no entries at all),
///    painted with the muted neutral surface. *Not* a wilting/rain-cloud
///    icon — those land in S4.
class WeeklyBloomBar extends StatelessWidget {
  const WeeklyBloomBar({super.key, required this.days});

  /// Newest-first list of cells (today, yesterday, …). Always length 7.
  final List<DayBloom> days;

  /// Single-letter weekday labels in `weekday`-index order (Mon=1 … Sun=7).
  /// We render the labels in display order — same order the bar paints.
  static const List<String> _weekdayLetters = <String>[
    '', // 0 unused; DateTime.weekday is 1-based.
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    // The brief specifies newest-first ordering; we display oldest-first
    // (left to right) so the chart reads as a normal week timeline.
    final displayed = days.reversed.toList(growable: false);

    return Semantics(
      label: 'Weekly bloom bar — last 7 days',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final day in displayed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MoodBloomSpacing.xs,
                      ),
                      child: _BloomCell(day: day),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MoodBloomSpacing.xs),
            Row(
              children: [
                for (final day in displayed)
                  Expanded(
                    child: Center(
                      child: Text(
                        _weekdayLetters[day.day.weekday],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: MoodBloomColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BloomCell extends StatelessWidget {
  const _BloomCell({required this.day});

  final DayBloom day;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    final color = switch (day.kind) {
      DayBloomKind.bloom => MoodBloomColors.moodHappy,
      DayBloomKind.empty => MoodBloomColors.surfaceDim,
    };
    return Semantics(
      label: switch (day.kind) {
        DayBloomKind.bloom => 'Bloom day',
        DayBloomKind.empty => 'Empty day',
      },
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
          border: Border.all(color: MoodBloomColors.outline, width: 0.5),
        ),
      ),
    );
  }
}
