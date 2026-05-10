import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../garden/presentation/widgets/garden_bed.dart';
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../domain/entities/weekly_garden.dart';

/// Detail screen for a single archived [WeeklyGarden] (HB-005 TC-13).
///
/// Renders the week's hero plant tier + summary stats at the top, then
/// every entry from the archive in a list. Tapping a tile routes to
/// the existing entry-detail screen at `/history/<id>` (read-only after
/// the same-day immutability boundary, which is enforced by
/// [MoodEntry.isLocked]).
class ArchivedWeekScreen extends StatelessWidget {
  const ArchivedWeekScreen({super.key, required this.week});

  final WeeklyGarden week;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final entries = [...week.entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: Text(
          week.weekId,
          style: MbFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: mb.text,
          ),
        ),
        backgroundColor: mb.bg,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
          ),
          itemCount: entries.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: MoodBloomSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SummaryHeader(week: week);
            }
            final entry = entries[index - 1];
            return MoodEntryTile(
              entry: entry,
              onTap: () => context.go('/history/${entry.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.week});

  final WeeklyGarden week;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GardenBed(
              entries: week.entries,
              tier: week.summary.endingPlantTier,
              size: const Size(280, 140),
              showOverflowBadge: true,
            ),
          ),
          const SizedBox(height: MoodBloomSpacing.md),
          Text(
            'A complete chapter — ${week.summary.totalEntryCount} '
            '${week.summary.totalEntryCount == 1 ? "entry" : "entries"} · '
            'avg ${week.summary.averageMoodScore.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
          ),
        ],
      ),
    );
  }
}
