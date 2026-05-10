import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garden/domain/entities/flower_species.dart';
import '../../garden/presentation/widgets/flower_sprite.dart';
import '../../garden/presentation/widgets/garden_bed.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
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

/// Glanceable row of flower-species sprites — one per top mood of the
/// archived week. Gives the History list a visual cue of "what kind of
/// week" each archived week was without forcing the user to open it.
/// Empty input renders an empty box (no overflow / no caption).
class _DominantSpeciesCluster extends StatelessWidget {
  const _DominantSpeciesCluster({required this.counts});

  final Map<MoodType, int> counts;

  static const int _maxSprites = 4;

  List<MapEntry<MoodType, int>> get _topMoods {
    final entries = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.index.compareTo(b.key.index);
      });
    return entries.take(_maxSprites).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final top = _topMoods;
    if (top.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final entry in top) ...[
          FlowerSprite(
            species: FlowerSpecies.forMood(entry.key),
            size: 16,
            tint: palette.colorOf(entry.key.mbKind),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _WeeklyHarvestTile extends StatelessWidget {
  const _WeeklyHarvestTile({required this.week, required this.onTap});

  final WeeklyGarden week;
  final VoidCallback onTap;

  /// Below this row width the inline GardenBed thumbnail shrinks so the
  /// entry text isn't squeezed. The 110×90 thumbnail used to dominate
  /// phone-class rows (~360 dp wide) — user feedback v1.0 polish
  /// (2026-05-10): "harvest entries the flowers side is too large in
  /// the mobile viewport".
  static const double _phoneRow = 420;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      onTap: onTap,
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth < _phoneRow;
          final thumbSize = isPhone ? const Size(72, 60) : const Size(110, 90);
          final gap = isPhone ? MoodBloomSpacing.md : MoodBloomSpacing.lg;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GardenBed(
                entries: week.entries,
                tier: week.summary.endingPlantTier,
                size: thumbSize,
                showOverflowBadge: true,
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      week.weekId,
                      style: MbFonts.fraunces(
                        fontSize: isPhone ? 14 : 16,
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
                    const SizedBox(height: 6),
                    _DominantSpeciesCluster(counts: week.summary.moodCounts),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: mb.textDim),
            ],
          );
        },
      ),
    );
  }
}
