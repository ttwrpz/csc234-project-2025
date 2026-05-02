import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../mood/data/providers.dart';
import '../../../mood/domain/ai_analysis_failure.dart';
import '../../../mood/domain/entities/mood_entry.dart';
import '../../domain/entities/pattern_insight.dart';

/// Pattern insights card slotted onto the analytics dashboard. Reads from
/// `analyzePatterns` (Cloud Function) and renders 0..N rows, each with a
/// confidence chip + sample-size badge per ADR-0007.
///
/// Hides itself entirely when `ai_pattern_analysis_enabled` Remote Config
/// is false — both as defence in depth and to power the demo kill-switch
/// rehearsal (per kickoff Open Question O-3).
class PatternInsightCard extends ConsumerWidget {
  const PatternInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Server-side feature flag check. The widget self-hides when off,
    // and the slot in `analytics_screen.dart` ALSO short-circuits at
    // the insertion site — both layers are intentional.
    final flagOn = ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled;
    if (!flagOn) return const SizedBox.shrink();

    final asyncEntries = ref.watch(myMoodsStreamProvider);
    return asyncEntries.when(
      loading: () => const _LoadingCard(),
      error: (_, _) => const _ErrorCard(),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyCard();
        }
        final insightsAsync = ref.watch(_patternInsightsProvider(entries));
        return insightsAsync.when(
          loading: () => const _LoadingCard(),
          error: (_, _) => const _ErrorCard(),
          data: (result) => switch (result) {
            Ok(value: final list) when list.isEmpty => const _EmptyCard(),
            Ok(value: final list) => _DataCard(insights: list),
            Err() => const _ErrorCard(),
          },
        );
      },
    );
  }
}

/// FutureProvider keyed on the current entries list. The current list is the
/// natural input — there is no `MoodWindow` parameter here because the card
/// runs over the full history (the server applies its own window).
final _patternInsightsProvider =
    FutureProvider.family<
      Result<List<PatternInsight>, AiAnalysisFailure>,
      List<MoodEntry>
    >((ref, entries) async {
      final repo = ref.watch(aiAnalysisRepositoryProvider);
      return repo.analyzePatterns(history: entries);
    });

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const _CardShell(
    child: SizedBox(
      height: 64,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.md),
        child: Text(
          "We couldn't read your patterns just now.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.md),
        child: Text(
          'Log a few more moods to see patterns.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.insights});
  final List<PatternInsight> insights;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(MoodBloomSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patterns we noticed',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: MoodBloomSpacing.sm),
            for (final insight in insights) ...[
              const SizedBox(height: MoodBloomSpacing.sm),
              _InsightRow(insight: insight),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: MoodBloomSpacing.sm),
      child: child,
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});
  final PatternInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(insight.text, style: theme.textTheme.bodyMedium),
        const SizedBox(height: MoodBloomSpacing.xs),
        Row(
          children: [
            _ConfidenceChip(confidence: insight.confidence),
            const SizedBox(width: MoodBloomSpacing.sm),
            Text(
              '${insight.sampleSize} samples',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final band = _band(confidence);
    return switch (band) {
      _Band.low => Chip(
        label: Text('low', style: TextStyle(color: MoodBloomColors.warning)),
        side: BorderSide(color: MoodBloomColors.warning),
        backgroundColor: Colors.transparent,
        visualDensity: VisualDensity.compact,
      ),
      _Band.mid => Chip(
        label: const Text('medium'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
      _Band.high => Chip(
        label: Text(
          'high',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        visualDensity: VisualDensity.compact,
      ),
    };
  }

  static _Band _band(double c) {
    if (c < 0.5) return _Band.low;
    if (c < 0.8) return _Band.mid;
    return _Band.high;
  }
}

enum _Band { low, mid, high }
