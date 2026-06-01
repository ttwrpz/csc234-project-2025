import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../history/presentation/entry_detail_screen.dart';
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../domain/entities/weekly_garden.dart';
import 'widgets/harvest_mini_garden.dart';

/// Detail screen for a single archived [WeeklyGarden].
///
/// Renders the week's hero plant tier + summary stats at the top, then
/// every entry from the archive in a list. Tapping a tile opens the
/// entry-detail modal (read-only after the same-day immutability
/// boundary, which is enforced by [MoodEntry.isLocked]).
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
              // Refreshed header per the prototype's archive-detail
              // treatment - slightly larger Fraunces title (18 w600),
              // tighter row gap, back chevron retained for in-router
              // navigation.
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      week.weekId,
                      style: MbFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: mb.text,
                      ),
                    ),
                  ),
                  const MbLockBadge(small: true),
                ],
              );
            }
            if (index == 1) {
              return _SummaryHeader(week: week);
            }
            final entry = entries[index - 2];
            return MoodEntryTile(
              entry: entry,
              onTap: () => EntryDetailSheet.show(context, entry.id),
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
    final avg = week.summary.averageMoodScore;
    final entryCount = week.summary.totalEntryCount;
    // Card body refreshed per the prototype's `HarvestCard` shape -
    // hero garden snapshot on top, then a stat row separated from the
    // hero by a 1px border-top.
    return MbCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Same mini-garden the harvest cards + home use, taller
              // here so the detail hero reads as a feature.
              HarvestMiniGarden(
                entries: week.entries,
                weekStart: week.weekStart,
                tier: week.summary.endingPlantTier,
                height: 160,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoodBloomSpacing.lg,
                  MoodBloomSpacing.md,
                  MoodBloomSpacing.lg,
                  MoodBloomSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: mb.line)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: MoodBloomSpacing.md,
                        ),
                        child: Wrap(
                          spacing: MoodBloomSpacing.lg,
                          runSpacing: MoodBloomSpacing.sm,
                          children: [
                            _Stat(
                              label: 'AVG',
                              value:
                                  '${avg >= 0 ? '+' : ''}'
                                  '${avg.toStringAsFixed(2)}',
                              accent: avg >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : MoodBloomColors.moodSad,
                            ),
                            _Stat(label: 'ENTRIES', value: '$entryCount'),
                            _Stat(
                              label: 'TIER',
                              value: week.summary.endingPlantTier.name,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact label/value pair used inside the archived-week summary card.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: MbFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: mb.textDim,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: MbFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: accent ?? mb.text,
          ),
        ),
      ],
    );
  }
}
