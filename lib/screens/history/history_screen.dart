import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/routes.dart';
import '../../models/mood_entry.dart';
import '../../models/mood_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_card.dart';
import 'calendar_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isCalendarView = false;
  final Set<MoodType> _filters = {};

  @override
  Widget build(BuildContext context) {
    final moodProvider = context.watch<MoodProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredEntries = _filters.isEmpty
        ? moodProvider.entries
        : moodProvider.filteredEntries(_filters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
            tooltip: _isCalendarView ? 'List view' : 'Calendar view',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Filter chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _filters.isEmpty,
                        onSelected: (_) => setState(() => _filters.clear()),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    ...MoodType.values.map((mood) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          avatar: Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          label: Text(mood.label),
                          selected: _filters.contains(mood),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _filters.add(mood);
                              } else {
                                _filters.remove(mood);
                              }
                            });
                          },
                          selectedColor: mood.color.withValues(alpha: 0.2),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _isCalendarView
                    ? MoodCalendarView(
                        entries: moodProvider.entries,
                        onEntryTap: (entry) => _openDetail(entry),
                      )
                    : _buildListView(filteredEntries, moodProvider, auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
    List<MoodEntry> entries,
    MoodProvider moodProvider,
    AuthProvider auth,
  ) {
    if (moodProvider.isLoading && entries.isEmpty) {
      return _buildShimmerList(context);
    }

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F4DD}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No mood entries yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Start by logging your first mood!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        if (auth.user != null) {
          await moodProvider.refreshEntries(auth.user!.uid);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return MoodCard(
            entry: entries[index],
            onTap: () => _openDetail(entries[index]),
          );
        },
      ),
    );
  }

  void _openDetail(MoodEntry entry) {
    Navigator.of(context).pushNamed(AppRoutes.entryDetail, arguments: entry);
  }

  Widget _buildShimmerList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3A3A50) : const Color(0xFFF5F5F5),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
