import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/garden_state.dart';

/// "This week's bloom" — a 7-day mood strip rendered as vertical bars
/// inside an `MbCard`. Today is on the right, six days ago on the left.
///
/// Spec (per prototype):
///  * Header row: "This week's bloom" left, "mood strip" right (dim).
///  * Each day cell is a flexed column { coloured bar, weekday letter }.
///  * Bar height: `6` if the day is empty, otherwise `10 + |score| * 14`
///    where score is +1 for bloom, -1 for any negative kind. We
///    approximate "score magnitude" from `DayBloomKind` since the
///    pre-aggregated `DayBloom` does not carry intensity.
///  * Bar colour: primary for bloom, amber for any negative; both at
///    85% opacity. Empty days render as a 1px dashed-border placeholder.
class WeeklyBloomBar extends StatelessWidget {
  const WeeklyBloomBar({super.key, required this.days, this.onDayTap});

  /// Newest-first list of cells (today, yesterday, …). Always length 7.
  final List<DayBloom> days;

  /// Optional tap handler — called with the local-midnight `DateTime` of
  /// the tapped column. Home wires this to open a bottom-sheet listing
  /// the day's entries; the bar still renders read-only when null.
  final ValueChanged<DateTime>? onDayTap;

  // SMTWTFS — index by `DateTime.weekday % 7` so Sunday=0.
  static const List<String> _weekdayLetters = <String>[
    'S', // Sunday (weekday=7 → 7%7=0)
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    // Display oldest-first (left to right).
    final displayed = days.reversed.toList(growable: false);

    return Semantics(
      label: 'Weekly bloom bar — last 7 days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "This week's bloom",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mb.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                'mood strip',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mb.textDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < displayed.length; i += 1) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _BloomColumn(
                      day: displayed[i],
                      onTap: onDayTap == null
                          ? null
                          : () => onDayTap!(
                              _truncateToLocalDay(displayed[i].day),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _truncateToLocalDay(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

class _BloomColumn extends StatelessWidget {
  const _BloomColumn({required this.day, this.onTap});

  final DayBloom day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final isEmpty = day.kind == DayBloomKind.empty;
    final isBloom = day.kind == DayBloomKind.bloom;
    final isNegative =
        day.kind == DayBloomKind.wilting || day.kind == DayBloomKind.rainCloud;

    // Heights: empty = 6 (a thin bar), bloom = +1 magnitude, wilting =
    // -1, rainCloud = -2 (visually heavier).
    final magnitude = switch (day.kind) {
      DayBloomKind.empty => 0.0,
      DayBloomKind.bloom => 1.0,
      DayBloomKind.wilting => 1.0,
      DayBloomKind.rainCloud => 2.0,
    };
    final height = isEmpty ? 6.0 : (10.0 + magnitude * 14.0).clamp(10.0, 60.0);
    final color = isBloom
        ? theme.colorScheme.primary
        : isNegative
        ? MoodBloomColors.amber
        : mb.line;
    final opacity = isEmpty ? 0.3 : 0.85;

    final col = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isEmpty
                ? Colors.transparent
                : color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
            border: isEmpty ? Border.all(color: mb.line, width: 1) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          WeeklyBloomBar._weekdayLetters[day.day.weekday % 7],
          style: theme.textTheme.labelSmall?.copyWith(
            color: mb.textDim,
            fontSize: 10,
          ),
        ),
      ],
    );

    final semanticLabel = switch (day.kind) {
      DayBloomKind.bloom => 'Bloom day',
      DayBloomKind.rainCloud => 'A heavier day',
      DayBloomKind.wilting => 'A gentler day',
      DayBloomKind.empty => 'Empty day',
    };

    // Empty days have nothing to show in the sheet, so they stay
    // non-interactive even when the parent supplied an `onTap`.
    if (onTap == null || isEmpty) {
      return Semantics(label: semanticLabel, child: col);
    }
    return Semantics(
      button: true,
      label: '$semanticLabel — open entries',
      child: InkWell(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
        onTap: onTap,
        child: col,
      ),
    );
  }
}
