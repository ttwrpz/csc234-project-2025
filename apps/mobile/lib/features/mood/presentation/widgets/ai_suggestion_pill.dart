import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../controllers/ai_suggestion_controller.dart';
import '../controllers/log_mood_controller.dart';
import 'mood_kind_adapter.dart';

/// AI suggestion card — debounced result of `analyzeMoodText`. Renders five
/// states:
///
///   - loading        → typing-dots row with "AI reading your note…"
///   - data(null)     → SizedBox.shrink (user hasn't typed enough yet)
///   - data(suggest)  → mood chip + intensity + confidence badge + Accept /
///                       Dismiss pill buttons
///   - data(suggest)  → SizedBox.shrink WHEN safetyFlag == selfHarm
///                       (S3 hides; S4 swaps in compassionate banner)
///   - error          → "Couldn't analyze — pick manually." copy
///
/// Surface is a tinted [MbCard] with `mb.aiBg` background and `mb.aiBd`
/// border, leading 28×28 r8 sparkle avatar (linear primary→amber gradient).
/// Public API (`AISuggestionPill()`) is preserved so the screen call site
/// keeps working unchanged.
class AISuggestionPill extends ConsumerWidget {
  const AISuggestionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSuggestionControllerProvider);

    return state.when(
      loading: () => const _AiCard(child: _LoadingBody()),
      data: (suggestion) {
        if (suggestion == null) return const SizedBox.shrink();
        if (suggestion.safetyFlag == AiSafetyFlag.selfHarm) {
          // S3: hide the pill entirely. S4 will replace this branch with the
          // compassionate banner (no protocol change required — the seam is
          // already in the wire format).
          return const SizedBox.shrink();
        }
        return _AiCard(
          child: _SuggestionBody(
            suggestion: suggestion,
            onAccept: () {
              ref
                  .read(logMoodControllerProvider.notifier)
                  .applyAiSuggestion(suggestion.mood);
              ref.read(aiSuggestionControllerProvider.notifier).clear();
            },
            onDismiss: () =>
                ref.read(aiSuggestionControllerProvider.notifier).clear(),
          ),
        );
      },
      error: (_, _) => const _AiCard(child: _ErrorBody()),
    );
  }
}

/// Tinted [MbCard] shell with the prototype's leading sparkle avatar.
class _AiCard extends StatelessWidget {
  const _AiCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mb.aiBg,
        border: Border.all(color: mb.aiBd),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SparkleAvatar(),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 28×28 r8 gradient avatar with a small white sparkle icon. Same visual as
/// the Insights header on Analytics — kept private here so changing the
/// gradient stays a one-line edit.
class _SparkleAvatar extends StatelessWidget {
  const _SparkleAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6FA587), Color(0xFFE8A23B)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      label: 'Analyzing mood',
      liveRegion: true,
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: mb.textDim),
          ),
          const SizedBox(width: 8),
          Text(
            'AI reading your note…',
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      "Couldn't analyze — pick manually.",
      style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
    );
  }
}

class _SuggestionBody extends StatelessWidget {
  const _SuggestionBody({
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  final AiSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final mbKind = suggestion.mood.mbKind;
    final percent = (suggestion.confidence * 100).round();
    final moodLabel = _moodDisplayName(suggestion.mood.name);
    return Semantics(
      label:
          'AI suggests $moodLabel with $percent percent confidence. '
          'Accept or dismiss.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI suggests',
            style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MbMoodChip(mood: mbKind, size: MbChipSize.sm, label: moodLabel),
              // The intensity is omitted in S3 — the AiSuggestion entity does
              // not carry an intensity field. We surface the confidence band
              // instead, which is what the prototype labels "intensity".
              MbConfidenceBadge(level: _bandFor(suggestion.confidence)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PillButton(label: 'Accept', onPressed: onAccept, primary: true),
              const SizedBox(width: 6),
              _PillButton(
                label: 'Dismiss',
                onPressed: onDismiss,
                primary: false,
              ),
              const Spacer(),
            ],
          ),
          // Tiny rationale line (kept dim so it doesn't compete with the
          // primary action). Trimmed to ~80 chars to keep the card compact.
          if (suggestion.rationale.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _trimRationale(suggestion.rationale),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MbFonts.nunito(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(0x99),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static MbConfidenceLevel _bandFor(double c) {
    if (c < 0.5) return MbConfidenceLevel.low;
    if (c < 0.8) return MbConfidenceLevel.medium;
    return MbConfidenceLevel.high;
  }

  static String _trimRationale(String raw) {
    if (raw.length <= 80) return raw;
    return '${raw.substring(0, 79).trimRight()}…';
  }
}

/// Small pill button used inside the AI suggestion card. Primary = filled
/// brand color; secondary = transparent with a line border.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final bg = primary ? theme.colorScheme.primary : Colors.transparent;
    final fg = primary ? Colors.white : mb.textDim;
    final border = primary ? theme.colorScheme.primary : mb.line;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: MbFonts.nunito(
              fontSize: 11,
              fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

String _moodDisplayName(String name) {
  if (name.isEmpty) return name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}
