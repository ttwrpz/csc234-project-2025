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
/// `analyzePatterns` (Cloud Function) and renders 0..3 rows, each with a
/// confidence chip + sample-size badge.
///
/// The header row carries a sparkle avatar (linear primary→amber
/// gradient) + "Insights" title + "AI-assisted" caption, and each insight
/// row is separated by a 1 px [MbColors.line] divider.
///
/// Hides itself entirely when `ai_pattern_analysis_enabled` Remote Config
/// is false — both as defence in depth and to power the demo kill-switch
/// rehearsal.
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
      error: (_, _) =>
          _ErrorCard(onRetry: () => ref.invalidate(myMoodsStreamProvider)),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyCard();
        }
        final insightsAsync = ref.watch(_patternInsightsProvider(entries));
        return insightsAsync.when(
          loading: () => const _LoadingCard(),
          error: (_, _) => _ErrorCard(
            onRetry: () => ref.invalidate(_patternInsightsProvider(entries)),
          ),
          data: (result) => switch (result) {
            Ok(value: final list) when list.isEmpty => const _EmptyCard(),
            Ok(value: final list) => _DataCard(insights: list),
            Err() => _ErrorCard(
              onRetry: () => ref.invalidate(_patternInsightsProvider(entries)),
            ),
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

/// Hero header bar — larger sparkle badge, brand-gradient backdrop, and
/// a Fraunces "AI Insight" title that distinguishes this personalised
/// card from the static "View detailed insights" link below it on the
/// Patterns screen.
class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6FA587), Color(0xFFE8A23B)],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33E8A23B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Insight',
                style: MbFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              Text(
                'Patterns your garden has noticed lately',
                style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A23B).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFE8A23B).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            'AI',
            style: MbFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF8A5A1F),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const _CardShell(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                "We couldn't read your patterns just now.",
                style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'Keep tending your garden - patterns bloom here as the days '
          'fill in.',
          style: MbFonts.nunito(fontSize: 13, height: 1.4, color: mb.textDim),
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
    // Cap at 3 — anything more crowds the dashboard.
    final visible = insights.take(3).toList();
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 10),
              const _RowDivider(),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 10),
            _InsightRow(insight: visible[i]),
          ],
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Container(height: 1, color: mb.line);
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Soft brand-gradient backdrop (mint → amber wash, low alpha) so
    // the AI Insight card reads as a premium / personalised surface
    // distinct from the plain MbCard "View detailed insights" link
    // below it. Alpha drops in dark mode to keep contrast against
    // navy without washing the text into mud.
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x336FA587), Color(0x33E8A23B)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1F6FA587), Color(0x1FE8A23B)],
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        border: Border.all(
          color: const Color(0xFFE8A23B).withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const _InsightsHeader(), child],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});
  final PatternInsight insight;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight.text,
          style: MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.text),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            MbConfidenceBadge(level: _bandFor(insight.confidence)),
            const SizedBox(width: 8),
            Text(
              '${insight.sampleSize} samples',
              style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
            ),
          ],
        ),
      ],
    );
  }

  static MbConfidenceLevel _bandFor(double c) {
    if (c < 0.5) return MbConfidenceLevel.low;
    if (c < 0.8) return MbConfidenceLevel.medium;
    return MbConfidenceLevel.high;
  }
}
