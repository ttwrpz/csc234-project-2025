import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../domain/entities/calendar_state.dart';
import 'controllers/calendar_controller.dart';

/// Month-grid calendar of mood history. Restyled to the Sprint 2 Prototype:
/// the whole calendar lives inside a single [MbCard]; header is two
/// chevron [MbIconButton]s flanking the "Month Year" label; each day cell
/// is a 1px-line, r8, aspect-1 box with the day number top-left, a mood
/// color dot bottom-left, and a count badge top-right when entries > 1.
/// Today's cell carries a primary border + soft-green fill + 700 number.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// First-of-month, local-time midnight. Initialised to the current month;
  /// users navigate prev/next via the header arrows.
  late DateTime _viewedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewedMonth = DateTime(now.year, now.month, 1);
  }

  void _goPrevMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month - 1, 1);
    });
  }

  void _goNextMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + 1, 1);
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    return !_viewedMonth.isBefore(thisMonth);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(calendarControllerProvider(_viewedMonth));
    final mb = Theme.of(context).extension<MbColors>()!;

    // Cap calendar to a reasonable max width on tablet/desktop. Without
    // this, each cell on a 1200 dp content column became ~165 dp tall —
    // visually noisy and the source of the layout overflow the user
    // reported. 560 dp keeps cells in the same readable size band the
    // prototype designs for.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: MbCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(
                month: _viewedMonth,
                onPrev: _goPrevMonth,
                onNext: _isCurrentMonth ? null : _goNextMonth,
              ),
              const SizedBox(height: 12),
              const _WeekdayHeaderRow(),
              const SizedBox(height: 4),
              stateAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(MoodBloomSpacing.xl),
                  child: Text(
                    "We couldn't load your calendar right now.",
                    style: MbFonts.nunito(fontSize: 13, color: mb.text),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (state) => _MonthGrid(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet list of all entries on `dayKey`. Triggered when the user
/// taps a multi-entry calendar cell so all the day's entries are reachable,
/// not only the most recent one (which is what the cell's default tap
/// navigation goes to). Reads `myMoodsStreamProvider` so it always sees the
/// freshest snapshot.
class _DayEntriesSheet extends ConsumerWidget {
  const _DayEntriesSheet({required this.dayKey});

  final DateTime dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final entriesAsync = ref.watch(myMoodsStreamProvider);
    final dayLabel =
        '${_monthName(dayKey.month)} ${dayKey.day}, ${dayKey.year}';

    final dayEntries = entriesAsync.maybeWhen(
      data: (all) => [
        for (final e in all)
          if (_truncateToLocalDay(e.createdAt) == dayKey) e,
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      orElse: () => const <MoodEntry>[],
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: mb.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              dayLabel,
              style: MbFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${dayEntries.length} ${dayEntries.length == 1 ? "entry" : "entries"}',
              style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
            ),
            const SizedBox(height: 12),
            for (final e in dayEntries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/history/${e.id}');
                  },
                  child: MbCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: palette
                                .colorOf(e.mood.mbKind)
                                .withAlpha(0x33),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            palette.emojiOf(e.mood.mbKind),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.mood.name,
                                style: MbFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: mb.text,
                                ),
                              ),
                              if (e.text.isNotEmpty)
                                Text(
                                  e.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MbFonts.nunito(
                                    fontSize: 12,
                                    color: mb.textDim,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(e.createdAt),
                          style: MbFonts.nunito(
                            fontSize: 11,
                            color: mb.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime t) {
  final local = t.toLocal();
  final hour = local.hour == 0
      ? 12
      : (local.hour > 12 ? local.hour - 12 : local.hour);
  final mm = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'pm' : 'am';
  return '$hour:$mm $ap';
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final label = '${_monthName(month.month)} ${month.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MbIconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          size: MbIconButtonSize.sm,
          semanticLabel: 'Previous month',
        ),
        Semantics(
          header: true,
          child: Text(
            label,
            style: MbFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
        ),
        MbIconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          size: MbIconButtonSize.sm,
          semanticLabel: 'Next month',
        ),
      ],
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  static const _labels = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final l in _labels)
            Expanded(
              child: Center(
                child: Text(
                  l,
                  style: MbFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: mb.textDim,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = state.month;
    // Dart's DateTime.weekday is 1..7 (Mon..Sun). We render Sun-first, so
    // Sunday lands in column 0 and the leading-blank count is `weekday % 7`.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      firstOfMonth.year,
      firstOfMonth.month + 1,
      0,
    ).day;
    final totalCells = leadingBlanks + daysInMonth;
    final cellCount = (totalCells + 6) ~/ 7 * 7;
    final today = _truncateToLocalDay(DateTime.now());

    final cells = <Widget>[];
    for (var i = 0; i < cellCount; i++) {
      if (i < leadingBlanks || i >= leadingBlanks + daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      final dayNumber = i - leadingBlanks + 1;
      final dayKey = DateTime(firstOfMonth.year, firstOfMonth.month, dayNumber);
      final dot = state.dotsByDay[dayKey];
      final isToday = dayKey == today;
      cells.add(
        _DayCell(
          dayNumber: dayNumber,
          dayKey: dayKey,
          dot: dot,
          isToday: isToday,
        ),
      );
    }

    final grid = GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: cells,
    );

    if (state.isEmpty) {
      return Column(
        children: [
          grid,
          const SizedBox(height: 16),
          const _EmptyStateOverlay(),
        ],
      );
    }
    return grid;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.dayKey,
    required this.dot,
    required this.isToday,
  });

  final int dayNumber;
  final DateTime dayKey;
  final DayDot? dot;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final hasEntry = dot != null;
    final dotColor = hasEntry ? _categoryColor(dot!.dominantCategory) : null;
    final count = dot?.totalEntries ?? 0;
    final semanticsLabel = hasEntry
        ? 'Day $dayNumber, ${dot!.totalEntries} '
              '${dot!.totalEntries == 1 ? "entry" : "entries"}'
        : 'Day $dayNumber, no entries';

    final cell = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday ? MoodBloomColors.softGreen : Colors.transparent,
        border: Border.all(
          color: isToday ? theme.colorScheme.primary : mb.line,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '$dayNumber',
              style: MbFonts.nunito(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: mb.textDim,
              ),
            ),
          ),
          if (hasEntry)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (count > 1)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: MbFonts.nunito(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!hasEntry) {
      return Semantics(label: semanticsLabel, child: cell);
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Single entry → straight to detail. Multi-entry → bottom sheet
          // listing every entry for the day; the previous behaviour silently
          // navigated to only the most-recent one and lost the others.
          if (count > 1) {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: false,
              isScrollControlled: true,
              backgroundColor: theme.extension<MbColors>()!.bg,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _DayEntriesSheet(dayKey: dayKey),
            );
          } else {
            context.go('/history/${dot!.mostRecentEntryId}');
          }
        },
        child: cell,
      ),
    );
  }
}

class _EmptyStateOverlay extends StatelessWidget {
  const _EmptyStateOverlay();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Padding(
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Text(
        'No moods this month — tap Log Mood to start.',
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
        textAlign: TextAlign.center,
      ),
    );
  }
}

DateTime _truncateToLocalDay(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

Color _categoryColor(MoodCategory category) => switch (category) {
  MoodCategory.positive => MoodBloomColors.moodHappy,
  MoodCategory.negativeMild => MoodBloomColors.moodSad,
  MoodCategory.negativeStrong => MoodBloomColors.moodAngry,
};

const _monthNames = <String>[
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

String _monthName(int month) => _monthNames[month - 1];
