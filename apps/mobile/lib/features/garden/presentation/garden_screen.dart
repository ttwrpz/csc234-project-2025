import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../domain/entities/garden_state.dart';
import 'widgets/garden_flower.dart';
import 'widgets/streak_header.dart';
import 'widgets/weekly_bloom_bar.dart';

/// Garden screen — pivot feature #7's positive half. Renders the user's
/// positive mood history as flowers, a consecutive-day streak, and a 7-day
/// bloom bar. The compassionate-reframing variants for negative moods
/// (wilting plants for `negativeMild`, rain clouds for `negativeStrong`)
/// land in S4.
///
/// Read-only — this screen is a *consumer* of the mood feed, never a
/// mutator.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  /// Cap on rendered flowers to keep layout bounded on long histories.
  /// Hardcoded for S3; we revisit when the canvas turns into a CustomPaint
  /// and density becomes a designed concern.
  static const int _maxFlowers = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gardenStateStreamProvider);
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
          data: (garden) => _GardenView(state: garden),
        ),
      ),
    );
  }
}

class _GardenView extends StatelessWidget {
  const _GardenView({required this.state});

  final GardenState state;

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
          child: state.isEmpty ? const _GardenEmpty() : _GardenCanvas(state: state),
        ),
        const SizedBox(height: MoodBloomSpacing.xxl),
      ],
    );
  }
}

class _GardenCanvas extends StatelessWidget {
  const _GardenCanvas({required this.state});

  final GardenState state;

  @override
  Widget build(BuildContext context) {
    final flowerCount = state.positiveMoodCount.clamp(
      0,
      GardenScreen._maxFlowers,
    );
    final overflow = state.positiveMoodCount - flowerCount;

    return Semantics(
      label: 'Garden canvas, ${state.positiveMoodCount} positive moods logged',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: MoodBloomSpacing.sm,
            runSpacing: MoodBloomSpacing.sm,
            children: [
              for (var i = 0; i < flowerCount; i += 1)
                GardenFlower(
                  color: GardenFlower.positivePalette[
                      i % GardenFlower.positivePalette.length],
                ),
            ],
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
