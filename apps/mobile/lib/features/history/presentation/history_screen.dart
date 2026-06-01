import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../harvest/presentation/weekly_harvests_tab.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import 'calendar_view.dart';
import 'entry_detail_screen.dart';
import 'widgets/mood_entry_tile.dart';

/// Three views the user can flip between with a pill-segmented toggle:
/// the entry list (default), the calendar, and the archived weekly
/// harvests. The History tab is the canonical surface for the harvests
/// archive.
enum HistoryView { list, calendar, harvests }

/// Filters available on the list view per the v1.6 prototype. Order
/// matches the prototype's `HistoryListScreen` chip row.
enum HistoryFilter { thisWeek, thisMonth, allTime }

extension on HistoryFilter {
  String get label => switch (this) {
    HistoryFilter.thisWeek => 'This week',
    HistoryFilter.thisMonth => 'This month',
    HistoryFilter.allTime => 'All time',
  };

  bool matches(MoodEntry entry, DateTime now) {
    switch (this) {
      case HistoryFilter.thisWeek:
        return now.difference(entry.createdAt).inDays < 7;
      case HistoryFilter.thisMonth:
        return now.difference(entry.createdAt).inDays < 31;
      case HistoryFilter.allTime:
        return true;
    }
  }
}

/// History screen - surface for the list / calendar / harvests swap.
/// Uses [MbSegmentedToggle] for the view swap, a horizontal-scroll
/// [MbFilterChip] row, and [MoodEntryTile] rows in [MbCard]s.
///
/// v1.6 visual refresh: title "History" Fraunces 24 w600, the segmented
/// toggle reads "List / Calendar / Harvest" per the prototype.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryView _view = HistoryView.list;
  HistoryFilter _filter = HistoryFilter.thisWeek;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.pagePadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                view: _view,
                onViewChanged: (v) => setState(() => _view = v),
              ),
              const SizedBox(height: MoodBloomSpacing.md),
              // Filter pills only act on the list. Hiding them on the
              // calendar / harvests tabs removes a noisy non-functional
              // control and lets each grid use the full vertical space
              // below the header.
              if (_view == HistoryView.list) ...[
                _FilterChipRow(
                  value: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: MoodBloomSpacing.md),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: switch (_view) {
                    HistoryView.list => _HistoryListView(
                      key: const ValueKey('list'),
                      filter: _filter,
                    ),
                    HistoryView.calendar => const KeyedSubtree(
                      key: ValueKey('calendar'),
                      child: CalendarView(),
                    ),
                    HistoryView.harvests => const KeyedSubtree(
                      key: ValueKey('harvests'),
                      child: WeeklyHarvestsTab(),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.view, required this.onViewChanged});

  final HistoryView view;
  final ValueChanged<HistoryView> onViewChanged;

  /// Below this width the title + 320 dp segmented toggle no longer
  /// fit comfortably side-by-side, so we stack them vertically.
  static const double _stackBelow = 520;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final title = Text(
      'History',
      style: MbFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
    );
    final toggle = MbSegmentedToggle<HistoryView>(
      items: const [
        MbSegmentedItem(value: HistoryView.list, label: 'List'),
        MbSegmentedItem(value: HistoryView.calendar, label: 'Calendar'),
        MbSegmentedItem(value: HistoryView.harvests, label: 'Harvest'),
      ],
      value: view,
      onChanged: onViewChanged,
      height: 36,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: MoodBloomSpacing.md),
              SizedBox(width: double.infinity, child: toggle),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            SizedBox(width: 320, child: toggle),
          ],
        );
      },
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.value, required this.onChanged});

  final HistoryFilter value;
  final ValueChanged<HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HistoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = HistoryFilter.values[index];
          return MbFilterChip(
            label: filter.label,
            selected: filter == value,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class _HistoryListView extends ConsumerStatefulWidget {
  const _HistoryListView({super.key, required this.filter});

  final HistoryFilter filter;

  @override
  ConsumerState<_HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends ConsumerState<_HistoryListView> {
  /// How many day-sections to render at once. The full history is held
  /// in memory by the stream, but we only build a window of day-cards so
  /// a long history doesn't lay out every entry up front. "Load more"
  /// grows the window by [_pageSize].
  static const int _pageSize = 14;
  int _visible = _pageSize;

  @override
  void didUpdateWidget(_HistoryListView old) {
    super.didUpdateWidget(old);
    // Reset the window when the filter changes so switching to a
    // narrower filter doesn't keep a huge window open.
    if (old.filter != widget.filter) _visible = _pageSize;
  }

  @override
  Widget build(BuildContext context) {
    final moods = ref.watch(myMoodsStreamProvider);
    final mb = Theme.of(context).extension<MbColors>()!;
    return moods.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MoodBloomSpacing.xl),
          child: Text(
            "We couldn't load your history right now.",
            style: MbFonts.nunito(fontSize: 13, color: mb.text),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        final now = DateTime.now();
        final filtered =
            entries.where((e) => widget.filter.matches(e, now)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(MoodBloomSpacing.xl),
              child: Text(
                'Your garden is just getting started.',
                style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        // Group entries by local-midnight day, then render only the
        // first [_visible] day-sections; a "Load more" footer reveals
        // older ones in pages.
        final daySections = _groupAndFillDays(filtered, widget.filter, now);
        final shown = daySections.length <= _visible
            ? daySections.length
            : _visible;
        final hasMore = shown < daySections.length;
        return ListView.builder(
          itemCount: shown + (hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= shown) {
              return _LoadMoreButton(
                onPressed: () => setState(() => _visible += _pageSize),
              );
            }
            return _DaySection(section: daySections[i]);
          },
        );
      },
    );
  }
}

/// Footer button that reveals the next page of older day-sections.
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MoodBloomSpacing.lg),
      child: Center(
        child: MbGhostButton(
          label: 'Load more',
          fullWidth: false,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// One day's slice of the History list - a SUN · APR 28 header and either
/// a dashed empty-day placeholder card or a stack of per-entry MbCards.
///
/// Per the v1.6 prototype each entry sits in its OWN card with 8 dp gaps
/// between siblings (no shared frame, no hairline dividers). Empty days
/// render a single dashed-border card on the surface-dim wash so the row
/// reads as "open" rather than "missing".
class _DaySection extends StatelessWidget {
  const _DaySection({required this.section});

  final _DaySectionData section;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceDim = isDark
        ? MoodBloomColors.surfaceDimDark
        : MoodBloomColors.surfaceDim;
    return Padding(
      padding: const EdgeInsets.only(top: MoodBloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: MbSectionLabel(_headerLabel(section.day)),
          ),
          if (section.entries.isEmpty)
            _EmptyDayCard(surfaceDim: surfaceDim)
          else
            Column(
              children: [
                for (var i = 0; i < section.entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  MoodEntryTile(
                    entry: section.entries[i],
                    onTap: () =>
                        EntryDetailSheet.show(context, section.entries[i].id),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static String _headerLabel(DateTime day) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${weekdays[day.weekday - 1]} · ${months[day.month - 1]} ${day.day}';
  }
}

/// "A quiet day. Empty slots are fine." card rendered when a day in
/// the active filter window has no entries. Uses a dashed border over
/// the surface-dim wash per the v1.6 prototype's empty-day pattern.
class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard({required this.surfaceDim});

  final Color surfaceDim;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return DottedBorder(
      color: mb.line,
      strokeWidth: 1,
      radius: MoodBloomSpacing.radiusCardLg,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceDim,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        ),
        child: Text(
          'A quiet day. Empty slots are fine.',
          style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
        ),
      ),
    );
  }
}

/// Lightweight dashed-border wrapper. Flutter has no first-class dashed
/// border on `BoxDecoration`, so we paint one via a CustomPainter on the
/// child's outer rect.
class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 4,
    this.gapLength = 3,
    this.radius = 14,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.radius != radius;
}

/// Logical day slice with the day's local-midnight key and its entries
/// (possibly empty for a "quiet day" placeholder).
class _DaySectionData {
  const _DaySectionData({required this.day, required this.entries});

  final DateTime day;
  final List<MoodEntry> entries;
}

/// Group [entries] by local-midnight day, then fill in empty days inside
/// the active filter's window so the user sees "A quiet day" cards for
/// missed slots. Returns days in reverse-chronological order so the most
/// recent day surfaces first.
List<_DaySectionData> _groupAndFillDays(
  List<MoodEntry> entries,
  HistoryFilter filter,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  // Decide how many trailing days to fill empties for. "All time" never
  // forces empty placeholders - that would scroll back through the user's
  // entire dormant history.
  final fillSpan = switch (filter) {
    HistoryFilter.thisWeek => 7,
    HistoryFilter.thisMonth => 31,
    HistoryFilter.allTime => 0,
  };

  final buckets = <DateTime, List<MoodEntry>>{};
  for (final e in entries) {
    final local = e.createdAt.toLocal();
    final key = DateTime(local.year, local.month, local.day);
    buckets.putIfAbsent(key, () => []).add(e);
  }

  final filledKeys = <DateTime>{};
  final sections = <_DaySectionData>[];

  for (var i = 0; i < fillSpan; i++) {
    final day = today.subtract(Duration(days: i));
    filledKeys.add(day);
    sections.add(_DaySectionData(day: day, entries: buckets[day] ?? const []));
  }

  // Any entry-bearing days OUTSIDE the fill window still need a row,
  // sorted newest-first. (Relevant only for `allTime` since the other
  // filters either cover the entry window or pre-fill it.)
  final extra = buckets.keys.where((k) => !filledKeys.contains(k)).toList()
    ..sort((a, b) => b.compareTo(a));
  for (final day in extra) {
    sections.add(_DaySectionData(day: day, entries: buckets[day]!));
  }

  // Drop trailing all-empty days for the `thisWeek` / `thisMonth` filters
  // when the user has zero entries in that window. The empty-state at
  // the parent level already covered that case.
  if (sections.every((s) => s.entries.isEmpty)) return [];

  return sections;
}
