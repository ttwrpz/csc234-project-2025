import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garden/domain/entities/flower_species.dart';
import '../../garden/domain/entities/plant_tier.dart';
import '../../garden/presentation/widgets/flower_sprite.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';
import '../../mood/presentation/widgets/mood_kind_adapter.dart';
import '../domain/entities/weekly_garden.dart';
import 'controllers/weekly_summary_controller.dart';
import 'widgets/harvest_mini_garden.dart';

/// Pre-harvest summary shown ONCE before each archival commits, now
/// presented as a modal (bottom sheet on phone, dialog on tablet+) per
/// the v1.6 prototype's `ModalFrame`. The user reviews their week's
/// stats and taps **Continue to new week** to commit the archive.
///
/// Locked banner copy (CLAUDE.md §"Pre-approved phrasing"):
/// "Your garden this week has been harvested and saved to your history.
/// A new week begins — a fresh canvas for your story."
///
/// Layout (top → bottom): "Your week" modal header → hero `GardenBed` →
/// banner copy → average-mood scale → top-3 dominant emotion chips →
/// "Pattern check-ins" line → full-width Continue button.
class WeeklySummarySheet {
  const WeeklySummarySheet._();

  /// Locked banner phrasing — verbatim from CLAUDE.md "Pre-approved
  /// intervention phrasing". Test asserts the exact string is rendered.
  static const String harvestBanner =
      'Your garden this week has been harvested and saved to your history. '
      'A new week begins - a fresh canvas for your story.';

  /// Locked CTA label — keeps the screen's only navigation action
  /// stable so widget + golden tests pin to a known string.
  static const String continueLabel = 'Continue to new week';

  /// Presents the harvest summary as a modal. Resolves when the modal
  /// is dismissed (either after the archive commits + auto-pop, or via
  /// the header close icon). [isDismissible] is false so a stray
  /// barrier tap doesn't skip the archive review.
  static Future<void> show(
    BuildContext context, {
    required WeeklySummary summary,
    List<MoodEntry> entries = const <MoodEntry>[],
  }) {
    return MbModalSheet.show<void>(
      context,
      isDismissible: false,
      builder: (_) => WeeklySummaryView(summary: summary, entries: entries),
    );
  }
}

/// Modal body for the weekly harvest summary. Hosts the archive
/// controller listen → auto-pop and renders the section stack inside
/// an [MbModalScaffold].
class WeeklySummaryView extends ConsumerWidget {
  const WeeklySummaryView({
    super.key,
    required this.summary,
    this.entries = const <MoodEntry>[],
  });

  final WeeklySummary summary;

  /// The week's entries — drives the hero [GardenBed] so the user sees
  /// real plants for the moods they logged this week, not generic
  /// stylized buds. Empty list collapses the hero to a small archive
  /// marker so the screen still mounts on edge-case test rigs.
  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(weeklySummaryControllerProvider);

    // Pop the modal as soon as the archive write resolves. The
    // controller doesn't navigate itself — it only flips state — so the
    // Continue button used to leave the user stuck on a "Running…" CTA
    // even though the archive landed cleanly. Listening once at the
    // build level routes every success path (manual tap, debug force,
    // double-tap idempotency) through the same `pop`.
    ref.listen<HarvestArchiveStatus>(weeklySummaryControllerProvider, (
      prev,
      next,
    ) {
      // Pop on Success AND on AlreadyDone (cross-device race outcome).
      // Both represent "the archive exists" from the user's POV; only
      // the local write path differs.
      if (next is HarvestArchiveSuccess || next is HarvestArchiveAlreadyDone) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return MbModalScaffold(
      title: 'Your week',
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: MoodBloomSpacing.sm),
          _Hero(tier: summary.endingPlantTier, entries: entries),
          const SizedBox(height: MoodBloomSpacing.lg),
          _HarvestBanner(text: WeeklySummarySheet.harvestBanner),
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
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tier, required this.entries});

  final PlantTier tier;
  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Same mini-garden as the harvest cards + detail screen + home, so
    // the whole harvest flow renders one consistent garden. weekStart is
    // derived from the entries (this is the week being archived).
    return ClipRRect(
      borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
      child: HarvestMiniGarden(entries: entries, tier: tier, height: 140),
    );
  }
}

class _HarvestBanner extends StatelessWidget {
  const _HarvestBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    // Prototype's harvest banner uses the AI-tint card style — `aiBg`
    // background + `aiBd` border + body Nunito 14 line-height 1.55.
    // The string itself is the locked
    // [WeeklySummarySheet.harvestBanner]; we only refresh the
    // surrounding card treatment.
    return MbCard(
      decoration: BoxDecoration(
        color: mb.aiBg,
        border: Border.all(color: mb.aiBd),
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
      ),
      padding: const EdgeInsets.all(MoodBloomSpacing.lg),
      child: Text(
        text,
        style: MbFonts.nunito(fontSize: 14, height: 1.55, color: mb.text),
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
/// label. Uses the flower-species mapping (sunflower / forget-me-not /
/// daisy / poppy / fern / lavender) on the weekly summary screen.
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
        ? 'No pattern check-ins this week - the engine stayed quiet.'
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
    // Disable the CTA on every terminal status. Without this guard the
    // button stays tappable after AlreadyDone or Success, and a re-tap
    // no-ops silently via the controller's early-return guard - the
    // user would perceive a frozen button.
    final terminal =
        status is HarvestArchiveSuccess || status is HarvestArchiveAlreadyDone;
    return MbPrimaryButton(
      label: WeeklySummarySheet.continueLabel,
      loading: loading,
      onPressed: (loading || terminal)
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
