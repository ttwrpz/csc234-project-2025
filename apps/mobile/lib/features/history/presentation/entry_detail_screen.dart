import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';

/// Read-only entry detail. Sprint 2 ships only the scaffold — edit/delete
/// land in S3 along with the 24h immutability enforcement (WBS 3.5).
class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(moodEntryByIdProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Entry')),
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _NotFound(),
        data: (entry) =>
            entry == null ? const _NotFound() : _Detail(entry: entry),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.entry});
  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final created = entry.createdAt.toLocal();
    final dateLabel =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    return ListView(
      padding: const EdgeInsets.all(MoodBloomSpacing.xl),
      children: [
        Text(
          entry.mood.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: MoodBloomSpacing.sm),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MoodBloomColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: MoodBloomSpacing.xl),
        Text('Intensity', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: MoodBloomSpacing.sm),
        Row(
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: MoodBloomSpacing.sm),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < entry.intensity
                      ? MoodBloomColors.seed
                      : MoodBloomColors.outline,
                ),
              ),
            );
          }),
        ),
        if (entry.text.isNotEmpty) ...[
          const SizedBox(height: MoodBloomSpacing.xl),
          Text('Note', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: MoodBloomSpacing.sm),
          Text(entry.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: MoodBloomSpacing.xl),
        Text(
          'Edit and delete arrive in the next release.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MoodBloomColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.xl),
        child: Text(
          "We couldn't find that entry.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
