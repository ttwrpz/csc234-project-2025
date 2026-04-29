import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/domain/entities/mood_type.dart';
import '../domain/entities/calendar_state.dart';
import 'controllers/calendar_controller.dart';

/// Month-grid calendar of mood history. Read-only: each day with at least one
/// entry shows a colored dot; tapping the day routes to `/history/<id>` for
/// the most-recent entry of that day.
///
/// Lives inside `HistoryScreen` as the second tab (List / Calendar). No new
/// routes are added — the in-screen tab toggle is the entire navigation.
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

    return Column(
      children: [
        _MonthHeader(
          month: _viewedMonth,
          onPrev: _goPrevMonth,
          onNext: _isCurrentMonth ? null : _goNextMonth,
        ),
        const SizedBox(height: MoodBloomSpacing.sm),
        const _WeekdayHeaderRow(),
        Expanded(
          child: stateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(MoodBloomSpacing.xl),
                child: Text(
                  "We couldn't load your calendar right now.",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (state) => _MonthGrid(state: state),
          ),
        ),
      ],
    );
  }
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
    final label = '${_monthName(month.month)} ${month.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MoodBloomSpacing.lg,
        vertical: MoodBloomSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: onPrev,
          ),
          Semantics(
            header: true,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  static const _labels = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.sm),
        child: Row(
          children: [
            for (final l in _labels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: MoodBloomColors.onSurfaceMuted,
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = state.month;
    // Dart: DateTime.weekday is 1..7 (Mon..Sun). We render Sun-first, so
    // Sunday lands in column 0 and the leading-blank count is `weekday % 7`.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      firstOfMonth.year,
      firstOfMonth.month + 1,
      0,
    ).day;
    final totalCells = leadingBlanks + daysInMonth;
    // Round up to a whole row of 7.
    final cellCount = (totalCells + 6) ~/ 7 * 7;

    final grid = Padding(
      padding: const EdgeInsets.all(MoodBloomSpacing.sm),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: cellCount,
        itemBuilder: (context, i) {
          if (i < leadingBlanks || i >= leadingBlanks + daysInMonth) {
            return const SizedBox.shrink();
          }
          final dayNumber = i - leadingBlanks + 1;
          final dayKey = DateTime(
            firstOfMonth.year,
            firstOfMonth.month,
            dayNumber,
          );
          final dot = state.dotsByDay[dayKey];
          return _DayCell(dayNumber: dayNumber, dot: dot);
        },
      ),
    );

    if (state.isEmpty) {
      return Column(
        children: [
          Expanded(child: grid),
          const _EmptyStateOverlay(),
          const SizedBox(height: MoodBloomSpacing.xl),
        ],
      );
    }
    return grid;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.dayNumber, required this.dot});

  final int dayNumber;
  final DayDot? dot;

  @override
  Widget build(BuildContext context) {
    final hasEntry = dot != null;
    final dotColor = hasEntry ? _categoryColor(dot!.dominantCategory) : null;
    final semanticsLabel = hasEntry
        ? 'Day $dayNumber, ${dot!.totalEntries} '
              '${dot!.totalEntries == 1 ? "entry" : "entries"}'
        : 'Day $dayNumber, no entries';

    final cell = Padding(
      padding: const EdgeInsets.all(MoodBloomSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
          color: hasEntry ? MoodBloomColors.surfaceDim : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MoodBloomColors.onSurface,
              ),
            ),
            const SizedBox(height: MoodBloomSpacing.xs),
            if (hasEntry)
              Container(
                width: dot!.totalEntries > 1 ? 10 : 8,
                height: dot!.totalEntries > 1 ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!hasEntry) {
      return Semantics(label: semanticsLabel, child: cell);
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSm),
        onTap: () => context.go('/history/${dot!.mostRecentEntryId}'),
        child: cell,
      ),
    );
  }
}

class _EmptyStateOverlay extends StatelessWidget {
  const _EmptyStateOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: MoodBloomColors.onSurfaceMuted,
            ),
            const SizedBox(height: MoodBloomSpacing.md),
            Text(
              'No moods this month — tap Log Mood to start.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MoodBloomColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
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
