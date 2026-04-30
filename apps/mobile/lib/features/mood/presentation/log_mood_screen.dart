import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../domain/repositories/mood_media_repository.dart';
import 'controllers/ai_suggestion_controller.dart';
import 'controllers/log_mood_controller.dart';
import 'controllers/log_mood_submission_controller.dart';
import 'widgets/ai_suggestion_pill.dart';
import 'widgets/intensity_dots.dart';
import 'widgets/intensity_slider.dart';
import 'widgets/media_picker_button.dart';
import 'widgets/media_thumbnail_strip.dart';
import 'widgets/mood_text_field.dart';
import 'widgets/mood_type_grid.dart';

/// Mood logging screen — pivot feature #1 (intensity 1..5) and the entry
/// point for AI mood detection in S3.
class LogMoodScreen extends ConsumerWidget {
  const LogMoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(logMoodControllerProvider);
    final submission = ref.watch(logMoodSubmissionControllerProvider);
    final controller = ref.read(logMoodControllerProvider.notifier);
    final theme = Theme.of(context);

    final canSave = draft.mood != null && !submission.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('How are you feeling?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl),
          child: ListView(
            children: [
              const SizedBox(height: MoodBloomSpacing.xl),
              Text('Pick a mood', style: theme.textTheme.titleMedium),
              const SizedBox(height: MoodBloomSpacing.md),
              MoodTypeGrid(selected: draft.mood, onSelect: controller.pickMood),
              const SizedBox(height: MoodBloomSpacing.xl),
              Text('How intense?', style: theme.textTheme.titleMedium),
              const SizedBox(height: MoodBloomSpacing.md),
              IntensityDots(intensity: draft.intensity),
              const SizedBox(height: MoodBloomSpacing.sm),
              IntensitySlider(
                intensity: draft.intensity,
                onChanged: controller.setIntensity,
              ),
              const SizedBox(height: MoodBloomSpacing.xl),
              Text('Want to add a note?', style: theme.textTheme.titleMedium),
              const SizedBox(height: MoodBloomSpacing.md),
              MoodTextField(
                value: draft.text,
                onChanged: (text) {
                  controller.setText(text);
                  ref
                      .read(aiSuggestionControllerProvider.notifier)
                      .onTextChanged(text);
                },
              ),
              const SizedBox(height: MoodBloomSpacing.sm),
              const AISuggestionPill(),
              const SizedBox(height: MoodBloomSpacing.lg),
              if (draft.pickedMedia.isNotEmpty) ...[
                MediaThumbnailStrip(
                  media: draft.pickedMedia,
                  onRemove: controller.removeMedia,
                ),
                const SizedBox(height: MoodBloomSpacing.sm),
              ],
              MediaPickerButton(
                onPick: (source) => _onPickMedia(context, ref, source),
              ),
              if (submission.errorMessage != null) ...[
                const SizedBox(height: MoodBloomSpacing.sm),
                Text(
                  submission.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: MoodBloomSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: MoodBloomSpacing.tapTargetMin,
                child: FilledButton(
                  onPressed: canSave ? () => _onSave(context, ref) : null,
                  child: submission.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(height: MoodBloomSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final entry = await ref.read(logMoodControllerProvider.notifier).save();
    if (entry != null && context.mounted) {
      context.go('/history');
    }
  }

  Future<void> _onPickMedia(
    BuildContext context,
    WidgetRef ref,
    MoodMediaSource source,
  ) async {
    final picker = ref.read(pickMoodMediaUseCaseProvider);
    final controller = ref.read(logMoodControllerProvider.notifier);
    final submission = ref.read(logMoodSubmissionControllerProvider.notifier);
    final result = await picker(source: source);
    switch (result) {
      case Ok(:final value):
        controller.addAllMedia(value);
      case Err(:final failure):
        submission.fail(failure.message);
    }
  }
}
