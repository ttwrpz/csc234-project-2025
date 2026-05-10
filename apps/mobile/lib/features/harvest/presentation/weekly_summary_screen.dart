import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garden/domain/entities/flower_species.dart';
import '../../garden/domain/entities/plant_tier.dart';
import '../../garden/presentation/widgets/flower_sprite.dart';
import '../../garden/presentation/widgets/plant_tier_group.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../domain/entities/weekly_garden.dart';
import 'controllers/weekly_summary_controller.dart';

/// Pre-harvest summary shown ONCE before each archival commits
/// (HB-005 Track 6.1). The user reviews their week's stats and taps
/// **Continue to new week** to commit the archive and start fresh.
///
/// Locked banner copy (CLAUDE.md §"Pre-approved phrasing"):
/// "Your garden this week has been harvested and saved to your history.
/// A new week begins — a fresh canvas for your story."
///
/// Layout (top → bottom): app-bar "Your week" → hero `PlantTierGroup` →
/// banner copy → average-mood scale → top-3 dominant emotion chips →
/// "Pattern check-ins" line → full-width Continue button.
class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key, required this.summary});

  final WeeklySummary summary;

  /// Locked banner phrasing — verbatim from CLAUDE.md "Pre-approved
  /// intervention phrasing". Test asserts the exact string is rendered.
  static const String harvestBanner =
      'Your garden this week has been harvested and saved to your history. '
      'A new week begins — a fresh canvas for your story.';

  /// Locked CTA label — keeps the screen's only navigation action
  /// stable so widget + golden tests pin to a known string.
  static const String continueLabel = 'Continue to new week';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final status = ref.watch(weeklySummaryControllerProvider);

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: Text(
          'Your week',
          style: MbFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: mb.text,
          ),
        ),
        backgroundColor: mb.bg,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.lg,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(tier: summary.endingPlantTier),
              const SizedBox(height: MoodBloomSpacing.lg),
              _HarvestBanner(text: harvestBanner),
              const SizedBox(height: MoodBloomSpacing.xl),
              _AverageMoodSection(value: summary.averageMoodScore),
              const SizedBox(height: MoodBloomSpacing.xl),
              _DominantEmotionsSection(counts: summary.moodCounts),
              const SizedBox(height: MoodBloomSpacing.xl),
              _PatternCheckInsSection(count: summary.triggeredTierCount),
              const SizedBox(height: MoodBloomSpacing.xl),
              _ContinueButton(status: status),
              if (status is HarvestArchiveError) ...[
                const SizedBox(height: MoodBloomSpacing.md),
                _ErrorRow(message: status.failure.message),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tier});

  final PlantTier tier;

  @override
  Widget build(BuildContext context) {
    return Center(child: PlantTierGroup(tier: tier, entryCount: 0));
  }
}

class _HarvestBanner extends StatelessWidget {
  const _HarvestBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.text),
        ),
      ),
    );
  }
}

class _AverageMoodSection extends StatelessWidget {
  const _AverageMoodSection({required this.value});

  /// Average mood score, range [-1, +1].
  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(-1.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('AVERAGE MOOD'),
        const SizedBox(height: MoodBloomSpacing.md),
        _AverageMoodScale(value: clamped.toDouble()),
      ],
    );
  }
}

class _AverageMoodScale extends StatelessWidget {
  const _AverageMoodScale({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      label:
          'Average mood for the week: ${value.toStringAsFixed(2)} '
          'on a scale from minus one to plus one.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Marker position: map [-1, +1] → [0, width].
              final width = constraints.maxWidth;
              final markerX = ((value + 1.0) / 2.0) * width;
              return SizedBox(
                height: 28,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mb.textDim.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: markerX - 6,
                      top: 6,
                      child: Container(
                        width: 12,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: MoodBloomSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '−1.0',
                style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
              ),
              Text(
                value.toStringAsFixed(2),
                style: MbFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              Text(
                '+1.0',
                style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DominantEmotionsSection extends StatelessWidget {
  const _DominantEmotionsSection({required this.counts});

  final Map<MoodType, int> counts;

  /// Top-3 mood types ordered by count descending. Ties are broken by
  /// the [MoodType] enum index — stable across runs.
  List<MapEntry<MoodType, int>> get _top3 {
    final entries = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.index.compareTo(b.key.index);
      });
    return entries.take(3).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final top = _top3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('DOMINANT EMOTIONS'),
        const SizedBox(height: MoodBloomSpacing.md),
        if (top.isEmpty)
          Text(
            'No emotions logged this week.',
            style: MbFonts.nunito(
              fontSize: 13,
              color: Theme.of(context).extension<MbColors>()!.textDim,
            ),
          )
        else
          Wrap(
            spacing: MoodBloomSpacing.sm,
            runSpacing: MoodBloomSpacing.sm,
            children: [
              for (final entry in top)
                _DominantEmotionChip(mood: entry.key, count: entry.value),
            ],
          ),
      ],
    );
  }
}

/// Mood chip with the per-emotion flower-species sprite leading the
/// label. Replaces the prior `MbMoodChip` so the Sprint 4 polish
/// flower mapping (sunflower / forget-me-not / daisy / poppy / fern /
/// lavender) is visible on the weekly summary screen.
class _DominantEmotionChip extends StatelessWidget {
  const _DominantEmotionChip({required this.mood, required this.count});

  final MoodType mood;
  final int count;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    final color = palette.colorOf(mood.mbKind);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MoodBloomSpacing.md,
        vertical: MoodBloomSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(0x55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowerSprite(
            species: FlowerSpecies.forMood(mood),
            size: 16,
            tint: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${mood.name} · $count',
            style: MbFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCheckInsSection extends StatelessWidget {
  const _PatternCheckInsSection({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final dayWord = count == 1 ? 'day' : 'days';
    final body = count == 0
        ? 'No pattern check-ins this week — the engine stayed quiet.'
        : '$count $dayWord the engine paused with you.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('PATTERN CHECK-INS'),
        const SizedBox(height: MoodBloomSpacing.md),
        Text(
          body,
          style: MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.text),
        ),
      ],
    );
  }
}

class _ContinueButton extends ConsumerWidget {
  const _ContinueButton({required this.status});

  final HarvestArchiveStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = status is HarvestArchiveRunning;
    return MbPrimaryButton(
      label: WeeklySummaryScreen.continueLabel,
      loading: loading,
      onPressed: loading
          ? null
          : () => ref
                .read(weeklySummaryControllerProvider.notifier)
                .acknowledge(),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      message,
      textAlign: TextAlign.center,
      style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
    );
  }
}
