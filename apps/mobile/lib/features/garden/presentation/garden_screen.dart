import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/domain/entities/mood_entry.dart';
import '../data/providers.dart';
import '../domain/entities/garden_state.dart';
import '../domain/usecases/compute_garden_state.dart';
import 'widgets/garden_flower.dart';
import 'widgets/rain_cloud.dart';
import 'widgets/streak_header.dart';
import 'widgets/weekly_bloom_bar.dart';
import 'widgets/wilting_plant.dart';

/// Garden screen — pivot feature #7. Renders the user's mood history as
/// a mixed canvas: flowers for positive moods, wilting plants for low-
/// intensity negatives (i 1–3), and rain clouds for high-intensity
/// negatives (i 4–5) per ADR-0006.
///
/// Read-only — this screen is a *consumer* of the mood feed, never a
/// mutator.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  /// Cap on rendered glyphs (combined flowers + wilting + rain) to keep
  /// layout bounded on long histories. Revisit when the canvas becomes a
  /// CustomPaint and density is a designed concern.
  static const int _maxGlyphs = 100;

  /// Cap on simultaneously animating rain clouds. Beyond this, additional
  /// rain-cloud entries render with `animate: false` so the controller
  /// budget stays bounded on mid-range Android (per ADR-0006 §performance).
  static const int _maxAnimatingRainClouds = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gardenStateStreamProvider);
    final entries = ref.watch(gardenEntriesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your garden')),
      body: SafeArea(
        child: state.when(
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
          data: (garden) =>
              _GardenView(state: garden, entries: entries.value ?? const []),
        ),
      ),
    );
  }
}

class _GardenView extends StatelessWidget {
  const _GardenView({required this.state, required this.entries});

  final GardenState state;
  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MoodBloomSpacing.md),
      children: [
        StreakHeader(streakDays: state.currentStreakDays),
        const SizedBox(height: MoodBloomSpacing.lg),
        WeeklyBloomBar(days: state.last7Days),
        const SizedBox(height: MoodBloomSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl),
          child: state.isEmpty
              ? const _GardenEmpty()
              : _GardenCanvas(state: state, entries: entries),
        ),
        const SizedBox(height: MoodBloomSpacing.xxl),
      ],
    );
  }
}

class _GardenCanvas extends StatelessWidget {
  const _GardenCanvas({required this.state, required this.entries});

  final GardenState state;
  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Build the per-entry glyph list, capped at `_maxGlyphs`. Among
    // rain-cloud glyphs the first `_maxAnimatingRainClouds` animate; the
    // rest render statically at full opacity (they will not visually
    // self-clear, but they keep the controller budget bounded).
    final glyphs = <Widget>[];
    var positiveSeen = 0;
    var rainCloudsAnimating = 0;
    for (final entry in entries) {
      if (glyphs.length >= GardenScreen._maxGlyphs) break;
      final kind = ComputeGardenStateUseCase.kind(entry.mood, entry.intensity);
      switch (kind) {
        case DayBloomKind.bloom:
          final color =
              GardenFlower.positivePalette[positiveSeen %
                  GardenFlower.positivePalette.length];
          glyphs.add(GardenFlower(color: color));
          positiveSeen += 1;
        case DayBloomKind.wilting:
          glyphs.add(WiltingPlant(intensity: entry.intensity));
        case DayBloomKind.rainCloud:
          final shouldAnimate =
              rainCloudsAnimating < GardenScreen._maxAnimatingRainClouds;
          glyphs.add(RainCloud(entryId: entry.id, animate: shouldAnimate));
          if (shouldAnimate) rainCloudsAnimating += 1;
        case DayBloomKind.empty:
          // `kind()` does not return `empty` for any logged entry;
          // exhaustive switch sentinel only.
          break;
      }
    }
    final overflow = entries.length - glyphs.length;

    return Semantics(
      label:
          'Garden, ${state.positiveMoodCount} positive moods, '
          '${state.wiltingMoodCount} gentler days, '
          '${state.rainCloudMoodCount} stormy days drifting away',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: MoodBloomSpacing.sm,
            runSpacing: MoodBloomSpacing.sm,
            children: glyphs,
          ),
          if (overflow > 0) ...[
            const SizedBox(height: MoodBloomSpacing.md),
            Text(
              'and $overflow more',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MoodBloomColors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GardenEmpty extends StatelessWidget {
  const _GardenEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoodBloomSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.grass_outlined,
            size: 96,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: MoodBloomSpacing.lg),
          Text(
            'Your garden is waiting.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MoodBloomSpacing.sm),
          Text(
            'Log a positive mood to plant your first bloom.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MoodBloomColors.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
