import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/garden_state.dart';

/// 7-day mood-score strip rendered as horizontal cells inside an
/// `MbCard`. Replaces the legacy `WeeklyBloomBar`. Driven by
/// [GardenState.last7Days] (newest first); cells are displayed
/// oldest-on-the-left so today sits at the right edge — matches the
/// reading direction of the previous bar.
///
/// Each cell carries a continuous signed magnitude (`avgScore`) so the
/// fill opacity scales with intensity rather than collapsing to a
/// fixed enum step. Empty days render as a faint outlined placeholder.
///
/// Semantics labels are descriptive (e.g. "Monday, positive day,
/// intensity 0.4") and never use the legacy "wilting" / "rain cloud"
/// vocabulary — see CLAUDE.md copy rules.
class DailyScoreStrip extends StatelessWidget {
  const DailyScoreStrip({
    super.key,
    required this.last7Days,
    this.onDayTap,
    this.compact = true,
  });

  /// Newest-first list of cells (today, yesterday, …, 6 days ago).
  /// Always length 7 (the use case guarantees this).
  final List<DayScore> last7Days;

  /// Optional tap handler — called with the cell's local-midnight
  /// `DateTime`. Empty cells stay non-interactive.
  final ValueChanged<DateTime>? onDayTap;

  /// `true` (default) renders the original phone-class layout (60 dp
  /// strip, 10/13 sp text). `false` is the desktop-class layout —
  /// taller bars, larger headings, more breathing room — used when the
  /// strip lives in a wider home page column.
  final bool compact;

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

  static const List<String> _weekdayNames = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    // Display oldest-first (left to right).
    final displayed = last7Days.reversed.toList(growable: false);

    final titleSize = compact ? 13.0 : 17.0;
    final captionSize = compact ? 11.0 : 13.0;
    final stripHeight = compact ? 60.0 : 110.0;
    final cellGap = compact ? 6.0 : 12.0;
    final headerSpacing = compact ? 10.0 : 16.0;

    return Semantics(
      label: 'Daily score strip - last 7 days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'This week',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mb.text,
                  fontWeight: FontWeight.w600,
                  fontSize: titleSize,
                ),
              ),
              Text(
                'mood scores',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mb.textDim,
                  fontSize: captionSize,
                ),
              ),
            ],
          ),
          SizedBox(height: headerSpacing),
          SizedBox(
            height: stripHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < displayed.length; i += 1) ...[
                  if (i > 0) SizedBox(width: cellGap),
                  Expanded(
                    child: _ScoreCell(
                      day: displayed[i],
                      compact: compact,
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

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.day, required this.compact, this.onTap});

  final DayScore day;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final score = day.avgScore;
    final isEmpty = score == null;
    final magnitude = isEmpty ? 0.0 : score.abs();
    final isPositive = !isEmpty && score >= 0;

    // Cell bar height. Bounded so the column (bar + gap + label) fits
    // inside the parent's `SizedBox`. Empty days render as a thin
    // placeholder; logged days scale with magnitude. Desktop uses a
    // taller scale so the strip reads as a proper insight surface.
    final emptyH = compact ? 6.0 : 10.0;
    final minH = compact ? 10.0 : 16.0;
    final maxH = compact ? 38.0 : 78.0;
    final scaleH = compact ? 28.0 : 62.0;
    final height = isEmpty
        ? emptyH
        : (minH + magnitude * scaleH).clamp(minH, maxH);

    final fillColor = isEmpty
        ? Colors.transparent
        : (isPositive ? theme.colorScheme.primary : MoodBloomColors.moodSad)
              .withValues(alpha: 0.35 + magnitude * 0.5);

    final col = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
            border: isEmpty ? Border.all(color: mb.line, width: 1) : null,
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          DailyScoreStrip._weekdayLetters[day.day.weekday % 7],
          style: theme.textTheme.labelSmall?.copyWith(
            color: mb.textDim,
            fontSize: compact ? 10 : 13,
            fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ],
    );

    final dayName = DailyScoreStrip._weekdayNames[day.day.weekday % 7];
    final semanticLabel = isEmpty
        ? '$dayName, no entries'
        : '$dayName, ${isPositive ? 'positive' : 'gentler'} day, '
              'intensity ${magnitude.toStringAsFixed(1)}';

    if (onTap == null || isEmpty) {
      return Semantics(label: semanticLabel, child: col);
    }
    return Semantics(
      button: true,
      label: '$semanticLabel - open entries',
      child: InkWell(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
        onTap: onTap,
        child: col,
      ),
    );
  }
}
