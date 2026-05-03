import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/providers.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../data/providers.dart';
import '../domain/entities/garden_state.dart';
import '../domain/entities/intervention_state.dart';
import 'widgets/cheer_up_banner.dart';
import 'widgets/hotline_footer.dart';
import 'widgets/sky_header.dart';
import 'widgets/weekly_bloom_bar.dart';

/// Garden screen — pivot feature #7. Restyled in Phase B to match the
/// "Sprint 2 Prototype": a 320 dp gradient sky header with a soft sun,
/// a CustomPaint ground line, animated flora, drifting rain clouds, and
/// a streak pill. Below the sky we render the cheer-up banner (when the
/// pattern detector trips), the weekly bloom bar in an `MbCard`, the
/// "Log today's mood" CTA, and a hotline footer (only after the 10-day
/// escalation threshold).
///
/// All previous Riverpod watches and behaviour are preserved — this
/// file is a presentation-layer redesign, not a logic change.
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  /// Session-scoped flag the cheer-up banner toggles when the user taps
  /// "Not now". The pattern detector continues to report `triggered:
  /// true` (cooldown writes are a Sprint-5 storage concern), so we hide
  /// the banner locally for the rest of this app launch.
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gardenStateStreamProvider);
    final entriesAsync = ref.watch(gardenEntriesStreamProvider);
    final intervention = ref.watch(interventionStateProvider);
    final user = ref.watch(currentUserStreamProvider).value;
    final mb = Theme.of(context).extension<MbColors>()!;

    return Scaffold(
      backgroundColor: mb.bg,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.xl),
            child: Text(
              "We couldn't open your garden right now.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (garden) => _GardenView(
          state: garden,
          entries: entriesAsync.value ?? const [],
          intervention: intervention.value,
          greetingName: _firstName(user?.displayName, user?.email),
          bannerDismissed: _bannerDismissed,
          onDismissBanner: () => setState(() => _bannerDismissed = true),
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
    required this.intervention,
    required this.greetingName,
    required this.bannerDismissed,
    required this.onDismissBanner,
  });

  final GardenState state;
  final List<MoodEntry> entries;
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

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
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
              child: MbCard(child: WeeklyBloomBar(days: state.last7Days)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: MbPrimaryButton(
                label: "Log today's mood",
                leading: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => context.go('/log-mood'),
              ),
            ),
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
