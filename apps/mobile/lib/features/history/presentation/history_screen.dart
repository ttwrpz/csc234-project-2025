import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mood/data/providers.dart';
import 'calendar_view.dart';
import 'widgets/mood_entry_tile.dart';

/// History screen — two tabs:
///   1. List   — chronological list of mood entries (S2 walking skeleton).
///   2. Calendar — month-grid with colored dots on days that have entries
///      (S3 WBS 5.1).
///
/// Tab toggle lives entirely inside `/history`; no new routes are added.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'List', icon: Icon(Icons.list)),
              Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: const TabBarView(children: [_HistoryListView(), CalendarView()]),
      ),
    );
  }
}

class _HistoryListView extends ConsumerWidget {
  const _HistoryListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(myMoodsStreamProvider);
    return moods.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MoodBloomSpacing.xl),
          child: Text(
            "We couldn't load your history right now.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(MoodBloomSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_outlined,
                    size: 96,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: MoodBloomSpacing.lg),
                  Text(
                    'Your history starts here.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MoodBloomSpacing.sm),
                  Text(
                    'Log a mood from the Log tab and it will show up here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, i) {
            final entry = entries[i];
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
