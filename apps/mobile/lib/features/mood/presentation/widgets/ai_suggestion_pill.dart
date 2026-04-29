import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../controllers/ai_suggestion_controller.dart';
import '../controllers/log_mood_controller.dart';

/// AI suggestion pill — debounced result of `analyzeMoodText`. Renders five
/// states:
///
///   - loading        → tonal placeholder + Semantics live region
///   - data(null)     → SizedBox.shrink (user hasn't typed enough yet)
///   - data(suggest)  → tonal pill: "AI suggests {Mood} — {N%}" + actions
///   - data(suggest)  → SizedBox.shrink WHEN safetyFlag == selfHarm
///                       (S3 hides; S4 swaps in compassionate banner)
///   - error          → tonal "Couldn't analyze — pick manually."
class AISuggestionPill extends ConsumerWidget {
  const AISuggestionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiSuggestionControllerProvider);

    return state.when(
      loading: () => _Pill.loading(context),
      data: (suggestion) {
        if (suggestion == null) return const SizedBox.shrink();
        if (suggestion.safetyFlag == AiSafetyFlag.selfHarm) {
          // S3: hide the pill entirely. S4 will replace this branch with the
          // compassionate banner (no protocol change required — the seam is
          // already in the wire format).
          return const SizedBox.shrink();
        }
        return _Pill.suggestion(
          context: context,
          suggestion: suggestion,
          onUseThis: () {
            ref
                .read(logMoodControllerProvider.notifier)
                .applyAiSuggestion(suggestion.mood);
            ref.read(aiSuggestionControllerProvider.notifier).clear();
          },
          onChooseAnother: () =>
              ref.read(aiSuggestionControllerProvider.notifier).clear(),
        );
      },
      error: (_, _) => _Pill.error(context),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.child,
    this.semanticsLabel,
    this.liveRegion = false,
  });

  final Widget child;
  final String? semanticsLabel;
  final bool liveRegion;

  factory _Pill.loading(BuildContext context) {
    return _Pill(
      semanticsLabel: 'Analyzing mood',
      liveRegion: true,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: MoodBloomSpacing.sm),
          Text(
            'Analyzing your mood…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  factory _Pill.suggestion({
    required BuildContext context,
    required AiSuggestion suggestion,
    required VoidCallback onUseThis,
    required VoidCallback onChooseAnother,
  }) {
    final percent = (suggestion.confidence * 100).round();
    final moodLabel = _moodDisplayName(suggestion.mood.name);
    return _Pill(
      semanticsLabel: 'AI suggests $moodLabel with $percent percent confidence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI suggests $moodLabel — $percent%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: MoodBloomSpacing.xs),
          Wrap(
            spacing: MoodBloomSpacing.sm,
            children: [
              TextButton(onPressed: onUseThis, child: const Text('Use this')),
              TextButton(
                onPressed: onChooseAnother,
                child: const Text('Choose another'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  factory _Pill.error(BuildContext context) {
    return _Pill(
      child: Text(
        "Couldn't analyze — pick manually.",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Container(
      padding: EdgeInsets.symmetric(
        horizontal: MoodBloomSpacing.md,
        vertical: MoodBloomSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
      ),
      child: child,
    );
    if (semanticsLabel == null) return body;
    return Semantics(
      label: semanticsLabel,
      liveRegion: liveRegion,
      child: body,
    );
  }
}

String _moodDisplayName(String name) {
  if (name.isEmpty) return name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}
