import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../garden/presentation/widgets/garden_bed.dart';
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../domain/entities/weekly_garden.dart';

/// Detail screen for a single archived [WeeklyGarden].
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
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.md,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
          ),
          itemCount: entries.length + 2,
          separatorBuilder: (_, _) =>
              const SizedBox(height: MoodBloomSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Row(
                children: [
                  MbIconButton(
                    icon: const Icon(Icons.arrow_back),
                    semanticLabel: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/history');
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    week.weekId,
                    style: MbFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                    ),
                  ),
                ],
              );
            }
            if (index == 1) {
              return _SummaryHeader(week: week);
            }
            final entry = entries[index - 2];
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
      // Let the bed fill the available card width on tablet / desktop
      // so the flowers spread instead of clustering in a hard-coded
      // 280 dp slot. Aspect ratio held at 2:1 so the bed scales
      // proportionally; very wide cards (≥ 720) get an extra height
      // bump for breathing room.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.clamp(280.0, 720.0);
          final h = w >= 600 ? w * 0.42 : w * 0.5;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GardenBed(
                  entries: week.entries,
                  tier: week.summary.endingPlantTier,
                  size: Size(w, h),
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
          );
        },
      ),
    );
  }
}
