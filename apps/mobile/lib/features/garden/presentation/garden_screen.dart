import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../harvest/presentation/controllers/weekly_summary_controller.dart';
import '../../harvest/presentation/weekly_summary_screen.dart';
import '../../history/presentation/calendar_view.dart' show DayEntriesSheet;
import '../../history/presentation/entry_detail_screen.dart';
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../data/providers.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import 'controllers/cheer_up_controller.dart';
import 'widgets/cheer_up_banner.dart';
import 'widgets/dominant_emotions_card.dart';
import 'widgets/gentle_nudge_card.dart';
import 'widgets/hotline_footer.dart';
import 'widgets/sky_header.dart';
import 'widgets/take_a_breath_button.dart';
import 'widgets/this_weeks_tier_card.dart';
import 'widgets/today_moods_card.dart';
import 'widgets/weekly_score_card.dart';

/// Home / Garden screen - v1.6 redesign per the Claude Design handoff
/// prototype (`.tmp-handoff/.../screens.jsx > GardenScreen`).
///
/// The page reads as a vertical chapter:
///   1. `SkyHeader` - atmospheric hero with eyebrow + tagline AND a
///      7-day plot strip across its bottom (mood-keyed mini-plants).
///   2. `TakeABreathButton` pill.
///   3. `CheerUpBanner` when the pattern detector trips (Tier 1/2/3).
///   4. `ThisWeeksTierCard` - tier name in serif + token pill.
///   5. `WeeklyScoreCard` - "DAILY SCORE" eyebrow + signed weekly avg +
///      7-bar mini chart + "Mood is weather. The ecosystem holds."
///   6. `TodayMoodsCard` - today's mood chips + log-mood `+` button.
///   7. `DominantEmotionsCard` - top 3 mood chips this week.
///   8. `GentleNudgeCard` - soft AI nudge + medical disclaimer.
///   9. Recent moods card (up to 4 tiles + "See all" link).
///  10. `HotlineFooter` when the user has escalated to Tier 3.
///
/// On tablet/desktop (`>= MbBreakpoints.homeWide`) the page splits
/// into a 60/40 two-column layout: left column = SkyHeader through
/// WeeklyScoreCard; right column = CheerUpBanner through HotlineFooter.
/// Desktop wraps the whole block in a 1100 dp `ConstrainedBox`.
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  /// One-shot guard so we only show the [WeeklySummarySheet] once
  /// per pending-harvest signal. Reset after the user acknowledges
  /// the archive (a fresh harvest a week later flips the provider
  /// true again, but in a new build pass after the route returns).
  bool _harvestRouteScheduled = false;

  /// Session-scoped record of which weekStart the user has already
  /// dismissed. Prevents the popup from re-opening immediately after
  /// the screen pops in the cross-device race window where Firestore
  /// has not yet pushed the canonical archive snapshot to this
  /// device.
  DateTime? _lastDismissedWeekStart;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gardenStateStreamProvider);
    final intervention = ref.watch(interventionStateProvider);
    final allEntries = ref.watch(myMoodsStreamProvider).value ?? const [];
    final cheerUp = ref.watch(cheerUpControllerProvider);

    final mb = Theme.of(context).extension<MbColors>()!;

    final pendingSummary = ref.watch(pendingWeeklySummaryProvider);
    final isAlreadyDismissed =
        pendingSummary != null &&
        _lastDismissedWeekStart != null &&
        pendingSummary.weekStart == _lastDismissedWeekStart;
    if (pendingSummary != null &&
        !_harvestRouteScheduled &&
        !isAlreadyDismissed) {
      _harvestRouteScheduled = true;
      final pushedWeekStart = pendingSummary.weekStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(weeklySummaryControllerProvider.notifier).reset();
        WeeklySummarySheet.show(
          context,
          summary: pendingSummary.summary,
          entries: pendingSummary.entries,
        ).then((_) {
          if (mounted) {
            setState(() {
              _harvestRouteScheduled = false;
              _lastDismissedWeekStart = pushedWeekStart;
            });
          }
        });
      });
    }

    ref.listen<AsyncValue<InterventionState>>(interventionStateProvider, (
      previous,
      next,
    ) {
      final value = next.value;
      if (value == null) return;
      if (!value.triggered) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: value.reason);
      });
    });

    return Scaffold(
      backgroundColor: mb.bg,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.xl),
            child: Text(
              "We couldn't open your home page right now.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (garden) => _GardenView(
          state: garden,
          allEntries: allEntries,
          intervention: intervention.value,
          bannerDismissed: cheerUp.bannerDismissed,
          onDismissBanner: () =>
              ref.read(cheerUpControllerProvider.notifier).onDismissed(),
        ),
      ),
    );
  }
}

class _GardenView extends StatelessWidget {
  const _GardenView({
    required this.state,
    required this.allEntries,
    required this.intervention,
    required this.bannerDismissed,
    required this.onDismissBanner,
  });

  final GardenState state;

  /// Full history (used for the Recent moods preview list). Comes
  /// from the `myMoodsStreamProvider`, which already de-dups offline
  /// + Firestore.
  final List<MoodEntry> allEntries;
  final InterventionState? intervention;
  final bool bannerDismissed;
  final VoidCallback onDismissBanner;

  /// Max recent moods rendered in the preview card.
  static const int _maxRecentRows = 4;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isDesktop = w >= MbBreakpoints.homeDesktop;
          final isWide = w >= MbBreakpoints.homeWide;
          if (isWide) {
            return _buildWide(context, isDesktop: isDesktop);
          }
          return _buildNarrow(context);
        },
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final blocks = _composeBlocks(context, mb: mb, isWide: false);

    return SingleChildScrollView(
      // Extra bottom padding clears both the bottom nav AND the FAB.
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Full-bleed SkyHeader at the top - the atmospheric hero
          // reads edge-to-edge.
          _buildSkyHeader(context, height: 320),
          for (final w in blocks)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoodBloomSpacing.pagePadding,
                14,
                MoodBloomSpacing.pagePadding,
                0,
              ),
              child: w,
            ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, {required bool isDesktop}) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final hPad = isDesktop ? 32.0 : MoodBloomSpacing.pagePadding;
    final maxWidth = isDesktop ? 1100.0 : double.infinity;
    final topPad = isDesktop ? 48.0 : 20.0;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSky),
          child: _buildSkyHeader(context, height: isDesktop ? 420 : 360),
        ),
        const SizedBox(height: 16),
        const TakeABreathButton(expand: true),
        const SizedBox(height: 12),
        ThisWeeksTierCard(tier: state.plantTier),
        const SizedBox(height: 12),
        WeeklyScoreCard(weekEntries: _weekEntries(), weekStart: _weekStart()),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _composeBlocks(context, mb: mb, isWide: true),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 140),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 6, child: left),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: right),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the SkyHeader for either layout. Single source of truth
  /// for the per-week entries + weekStart so wide + narrow stay in sync.
  /// Wires the plot-strip taps: a plant opens its entry; a `+N` pill
  /// opens that day's entries sheet.
  Widget _buildSkyHeader(BuildContext context, {required double height}) {
    return SkyHeader(
      state: state,
      weekEntries: _weekEntries(),
      weekStart: _weekStart(),
      height: height,
      onPlantTap: (entry) => EntryDetailSheet.show(context, entry.id),
      onOverflowTap: (day, _) => DayEntriesSheet.show(context, day),
    );
  }

  /// Composes the page blocks BELOW the SkyHeader. On the narrow
  /// layout these stack directly under the SkyHeader; on the wide
  /// layout they live in the right column (the left column hosts the
  /// SkyHeader + TakeABreath + ThisWeeksTierCard + WeeklyScoreCard).
  List<Widget> _composeBlocks(
    BuildContext context, {
    required MbColors mb,
    required bool isWide,
  }) {
    final triggered = intervention?.triggered ?? false;
    final escalated = intervention?.escalated ?? false;
    final reason = intervention?.reason ?? 'none';
    final weekEntries = _weekEntries();
    final weekStart = _weekStart();
    final today = _todayLocal();
    final todayEntries = _entriesOn(today);

    // Recent moods shows EARLIER days only - today's entries already
    // live in the Today card above, so excluding them here keeps the
    // two cards from duplicating each other.
    final recentForPreview =
        allEntries.where((e) {
          final local = e.createdAt.toLocal();
          final day = DateTime(local.year, local.month, local.day);
          return day != today;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final preview = recentForPreview
        .take(_maxRecentRows)
        .toList(growable: false);

    final out = <Widget>[];

    // Narrow layout includes TakeABreath + ThisWeeksTierCard +
    // WeeklyScoreCard here (in the wide layout they live in the
    // left column).
    if (!isWide) {
      out.add(const TakeABreathButton(expand: true));
      out.add(const SizedBox(height: 12));
      out.add(ThisWeeksTierCard(tier: state.plantTier));
      out.add(const SizedBox(height: 12));
      out.add(WeeklyScoreCard(weekEntries: weekEntries, weekStart: weekStart));
      out.add(const SizedBox(height: 12));
    }

    if (triggered && !bannerDismissed) {
      out.add(CheerUpBanner(reason: reason, onDismiss: onDismissBanner));
      out.add(const SizedBox(height: 12));
    }

    out.add(TodayMoodsCard(todayEntries: todayEntries, today: today));
    out.add(const SizedBox(height: 12));

    out.add(DominantEmotionsCard(weekEntries: weekEntries));
    out.add(const SizedBox(height: 12));

    out.add(GentleNudgeCard(confidence: _nudgeConfidence(state.last7Days)));
    out.add(const SizedBox(height: 16));

    out.add(_buildRecentMoodsCard(context, preview, mb));

    if (escalated) {
      out.add(const SizedBox(height: 16));
      out.add(const HotlineFooter());
    }
    return out;
  }

  Widget _buildRecentMoodsCard(
    BuildContext context,
    List<MoodEntry> preview,
    MbColors mb,
  ) {
    final theme = Theme.of(context);
    return MbCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const MbSectionLabel('RECENT MOODS'),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/history'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See all',
                  style: MbFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Moods from earlier days will appear here.',
                style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              ),
            )
          else
            for (var i = 0; i < preview.length; i++) ...[
              if (i > 0) Divider(height: 1, color: mb.line),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MoodEntryTile(
                  entry: preview[i],
                  onTap: () => EntryDetailSheet.show(context, preview[i].id),
                ),
              ),
            ],
        ],
      ),
    );
  }

  /// Today's week's mood entries (today through 6 days ago). Feeds
  /// both the SkyHeader's plot strip and the WeeklyScoreCard +
  /// DominantEmotionsCard.
  List<MoodEntry> _weekEntries() {
    final start = _weekStart();
    final end = start.add(const Duration(days: 7));
    return allEntries
        .where((e) {
          final local = e.createdAt.toLocal();
          final dayKey = DateTime(local.year, local.month, local.day);
          return !dayKey.isBefore(start) && dayKey.isBefore(end);
        })
        .toList(growable: false);
  }

  /// Entries logged on the given local-midnight day. Used by the
  /// `TodayMoodsCard` body list.
  List<MoodEntry> _entriesOn(DateTime day) {
    return allEntries
        .where((e) {
          final local = e.createdAt.toLocal();
          return local.year == day.year &&
              local.month == day.month &&
              local.day == day.day;
        })
        .toList(growable: false);
  }

  /// Local-midnight of today.
  DateTime _todayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Monday-aligned local-midnight of the current week.
  DateTime _weekStart() => WeeklyScoreCard.mondayOf(DateTime.now());

  /// Confidence shown on the Gentle Nudge card, derived from the
  /// mood-score data density over the last 7 days - how many of those
  /// days actually carry a logged mood score. A nudge read off a
  /// sparsely-logged week is a low-confidence guess; a week with most
  /// days scored earns higher confidence. Mirrors the analytics screen's
  /// day-fill ratio (>=0.7 high, >=0.4 medium) so the badge reads
  /// consistently across surfaces instead of being stuck at "low".
  ///   * 5+ of 7 days scored -> high
  ///   * 3-4 of 7 days scored -> medium
  ///   * 0-2 days scored      -> low
  static MbConfidenceLevel _nudgeConfidence(List<DayScore> last7Days) {
    final scoredDays = last7Days
        .where((d) => d.entryCount > 0 && d.avgScore != null)
        .length;
    if (scoredDays >= 5) return MbConfidenceLevel.high;
    if (scoredDays >= 3) return MbConfidenceLevel.medium;
    return MbConfidenceLevel.low;
  }
}
