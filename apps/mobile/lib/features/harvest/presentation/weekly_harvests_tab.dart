import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garden/data/providers.dart';
import '../../garden/domain/entities/plant_tier.dart';
import '../../garden/presentation/widgets/sky_plot_strip.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/domain/services/mood_score.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../data/providers.dart';
import '../domain/entities/weekly_garden.dart';
import 'archived_week_screen.dart';

/// History tab listing the user's weeks newest-first, per
/// `HistoryHarvestScreen` in `prototype/screens-extra.jsx`.
///
/// The CURRENT week is shown first as an "IN PROGRESS" card built from
/// live data (this week's entries + the garden's current tier). Past
/// (archived) weeks follow as read-only "locked" cards. Each card shows
/// a mini garden snapshot, range eyebrow, week label + tier headline,
/// an Avg / Entries / Brightest stat row, and the dominant-mood chips.
///
/// Empty state: "Your first week is still growing." — approved
/// vocabulary. Tapping a locked week opens [ArchivedWeekScreen].
class WeeklyHarvestsTab extends ConsumerWidget {
  const WeeklyHarvestsTab({super.key});

  /// Two-column harvest grid unlocks at this width.
  static const double _twoColBreakpoint = 900;

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
        // Build the live in-progress card from this week's entries.
        final allEntries =
            ref.watch(myMoodsStreamProvider).value ?? const <MoodEntry>[];
        final tier =
            ref.watch(gardenStateStreamProvider).value?.plantTier ??
            PlantTier.resting;
        final inProgress = _inProgressVm(allEntries, tier);

        // Archived weeks → locked view models.
        final archived = weeks.map(_archivedVm).toList(growable: false);

        if (inProgress == null && archived.isEmpty) {
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

        final cards = <_HarvestVm>[?inProgress, ...archived];
        // weekId of each archived week, parallel to the archived portion
        // of `cards`, so the grid can wire the open-week tap.
        final archivedWeeks = weeks;

        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= _twoColBreakpoint;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                0,
                MoodBloomSpacing.sm,
                0,
                MoodBloomSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntroBlurb(color: mb.textDim),
                  const SizedBox(height: MoodBloomSpacing.lg),
                  _HarvestGrid(
                    cards: cards,
                    archivedWeeks: archivedWeeks,
                    hasInProgress: inProgress != null,
                    twoCol: twoCol,
                  ),
                  const SizedBox(height: MoodBloomSpacing.md),
                  Text(
                    'Harvests are read-only after the week closes.',
                    style: MbFonts.nunito(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: mb.textDim,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the in-progress view model from this week's live entries.
  /// Returns null when the user has logged nothing this week (no card).
  static _HarvestVm? _inProgressVm(List<MoodEntry> all, PlantTier tier) {
    final monday = _mondayOf(DateTime.now());
    final end = monday.add(const Duration(days: 7));
    final entries = all.where((e) {
      final local = e.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      return !day.isBefore(monday) && day.isBefore(end);
    }).toList(growable: false);
    if (entries.isEmpty) return null;
    return _HarvestVm(
      rangeLabel: _rangeLabel(monday, end),
      weekLabel: 'This week',
      tier: tier,
      entries: entries,
      weekStart: monday,
      avg: _avgScore(entries),
      entryCount: entries.length,
      brightestLabel: _brightestDay(entries),
      moodCounts: _moodCounts(entries),
      inProgress: true,
    );
  }

  static _HarvestVm _archivedVm(WeeklyGarden week) {
    return _HarvestVm(
      rangeLabel: _rangeLabel(week.weekStart, week.weekEnd),
      weekLabel: _weekLabel(week.weekStart),
      tier: week.summary.endingPlantTier,
      entries: week.entries,
      weekStart: week.weekStart,
      avg: week.summary.averageMoodScore,
      entryCount: week.summary.totalEntryCount,
      brightestLabel: _brightestDay(week.entries),
      moodCounts: week.summary.moodCounts,
      inProgress: false,
    );
  }

  // ---- pure helpers --------------------------------------------------

  static DateTime _mondayOf(DateTime now) {
    final local = now.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    return midnight.subtract(Duration(days: midnight.weekday - DateTime.monday));
  }

  /// "This week" / "Last week" / "N weeks ago" from the week's Monday.
  static String _weekLabel(DateTime weekStart) {
    final thisMonday = _mondayOf(DateTime.now());
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weeks = thisMonday.difference(start).inDays ~/ 7;
    if (weeks <= 0) return 'This week';
    if (weeks == 1) return 'Last week';
    return '$weeks weeks ago';
  }

  /// "Apr 22 - Apr 28" from a [start] Monday and an exclusive [end].
  static String _rangeLabel(DateTime start, DateTime end) {
    final last = end.subtract(const Duration(days: 1));
    final m1 = _month(start.month);
    final m2 = _month(last.month);
    if (m1 == m2) return '$m1 ${start.day} - ${last.day}';
    return '$m1 ${start.day} - $m2 ${last.day}';
  }

  /// Weekday abbreviation of the highest mean-score day, or "-" when the
  /// week has no entries.
  static String _brightestDay(List<MoodEntry> entries) {
    if (entries.isEmpty) return '-';
    final sums = <DateTime, double>{};
    final counts = <DateTime, int>{};
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      sums[day] = (sums[day] ?? 0) + computeMoodScore(e.mood, e.intensity).value;
      counts[day] = (counts[day] ?? 0) + 1;
    }
    DateTime? best;
    var bestMean = double.negativeInfinity;
    sums.forEach((day, sum) {
      final mean = sum / counts[day]!;
      if (mean > bestMean) {
        bestMean = mean;
        best = day;
      }
    });
    return best == null ? '-' : _weekday(best!.weekday);
  }

  static double _avgScore(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    var sum = 0.0;
    for (final e in entries) {
      sum += computeMoodScore(e.mood, e.intensity).value;
    }
    return sum / entries.length;
  }

  static Map<MoodType, int> _moodCounts(List<MoodEntry> entries) {
    final out = <MoodType, int>{};
    for (final e in entries) {
      out[e.mood] = (out[e.mood] ?? 0) + 1;
    }
    return out;
  }

  static const _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _month(int m) => _months[(m - 1).clamp(0, 11)];

  static const _weekdays = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static String _weekday(int w) => _weekdays[(w - 1).clamp(0, 6)];
}

/// View model backing a single harvest card — shared by the live
/// in-progress card and the archived (locked) cards.
class _HarvestVm {
  const _HarvestVm({
    required this.rangeLabel,
    required this.weekLabel,
    required this.tier,
    required this.entries,
    required this.weekStart,
    required this.avg,
    required this.entryCount,
    required this.brightestLabel,
    required this.moodCounts,
    required this.inProgress,
  });

  final String rangeLabel;
  final String weekLabel;
  final PlantTier tier;
  final List<MoodEntry> entries;
  final DateTime weekStart;
  final double avg;
  final int entryCount;
  final String brightestLabel;
  final Map<MoodType, int> moodCounts;
  final bool inProgress;
}

String _tierName(PlantTier tier) => switch (tier) {
  PlantTier.flourishing => 'Flourishing',
  PlantTier.thriving => 'Thriving',
  PlantTier.resting => 'Resting',
  PlantTier.weathering => 'Weathering',
  PlantTier.stormSeason => 'Storm Season',
};

/// One-line intro blurb above the harvest grid, per the prototype.
class _IntroBlurb extends StatelessWidget {
  const _IntroBlurb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Every Sunday evening, your garden is harvested into the record. '
      'Past weeks live here as small snapshots - the weather, the plants, '
      'the headline.',
      style: MbFonts.nunito(fontSize: 13, height: 1.55, color: color),
    );
  }
}

/// Responsive grid wrapper — one column on phone widths, two columns on
/// tablet+ widths. Only archived (locked) cards are tappable; the live
/// in-progress card (always index 0 when present) has no archive to open.
class _HarvestGrid extends StatelessWidget {
  const _HarvestGrid({
    required this.cards,
    required this.archivedWeeks,
    required this.hasInProgress,
    required this.twoCol,
  });

  final List<_HarvestVm> cards;
  final List<WeeklyGarden> archivedWeeks;
  final bool hasInProgress;
  final bool twoCol;

  /// Resolves the archived [WeeklyGarden] for a card index, or null for
  /// the in-progress card.
  WeeklyGarden? _weekFor(int cardIndex) {
    final archivedIndex = hasInProgress ? cardIndex - 1 : cardIndex;
    if (archivedIndex < 0 || archivedIndex >= archivedWeeks.length) return null;
    return archivedWeeks[archivedIndex];
  }

  VoidCallback? _tapFor(BuildContext context, int cardIndex) {
    final week = _weekFor(cardIndex);
    if (week == null) return null;
    return () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArchivedWeekScreen(week: week)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!twoCol) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            _HarvestCard(vm: cards[i], onTap: _tapFor(context, i)),
            if (i != cards.length - 1)
              const SizedBox(height: MoodBloomSpacing.md),
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final hasRight = i + 1 < cards.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _HarvestCard(vm: cards[i], onTap: _tapFor(context, i)),
              ),
              const SizedBox(width: MoodBloomSpacing.md),
              Expanded(
                child: hasRight
                    ? _HarvestCard(
                        vm: cards[i + 1],
                        onTap: _tapFor(context, i + 1),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < cards.length) {
        rows.add(const SizedBox(height: MoodBloomSpacing.md));
      }
    }
    return Column(children: rows);
  }
}

class _HarvestCard extends StatelessWidget {
  const _HarvestCard({required this.vm, this.onTap});

  final _HarvestVm vm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mini garden snapshot — per-tier sky + ground + the SAME
          // mini-plant strip the home SkyHeader uses (one cluster per
          // day, no labels), so the harvest garden reads consistently
          // with the live home garden.
          _HarvestMiniGarden(
            entries: vm.entries,
            weekStart: vm.weekStart,
            tier: vm.tier,
            mb: mb,
          ),
          Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Range eyebrow + IN PROGRESS pill (current) or lock
                // badge (past), then the week-label + tier headline.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: MbSectionLabel(vm.rangeLabel)),
                              if (vm.inProgress) ...[
                                const SizedBox(width: 8),
                                const _InProgressBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vm.weekLabel} · ${_tierName(vm.tier)}',
                            style: MbFonts.fraunces(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: mb.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!vm.inProgress) ...[
                      const SizedBox(width: 8),
                      const MbLockBadge(small: true),
                    ],
                  ],
                ),
                const SizedBox(height: MoodBloomSpacing.sm),
                _StatRow(vm: vm),
                const SizedBox(height: MoodBloomSpacing.sm),
                _DominantMoodChips(counts: vm.moodCounts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact garden snapshot for a harvest card: per-tier sky gradient +
/// a two-tone ground band + the home garden's [SkyPlotStrip] (one
/// mood-keyed plant cluster per day, day labels hidden). Fixes the
/// missing background visual and keeps the flower model identical to
/// the home screen.
class _HarvestMiniGarden extends StatelessWidget {
  const _HarvestMiniGarden({
    required this.entries,
    required this.weekStart,
    required this.tier,
    required this.mb,
  });

  final List<MoodEntry> entries;
  final DateTime weekStart;
  final PlantTier tier;
  final MbColors mb;

  /// Per-tier sky gradient stops, ported from the prototype's
  /// `MiniHarvestGarden > TIER_BG`. Storm reads as a muted slate, never
  /// an alarming charcoal (CLAUDE.md "sheltered, never threatened").
  static List<Color> _skyFor(PlantTier tier) => switch (tier) {
    PlantTier.flourishing => const [
      Color(0xFFFFE0BA),
      Color(0xFFFFEAD0),
      Color(0xFFDDEFD8),
    ],
    PlantTier.thriving => const [
      Color(0xFFFFE4D1),
      Color(0xFFF5E9DA),
      Color(0xFFE8F3ED),
    ],
    PlantTier.resting => const [
      Color(0xFFF4DCC4),
      Color(0xFFECDFD0),
      Color(0xFFDAE2CE),
    ],
    PlantTier.weathering => const [
      Color(0xFFC8C9BC),
      Color(0xFFC2C7BA),
      Color(0xFFB8C5B0),
    ],
    PlantTier.stormSeason => const [
      Color(0xFF6E7C8B),
      Color(0xFF61707F),
      Color(0xFF4C606A),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isStorm = tier == PlantTier.stormSeason;
    final groundFront = isStorm ? const Color(0xFF2E4538) : mb.ground2;
    final groundBack = isStorm ? const Color(0xFF3D5040) : mb.ground;
    final labelTint = isStorm ? Colors.white : mb.text;
    return SizedBox(
      height: 130,
      child: ClipRect(
        child: Stack(
          children: [
            // Sky.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.55, 1],
                    colors: _skyFor(tier),
                  ),
                ),
              ),
            ),
            // Two-tone ground band.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: DecoratedBox(decoration: BoxDecoration(color: groundBack)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(color: groundFront),
              ),
            ),
            // Plants — same model + bucketing as the home strip.
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: SkyPlotStrip(
                weekEntries: entries,
                weekStart: weekStart,
                tier: tier,
                compact: true,
                showDayLabels: false,
                labelColor: labelTint,
                darkOverlay: isStorm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft-green "IN PROGRESS" pill shown on the live current-week card.
class _InProgressBadge extends StatelessWidget {
  const _InProgressBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: MoodBloomColors.softGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'IN PROGRESS',
        style: MbFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: MoodBloomColors.seedDark,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.vm});

  final _HarvestVm vm;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final avgLabel = '${vm.avg >= 0 ? "+" : ""}${vm.avg.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.only(top: MoodBloomSpacing.sm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: mb.line)),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'AVG',
            value: avgLabel,
            accent: vm.avg >= 0 ? MoodBloomColors.seed : MoodBloomColors.moodSad,
          ),
          const SizedBox(width: MoodBloomSpacing.lg),
          _Stat(label: 'ENTRIES', value: '${vm.entryCount}'),
          const SizedBox(width: MoodBloomSpacing.lg),
          _Stat(label: 'BRIGHTEST', value: vm.brightestLabel),
        ],
      ),
    );
  }
}

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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: accent ?? mb.text,
          ),
        ),
      ],
    );
  }
}

/// Row of mood chips representing the dominant moods of the week.
class _DominantMoodChips extends StatelessWidget {
  const _DominantMoodChips({required this.counts});

  final Map<MoodType, int> counts;

  static const int _maxChips = 3;

  List<MapEntry<MoodType, int>> get _topMoods {
    final entries = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.index.compareTo(b.key.index);
      });
    return entries.take(_maxChips).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final top = _topMoods;
    if (top.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in top)
          MbMoodChip(mood: entry.key.mbKind, size: MbChipSize.sm),
      ],
    );
  }
}
