import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import 'calendar_view.dart';
import 'widgets/mood_entry_tile.dart';

/// Two views the user can flip between with a pill-segmented toggle.
enum HistoryView { list, calendar }

/// Four filters available on the list view. Order matches the prototype's
/// horizontal-scroll chip row. `okay` rolls up under Negative since the
/// domain `MoodCategory` lumps it into `negativeMild`.
enum HistoryFilter { all, positive, negative, thisWeek }

extension on HistoryFilter {
  String get label => switch (this) {
    HistoryFilter.all => 'All',
    HistoryFilter.positive => 'Positive',
    HistoryFilter.negative => 'Negative',
    HistoryFilter.thisWeek => 'This Week',
  };

  /// Filter membership using the two-bucket valence model
  /// (positive / negative). The domain `MoodCategory` lumps "okay" into
  /// `negativeMild`, so it surfaces under the Negative filter alongside
  /// sad / angry / anxious.
  bool matches(MoodEntry entry, DateTime now) {
    switch (this) {
      case HistoryFilter.all:
        return true;
      case HistoryFilter.positive:
        return entry.mood == MoodType.happy || entry.mood == MoodType.calm;
      case HistoryFilter.negative:
        return entry.mood == MoodType.okay ||
            entry.mood == MoodType.sad ||
            entry.mood == MoodType.angry ||
            entry.mood == MoodType.anxious;
      case HistoryFilter.thisWeek:
        return now.difference(entry.createdAt).inDays <= 7;
    }
  }
}

/// History screen — pivot feature surface for the list ↔ calendar swap.
/// Restyled to the Sprint 2 Prototype with [MbSegmentedToggle] for the
/// view swap, a horizontal-scroll [MbFilterChip] row, and [MoodEntryTile]
/// rows in [MbCard]s.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryView _view = HistoryView.list;
  HistoryFilter _filter = HistoryFilter.all;

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
              // calendar tab removes a noisy non-functional control and
              // lets the calendar grid use the full vertical space below
              // the header.
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
                  child: _view == HistoryView.list
                      ? _HistoryListView(
                          key: const ValueKey('list'),
                          filter: _filter,
                        )
                      : const KeyedSubtree(
                          key: ValueKey('calendar'),
                          child: CalendarView(),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      children: [
        Expanded(
          child: Text(
            'History',
            style: MbFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: MbSegmentedToggle<HistoryView>(
            items: const [
              MbSegmentedItem(value: HistoryView.list, label: 'List'),
              MbSegmentedItem(value: HistoryView.calendar, label: 'Calendar'),
            ],
            value: view,
            onChanged: onViewChanged,
            height: 36,
          ),
        ),
      ],
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

class _HistoryListView extends ConsumerWidget {
  const _HistoryListView({super.key, required this.filter});

  final HistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final filtered = entries.where((e) => filter.matches(e, now)).toList()
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
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: MoodBloomSpacing.sm),
          itemBuilder: (context, i) {
            final entry = filtered[i];
            return MoodEntryTile(
              entry: entry,
              onTap: () => context.go('/history/${entry.id}'),
            );
          },
        );
      },
    );
  }
}
