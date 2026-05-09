import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garden/presentation/widgets/plant_tier_group.dart';
import '../data/providers.dart';
import '../domain/entities/weekly_garden.dart';
import 'archived_week_screen.dart';

/// History tab listing the user's archived weeks newest-first
/// (HB-005 Track 6.1, TC-12).
///
/// Empty state: "Your first week is still growing." — uses
/// approved vocabulary (no "no history yet"-style framing). Tap
/// any tile to open [ArchivedWeekScreen].
class WeeklyHarvestsTab extends ConsumerWidget {
  const WeeklyHarvestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(weeklyGardenHistoryProvider);
    final mb = Theme.of(context).extension<MbColors>()!;

    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MoodBloomSpacing.xl),
          child: Text(
            "We couldn't open your weekly harvests right now.",
            style: MbFonts.nunito(fontSize: 14, color: mb.text),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (weeks) {
        if (weeks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(MoodBloomSpacing.xl),
              child: Text(
                'Your first week is still growing.',
                style: MbFonts.nunito(fontSize: 14, color: mb.textDim),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
          ),
          itemCount: weeks.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: MoodBloomSpacing.md),
          itemBuilder: (context, index) {
            final week = weeks[index];
            return _WeeklyHarvestTile(
              week: week,
              onTap: () => _openWeek(context, week),
            );
          },
        );
      },
    );
  }

  void _openWeek(BuildContext context, WeeklyGarden week) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArchivedWeekScreen(week: week)),
    );
  }
}

class _WeeklyHarvestTile extends StatelessWidget {
  const _WeeklyHarvestTile({required this.week, required this.onTap});

  final WeeklyGarden week;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      onTap: onTap,
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero plant-tier thumbnail. Smaller than the canvas size used
          // on the WeeklySummary screen so it fits the row neatly; the
          // PlantTierGroup widget scales its painter to the supplied
          // logical size.
          PlantTierGroup(
            tier: week.summary.endingPlantTier,
            entryCount: week.summary.totalEntryCount,
            size: const Size(80, 64),
          ),
          const SizedBox(width: MoodBloomSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week.weekId,
                  style: MbFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mb.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${week.summary.totalEntryCount} '
                  '${week.summary.totalEntryCount == 1 ? "entry" : "entries"} · '
                  'avg ${week.summary.averageMoodScore.toStringAsFixed(2)}',
                  style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: mb.textDim),
        ],
      ),
    );
  }
}
