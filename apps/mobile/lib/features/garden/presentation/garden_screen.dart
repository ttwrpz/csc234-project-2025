import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/providers.dart';
import '../../history/presentation/calendar_view.dart' show DayEntriesSheet;
import '../../history/presentation/widgets/mood_entry_tile.dart';
import '../../mood/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../data/providers.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import 'controllers/cheer_up_controller.dart';
import 'widgets/cheer_up_banner.dart';
import 'widgets/hotline_footer.dart';
import 'widgets/sky_header.dart';
import 'widgets/weekly_bloom_bar.dart';

// Removed: `import 'package:go_router/go_router.dart';` once the inline
// CTA went away — the FAB still uses GoRouter so we keep it imported
// where actually used (see below).

/// Home screen — pivot feature #7. Restyled in Phase B to match the
/// "Sprint 2 Prototype": a 320 dp gradient sky header with a soft sun,
/// a CustomPaint ground line, animated flora, drifting rain clouds, and
/// a streak pill. Below the sky we render the cheer-up banner (when the
/// pattern detector trips), the weekly bloom bar in an `MbCard`, the
/// "Log today's mood" CTA, a "Recent moods" preview list, and a hotline
/// footer (only after the 10-day escalation threshold).
///
/// All previous Riverpod watches and behaviour are preserved.
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gardenStateStreamProvider);
    final entriesAsync = ref.watch(gardenEntriesStreamProvider);
    final intervention = ref.watch(interventionStateProvider);
    final user = ref.watch(currentUserStreamProvider).value;
    final allEntries = ref.watch(myMoodsStreamProvider).value ?? const [];
    // The cheer-up controller owns the banner's session-scoped dismissal
    // and the onShown idempotency guard. We watch the bool field so the
    // banner re-renders when "Not now" is tapped.
    final cheerUp = ref.watch(cheerUpControllerProvider);

    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

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
      // Fire after the current frame so the controller's setState
      // doesn't race with the build that triggered this listen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(cheerUpControllerProvider.notifier)
            .onShown(reason: value.reason);
      });
    });

    return Scaffold(
      backgroundColor: mb.bg,
      // FAB: a constantly-visible quick path to logging a new mood from
      // anywhere on Home. Sits above the bottom nav on mobile and above the
      // body on desktop. The label disappears on narrow viewports so it
      // doesn't overlap the centred Add nav button.
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
          entries: entriesAsync.value ?? const [],
          allEntries: allEntries,
          intervention: intervention.value,
          greetingName: _firstName(user?.displayName, user?.email),
          bannerDismissed: cheerUp.bannerDismissed,
          onDismissBanner: () =>
              ref.read(cheerUpControllerProvider.notifier).onDismissed(),
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
}

class _GardenView extends StatelessWidget {
  const _GardenView({
    required this.state,
    required this.entries,
    required this.allEntries,
    required this.intervention,
    required this.greetingName,
    required this.bannerDismissed,
    required this.onDismissBanner,
  });

  final GardenState state;
  final List<MoodEntry> entries;

  /// Full history (used for the Recent moods preview list). Comes from the
  /// `myMoodsStreamProvider`, which already de-dups offline + Firestore.
  final List<MoodEntry> allEntries;
  final InterventionState? intervention;
  final String greetingName;
  final bool bannerDismissed;
  final VoidCallback onDismissBanner;

  /// Recency window for sky scene: last 7 days. Older entries still
  /// count toward streaks and the bloom bar (those use the use case)
  /// but they don't render as flora — the scene is a "now" view.
  static const Duration _sceneWindow = Duration(days: 7);

  @override
  Widget build(BuildContext context) {
    final triggered = intervention?.triggered ?? false;
    final escalated = intervention?.escalated ?? false;
    final reason = intervention?.reason ?? 'none';

    final now = DateTime.now();
    final recent = [
      for (final e in entries)
        if (now.difference(e.createdAt) <= _sceneWindow) e,
    ];

    // Last 5 entries newest-first for the "Recent moods" preview. Empty
    // list collapses the section so first-time users don't see a stub.
    final recentForPreview = [...allEntries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final preview = recentForPreview.take(5).toList(growable: false);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        // Extra bottom padding clears both the bottom nav AND the FAB.
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkyHeader(
              entries: recent,
              streakDays: state.currentStreakDays,
              greetingName: greetingName,
            ),
            if (triggered && !bannerDismissed)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: CheerUpBanner(
                  reason: reason,
                  onDismiss: onDismissBanner,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: MbCard(
                child: WeeklyBloomBar(
                  days: state.last7Days,
                  // Tap a bar → bottom-sheet listing every entry on that day.
                  // Reuses the calendar's DayEntriesSheet so the UX is the
                  // same in both surfaces.
                  onDayTap: (day) => DayEntriesSheet.show(context, day),
                ),
              ),
            ),
            // The inline "Log today's mood" button used to live here. It
            // was removed once the centred bottom-nav slot + the home-page
            // FAB both became permanent visible CTAs — three buttons doing
            // the same thing on one page is just clutter.
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
      ),
    );
  }
}
