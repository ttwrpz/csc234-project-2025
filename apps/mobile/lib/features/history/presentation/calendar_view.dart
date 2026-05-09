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

/// Width breakpoint at which the calendar switches from a single-column
/// "tap → bottom sheet" layout to a two-column "calendar + side panel"
/// layout. Below this we keep the phone-style flow; above this the user
/// gets a persistent panel listing the selected day's entries.
const double _kSidePanelBreakpoint = 720;

/// Month-grid calendar of mood history. On phone widths, tapping a day cell
/// opens a bottom sheet listing every entry on that day. On tablet/desktop
/// (≥ [_kSidePanelBreakpoint]) we render the calendar on the left and a
/// persistent entries panel on the right that updates with each tap.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// First-of-month, local-time midnight. Initialised to the current month;
  /// users navigate prev/next via the header arrows.
  late DateTime _viewedMonth;

  /// Local-midnight `DateTime` of the day whose entries are shown in the
  /// side panel (desktop / tablet only). Defaults to today on first build.
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
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

  /// Snap back to the current month + select today. Wired to the new
  /// "Today" button in the calendar header so users who have paged months
  /// back can return in one tap.
  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _viewedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    return !_viewedMonth.isBefore(thisMonth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kSidePanelBreakpoint;
        final calendar = _CalendarCard(
          viewedMonth: _viewedMonth,
          selectedDay: wide ? _selectedDay : null,
          onPrev: _goPrevMonth,
          onNext: _isCurrentMonth ? null : _goNextMonth,
          // Hide the Today affordance once the user is already on the
          // current month — it'd be a no-op there.
          onToday: _isCurrentMonth ? null : _goToday,
          onDayTap: wide ? (day) => setState(() => _selectedDay = day) : null,
        );
        if (!wide) return calendar;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: calendar),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _selectedDay == null
                  ? const SizedBox.shrink()
                  : DayEntriesPanel(
                      key: ValueKey(_selectedDay),
                      dayKey: _selectedDay!,
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Just the calendar card — header, weekday row, month grid. Stateless so
/// the parent can drive the selection from outside (the wide layout) or
/// not at all (the phone layout).
class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({
    required this.viewedMonth,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onDayTap,
  });

  final DateTime viewedMonth;

  /// Highlight ring on the selected day (wide layout only). `null` skips
  /// the ring and falls back to the today-cell highlight.
  final DateTime? selectedDay;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  /// Tapping "Today" jumps back to the current month + selects today.
  /// `null` when the user is already viewing the current month — the
  /// header hides the chip in that case.
  final VoidCallback? onToday;

  /// When non-null, day cells call this *instead of* the
  /// detail-or-sheet navigation — used by the wide layout to drive the
  /// side panel without leaving the screen.
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(calendarControllerProvider(viewedMonth));
    final mb = Theme.of(context).extension<MbColors>()!;

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
                month: viewedMonth,
                onPrev: onPrev,
                onNext: onNext,
                onToday: onToday,
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
                data: (state) => _MonthGrid(
                  state: state,
                  selectedDay: selectedDay,
                  onDayTap: onDayTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet wrapper around [DayEntriesPanel]. Used by the calendar's
/// phone layout (when the user taps a multi-entry cell) and by Home's
/// weekly bloom bar (which always uses the modal regardless of viewport).
class DayEntriesSheet extends StatelessWidget {
  const DayEntriesSheet({super.key, required this.dayKey});

  /// Width threshold above which the day-entries surface renders as a
  /// centered dialog rather than a bottom sheet. Below this the
  /// bottom-sheet ergonomics (thumb-reach, drag-to-dismiss) win; above
  /// it a dialog is the natural desktop / web affordance — bottom
  /// sheets feel pinned-to-the-bottom on a 1440px window.
  ///
  /// 720dp was chosen to match the wide-layout breakpoint already in
  /// use elsewhere in this file (`wide = constraints.maxWidth >= 720`).
  static const double _dialogBreakpoint = 720;

  static Future<void> show(BuildContext context, DateTime dayKey) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final width = MediaQuery.of(context).size.width;
    if (width >= _dialogBreakpoint) {
      // Desktop / web wide layout — render as a centered dialog so the
      // mouse-driven dismiss + close button feel native. The same
      // [DayEntriesPanel] body backs both surfaces; only the chrome
      // changes.
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          backgroundColor: mb.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: DayEntriesPanel(dayKey: dayKey, popOnTap: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    // Narrow layout — keep the bottom sheet (phone-class screen).
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: mb.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DayEntriesSheet(dayKey: dayKey),
    );
  }

  final DateTime dayKey;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
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
            DayEntriesPanel(dayKey: dayKey, popOnTap: true),
          ],
        ),
      ),
    );
  }
}

/// The list of entries for a given day. Reused by both the bottom sheet
/// (phone) and the side panel (desktop). When [popOnTap] is true, tapping
/// an entry pops the enclosing route before navigating — the bottom-sheet
/// flow needs that; the side panel does not.
class DayEntriesPanel extends ConsumerWidget {
  const DayEntriesPanel({
    super.key,
    required this.dayKey,
    this.popOnTap = false,
  });

  final DateTime dayKey;
  final bool popOnTap;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          dayEntries.isEmpty
              ? 'No entries'
              : '${dayEntries.length} ${dayEntries.length == 1 ? "entry" : "entries"}',
          style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
        ),
        const SizedBox(height: 12),
        if (dayEntries.isEmpty)
          MbCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Nothing logged here yet — tap Log mood when you're ready.",
              style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final e in dayEntries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (popOnTap) Navigator.of(context).pop();
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
                          color: palette.colorOf(e.mood.mbKind).withAlpha(0x33),
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
                        style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
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
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final label = '${_monthName(month.month)} ${month.year}';
    return Row(
      children: [
        MbIconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          size: MbIconButtonSize.sm,
          semanticLabel: 'Previous month',
        ),
        Expanded(
          child: Center(
            child: Semantics(
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
          ),
        ),
        // Today chip — only rendered once the user has paged away from
        // the current month, so it never duplicates state already on
        // screen. Sits inline with the chevrons so the layout stays
        // tight on narrow phone widths.
        if (onToday != null) ...[
          TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: theme.colorScheme.primary,
              textStyle: MbFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Today'),
          ),
          const SizedBox(width: 4),
        ],
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
  const _MonthGrid({
    required this.state,
    required this.selectedDay,
    required this.onDayTap,
  });

  final CalendarState state;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = state.month;
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
      final isSelected = selectedDay != null && dayKey == selectedDay;
      cells.add(
        _DayCell(
          dayNumber: dayNumber,
          dayKey: dayKey,
          dot: dot,
          isToday: isToday,
          isSelected: isSelected,
          onDayTap: onDayTap,
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
    required this.isSelected,
    required this.onDayTap,
  });

  final int dayNumber;
  final DateTime dayKey;
  final DayDot? dot;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<DateTime>? onDayTap;

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

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isToday ? theme.colorScheme.primary : mb.line);
    final borderWidth = isSelected ? 2.0 : 1.0;

    final cell = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isToday || isSelected
            ? MoodBloomColors.softGreen
            : Colors.transparent,
        border: Border.all(color: borderColor, width: borderWidth),
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
                fontWeight: isToday || isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
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

    // Wide layout drives the side panel on every tap (entries OR not).
    // Phone layout only reacts when there's something to show.
    if (onDayTap != null) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onDayTap!(dayKey),
          child: cell,
        ),
      );
    }

    if (!hasEntry) {
      return Semantics(label: semanticsLabel, child: cell);
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (count > 1) {
            DayEntriesSheet.show(context, dayKey);
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
