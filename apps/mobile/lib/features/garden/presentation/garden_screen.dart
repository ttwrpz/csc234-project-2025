import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/providers.dart';
import '../../harvest/presentation/controllers/weekly_summary_controller.dart';
import '../../harvest/presentation/weekly_summary_screen.dart';
import '../../history/presentation/calendar_view.dart' show DayEntriesSheet;
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../tokens/data/providers.dart';
import '../../tokens/domain/entities/skin_state.dart';
import '../../tokens/domain/services/skin_catalog.dart';
import '../../tokens/presentation/controllers/token_visibility_controller.dart';
import '../../tokens/presentation/widgets/skin_modal_sheet.dart';
import '../../tokens/presentation/widgets/token_balance_chip.dart';
import '../data/providers.dart';
import '../domain/entities/flower_species.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import 'controllers/cheer_up_controller.dart';
import 'widgets/cheer_up_banner.dart';
import 'widgets/daily_score_strip.dart';
import 'widgets/garden_summary_row.dart';
import 'widgets/hotline_footer.dart';
import 'widgets/per_flower_detail_modal.dart';
import 'widgets/sky_header.dart';

/// Home screen — pivot feature #7. ADR-0010 redesign: the canvas now
/// reads two ecosystem signals (slow weekly EWMA → plant tier; fast
/// today-only mean → atmosphere overlay) instead of dispatching one
/// sprite per entry. Below the canvas: the cheer-up banner (when the
/// pattern detector trips), a `DailyScoreStrip` in an `MbCard`, the
/// "Recent moods" preview list, and the hotline footer (only after
/// the 10-day escalation threshold).
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  /// One-shot guard so we only push the [WeeklySummaryScreen] once per
  /// pending-harvest signal. Reset after the user acknowledges the
  /// archive (a fresh harvest a week later flips the provider true
  /// again, but in a new build pass after the route returns).
  bool _harvestRouteScheduled = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gardenStateStreamProvider);
    final intervention = ref.watch(interventionStateProvider);
    final user = ref.watch(currentUserStreamProvider).value;
    final allEntries = ref.watch(myMoodsStreamProvider).value ?? const [];
    // The cheer-up controller owns the banner's session-scoped dismissal
    // and the onShown idempotency guard. We watch the bool field so the
    // banner re-renders when "Not now" is tapped.
    final cheerUp = ref.watch(cheerUpControllerProvider);
    // TC-6 — read the user's per-species selected skins so the live
    // home garden renders the chosen alternate-skin tints. Past
    // archived gardens never receive this (the harvest archive surface
    // passes `null`).
    final skinState =
        ref.watch(skinStateStreamProvider).value ?? SkinState.empty();
    final speciesAccent = _speciesAccentFrom(skinState);

    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    // HB-005 Track 6.1: when the user has crossed a 7-day boundary on
    // an unarchived week AND we have a precomputed summary to show,
    // route them to the WeeklySummaryScreen via a post-frame callback
    // so the route stack stays clean. We do not edit `app/router.dart`
    // (architect-owned) — a `MaterialPageRoute` push is acceptable for
    // v1.0 demo scope. The flag prevents double-pushing across
    // identical rebuilds.
    final pendingSummary = ref.watch(pendingWeeklySummaryProvider);
    if (pendingSummary != null && !_harvestRouteScheduled) {
      _harvestRouteScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Reset the StateNotifier scoped state before each new push so
        // a previous week's success/error from this app session does
        // not carry into a fresh pending harvest.
        ref.read(weeklySummaryControllerProvider.notifier).resetError();
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => WeeklySummaryScreen(
                  summary: pendingSummary.summary,
                  entries: pendingSummary.entries,
                ),
              ),
            )
            .then((_) {
              if (mounted) {
                setState(() {
                  _harvestRouteScheduled = false;
                });
              }
            });
      });
    }

    // Whenever the detector flips to `triggered: true`, dispatch
    // `onShown` exactly once per app launch. The controller itself
    // no-ops on repeat calls via its `onShownDispatched` flag, but we
    // still scope the listen to triggered-true transitions to avoid
    // unnecessary controller hits during steady-state.
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/log-mood'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log mood'),
      ),
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
          greetingName: _firstName(user?.displayName, user?.email),
          bannerDismissed: cheerUp.bannerDismissed,
          onDismissBanner: () =>
              ref.read(cheerUpControllerProvider.notifier).onDismissed(),
          // TC-7: tapping a flower opens the per-entry preview sheet.
          // Routed via the SkyHeader → GardenBed callback chain so this
          // wiring stays inside the home screen's presentation layer
          // (no router changes — architect sign-off rule).
          onFlowerTap: (entry) =>
              PerFlowerDetailModal.show(context, entry),
          // Garden top-bar affordance for the skin modal (HB-008 Day 1
          // TC-8..10 entry point). Placed next to the token chip so the
          // user reads "I have N tokens → tap to spend them" without
          // hunting in Settings.
          onCustomizeSkins: () => SkinModalSheet.show(context),
          speciesAccent: speciesAccent,
        ),
      ),
    );
  }

  static String _firstName(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.split(' ').first;
    }
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'friend';
  }

  /// Builds the per-species accent map for the GardenBed painter from
  /// the user's [SkinState]. Only includes species where (a) the user
  /// has selected a skin AND (b) that skin is an alternate (not the
  /// species default). Default-selected species fall back to the
  /// built-in look — the painter sees them as absent keys.
  ///
  /// Pure function — separated so the unit-test surface for TC-6 can
  /// verify it directly without spinning up a full widget tree.
  static Map<FlowerSpecies, Color> _speciesAccentFrom(SkinState state) {
    const accents = <int, Color>{
      0: Color(0xFFD96E5C),
      1: Color(0xFFE8A23B),
      2: Color(0xFF7CA8D6),
      3: Color(0xFFA493C8),
      4: Color(0xFF5C9A78),
      5: Color(0xFFE6A4B4),
    };
    final out = <FlowerSpecies, Color>{};
    for (final species in FlowerSpecies.values) {
      final selectedId = state.selectedFor(species);
      if (selectedId == null) continue;
      final skin = SkinCatalog.byId(selectedId);
      if (skin == null || skin.isDefault) continue;
      out[species] = accents[skin.paletteSeed % accents.length]!;
    }
    return out;
  }
}

class _GardenView extends StatelessWidget {
  const _GardenView({
    required this.state,
    required this.allEntries,
    required this.intervention,
    required this.greetingName,
    required this.bannerDismissed,
    required this.onDismissBanner,
    required this.onFlowerTap,
    required this.onCustomizeSkins,
    required this.speciesAccent,
  });

  final GardenState state;

  /// Full history (used for the Recent moods preview list). Comes from
  /// the `myMoodsStreamProvider`, which already de-dups offline +
  /// Firestore.
  final List<MoodEntry> allEntries;
  final InterventionState? intervention;
  final String greetingName;
  final bool bannerDismissed;
  final VoidCallback onDismissBanner;

  /// TC-7 — opens the per-flower detail modal. Forwarded to the
  /// SkyHeader → GardenBed callback chain. Stateless so the wiring is
  /// trivial; the modal itself owns its dismiss + route side effects.
  final void Function(MoodEntry entry) onFlowerTap;

  /// TC-8..10 — opens the skin customization modal. Wired to the top-
  /// bar "Customize" icon next to the token chip.
  final VoidCallback onCustomizeSkins;

  /// TC-6 — per-species accent override forwarded to the SkyHeader's
  /// inner [GardenBed]. Empty map when the user has no alternate skin
  /// selected (default rendering, byte-for-byte identical to pre-S5).
  final Map<FlowerSpecies, Color> speciesAccent;

  /// Tablet breakpoint: the canvas + score strip shift into a 60% left
  /// column with the recent-moods list on a 40% right column. Phones
  /// stay single-column.
  static const double _tabletBreakpoint = 720;

  /// Desktop breakpoint: same two-column split as tablet, but clamped
  /// inside a 1100 dp `ConstrainedBox` so the form doesn't sprawl on
  /// 1440 / 1920 dp windows. Page padding bumps from 18 dp to 32 dp.
  /// (Tightened from 1200 in v1.0 polish so the centered home page
  /// reads as a focused content column instead of a wide split with
  /// empty space on either side.)
  static const double _desktopBreakpoint = 1080;

  @override
  Widget build(BuildContext context) {
    final triggered = intervention?.triggered ?? false;
    final escalated = intervention?.escalated ?? false;
    final reason = intervention?.reason ?? 'none';

    // Last 5 entries newest-first for the "Recent moods" preview. Empty
    // list collapses the section so first-time users don't see a stub.
    final recentForPreview = [...allEntries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final preview = recentForPreview.take(5).toList(growable: false);

    // This week's entries (today through 6 days ago) feed the
    // SkyHeader's [GardenBed]. Negative entries (sad/anxious/angry)
    // surface as their species silhouette on the canvas, not just in
    // list tiles.
    final weekCutoff = DateTime.now().subtract(const Duration(days: 7));
    final weekEntries = allEntries
        .where((e) => e.createdAt.isAfter(weekCutoff))
        .toList(growable: false);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
          final isTablet =
              !isDesktop && constraints.maxWidth >= _tabletBreakpoint;
          if (isDesktop || isTablet) {
            return _buildWide(
              context,
              isDesktop: isDesktop,
              triggered: triggered,
              escalated: escalated,
              reason: reason,
              preview: preview,
              weekEntries: weekEntries,
            );
          }
          return _buildNarrow(
            context,
            triggered: triggered,
            escalated: escalated,
            reason: reason,
            preview: preview,
            weekEntries: weekEntries,
          );
        },
      ),
    );
  }

  /// Phone-class layout (< 720 dp). Single-column scrolling list. The
  /// token chip is wired into the SkyHeader's top-right slot, stacked
  /// directly under the entries-this-week pill.
  Widget _buildNarrow(
    BuildContext context, {
    required bool triggered,
    required bool escalated,
    required String reason,
    required List<MoodEntry> preview,
    required List<MoodEntry> weekEntries,
  }) {
    return SingleChildScrollView(
      // Extra bottom padding clears both the bottom nav AND the FAB.
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkyHeader(
            state: state,
            greetingName: greetingName,
            recentEntries: weekEntries,
            onFlowerTap: onFlowerTap,
            speciesAccent: speciesAccent.isEmpty ? null : speciesAccent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: GardenSummaryRow(
              state: state,
              tokenChip: _GardenTokenChip(onCustomize: onCustomizeSkins),
            ),
          ),
          if (triggered && !bannerDismissed)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: CheerUpBanner(reason: reason, onDismiss: onDismissBanner),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: MbCard(
              child: DailyScoreStrip(
                last7Days: state.last7Days,
                onDayTap: (day) => DayEntriesSheet.show(context, day),
              ),
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: MbSectionLabel('RECENT MOODS'),
            ),
            const SizedBox(height: 8),
            for (final e in preview)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: MoodEntryTile(
                  entry: e,
                  onTap: () => context.go('/history/${e.id}'),
                ),
              ),
          ],
          if (escalated)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: HotlineFooter(),
            ),
        ],
      ),
    );
  }

  /// Tablet- / desktop-class layout (≥ 720 dp). Two-column split: the
  /// SkyHeader + DailyScoreStrip + cheer-up banner sit on the left
  /// (60%); recent-moods + hotline footer sit on the right (40%). On
  /// desktop (≥ 1080 dp) the whole block is wrapped in a 1200 dp
  /// `Center`+`ConstrainedBox` and the page padding bumps to 32 dp.
  Widget _buildWide(
    BuildContext context, {
    required bool isDesktop,
    required bool triggered,
    required bool escalated,
    required String reason,
    required List<MoodEntry> preview,
    required List<MoodEntry> weekEntries,
  }) {
    final hPad = isDesktop ? 32.0 : 18.0;
    final maxWidth = isDesktop ? 1100.0 : double.infinity;
    final theme = Theme.of(context);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSky),
          child: SkyHeader(
            state: state,
            greetingName: greetingName,
            recentEntries: weekEntries,
            // Wider canvas on tablet/desktop reads as a hero strip
            // instead of a band — the user reported the right column
            // out-running the left visually because the SkyHeader
            // was anchored at 320dp. 420dp gives the bed more vertical
            // room without crowding out the DailyScoreStrip below.
            height: isDesktop ? 420 : 360,
            onFlowerTap: onFlowerTap,
            speciesAccent: speciesAccent.isEmpty ? null : speciesAccent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GardenSummaryRow(
            state: state,
            tokenChip: _GardenTokenChip(onCustomize: onCustomizeSkins),
          ),
        ),
        if (triggered && !bannerDismissed)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CheerUpBanner(reason: reason, onDismiss: onDismissBanner),
          ),
        if (escalated)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: HotlineFooter(),
          ),
      ],
    );

    // Right column on desktop: this week's mood strip on top, then
    // recent moods below. v1.0 polish (2026-05-10) — moved the strip
    // out of the left column so the desktop layout reads as
    // "garden art on the left, week-at-a-glance + recent entries on
    // the right" instead of stacking three blocks under the SkyHeader.
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: MbCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MoodBloomSpacing.sm,
                vertical: MoodBloomSpacing.sm,
              ),
              child: DailyScoreStrip(
                last7Days: state.last7Days,
                onDayTap: (day) => DayEntriesSheet.show(context, day),
                compact: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (preview.isEmpty)
          MbCard(
            child: Padding(
              padding: const EdgeInsets.all(MoodBloomSpacing.lg),
              child: Text(
                'Your most recent moods will appear here once you log '
                'a few entries.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else ...[
          const MbSectionLabel('RECENT MOODS'),
          const SizedBox(height: 8),
          for (final e in preview)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MoodEntryTile(
                entry: e,
                onTap: () => context.go('/history/${e.id}'),
              ),
            ),
        ],
      ],
    );

    // Top padding scales with breakpoint so the SkyHeader doesn't
    // hug the top of the viewport on desktop. Bottom padding stays
    // generous so the FAB doesn't overlap content. v1.0 polish
    // (2026-05-10) — addressed "content too much at top in desktop"
    // by giving the page a vertical-rhythm anchor instead of starting
    // at y=8 dp.
    final topPad = isDesktop ? 48.0 : 16.0;
    return LayoutBuilder(
      builder: (context, viewport) {
        // Floor the content height to the viewport so the bed +
        // recent moods sit centred when the bottom of the page
        // would otherwise be empty whitespace. We MUST guard against
        // unbounded height (the SCV that wraps us provides infinite
        // maxHeight to its child during intrinsic measurement) —
        // setting `minHeight: infinity` on a BoxConstraints throws
        // and renders a RenderErrorBox, which then explodes on the
        // next hit test. v1.0 polish (2026-05-10) — fixes
        // "Cannot hit test a render box that has never been laid out"
        // crash reported in the user-testing round.
        final viewportH = viewport.hasBoundedHeight ? viewport.maxHeight : 0.0;
        final minH = viewport.hasBoundedHeight
            ? (viewportH - topPad - 140).clamp(0.0, viewportH)
            : 0.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 140),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: left),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: right),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Watches `tokenVisibilityProvider` + `tokenBalanceStreamProvider` and
/// renders a `TokenBalanceChip` only when the user has the toggle on
/// AND a balance is available. Hidden state collapses to a zero-sized
/// box so the SkyHeader's existing top-bar layout is undisturbed.
///
/// HB-008 Day 1 — when a non-null [onCustomize] callback is supplied,
/// pairs the chip with a small "Customize" icon button so the user
/// can open the [SkinModalSheet] without diving into Settings. The
/// button is collapsed when the chip is hidden (so the visibility
/// toggle still suppresses the entire token surface on the home page).
class _GardenTokenChip extends ConsumerWidget {
  const _GardenTokenChip({this.onCustomize});

  /// When non-null, renders an "open skin modal" button next to the
  /// chip. Null preserves the chip-only rendering for any non-home
  /// callers.
  final VoidCallback? onCustomize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(tokenVisibilityProvider);
    if (!visible) return const SizedBox.shrink();
    final balance = ref.watch(tokenBalanceStreamProvider).value;
    if (balance == null) return const SizedBox.shrink();
    final chip = TokenBalanceChip(balance: balance.balance);
    final customize = onCustomize;
    if (customize == null) return chip;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        const SizedBox(width: 6),
        // Compact icon button — 32 dp tap target is below the
        // Material 48 dp minimum so we wrap it in a Semantics + sized
        // SizedBox.expand to bring the effective hit-area up. v1.0
        // polish parity with `_OverflowBadge`'s tiny pill idiom — the
        // home page already has a dense top-right cluster, so the
        // customize affordance opts into the same compact size.
        Semantics(
          label: 'Customize flower skins',
          button: true,
          child: ExcludeSemantics(
            child: SizedBox(
              width: 32,
              height: 32,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: customize,
                  child: Icon(
                    Icons.brush_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
