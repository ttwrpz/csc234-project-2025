import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../domain/entities/mood_type.dart';
import '../domain/repositories/mood_media_repository.dart';
import 'controllers/ai_suggestion_controller.dart';
import 'controllers/log_mood_controller.dart';
import 'controllers/log_mood_submission_controller.dart';
import 'widgets/ai_suggestion_pill.dart';
import 'widgets/intensity_slider.dart';
import 'widgets/media_picker_button.dart';
import 'widgets/media_thumbnail_strip.dart';
import 'widgets/mood_text_field.dart';
import 'widgets/mood_type_grid.dart';

/// Mood logging screen — pivot feature #1 (intensity 1..5) and the entry
/// point for AI mood detection.
///
/// This is a ConsumerStatefulWidget specifically so we can reset the draft
/// + AI suggestion + submission state on every screen-enter. Without that,
/// the controllers persist across bottom-nav swaps and the user comes
/// back to a half-filled form from a previous session.
class LogMoodScreen extends ConsumerStatefulWidget {
  const LogMoodScreen({super.key});

  @override
  ConsumerState<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends ConsumerState<LogMoodScreen> {
  @override
  void initState() {
    super.initState();
    // Riverpod state persists across bottom-nav swaps because the
    // navigation shell keeps every branch alive. Schedule a one-shot
    // reset on the next frame so a fresh visit always starts blank —
    // mood, intensity, note, attachments, AI suggestion, error banner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resetAll(ref);
    });
  }

  static void _resetAll(WidgetRef ref) {
    ref.read(logMoodControllerProvider.notifier).reset();
    ref.read(aiSuggestionControllerProvider.notifier).clear();
    ref.read(logMoodSubmissionControllerProvider.notifier).succeed();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(logMoodControllerProvider);
    final submission = ref.watch(logMoodSubmissionControllerProvider);
    final controller = ref.read(logMoodControllerProvider.notifier);
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

    final hasMood = draft.mood != null;
    final canSave = hasMood && !submission.isSubmitting;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.lg,
                ),
                children: [
                  const _Header(),
                  const SizedBox(height: MoodBloomSpacing.lg),
                  const MbSectionLabel('Choose a feeling'),
                  const SizedBox(height: MoodBloomSpacing.sm),
                  MoodTypeGrid(
                    selected: draft.mood,
                    onSelect: controller.pickMood,
                  ),
                  const SizedBox(height: MoodBloomSpacing.xl),
                  _IntensitySection(
                    intensity: draft.intensity,
                    mood: draft.mood,
                    onChanged: controller.setIntensity,
                  ),
                  const SizedBox(height: MoodBloomSpacing.xl),
                  const MbSectionLabel("What's on your mind?"),
                  const SizedBox(height: MoodBloomSpacing.sm),
                  _NoteCard(
                    text: draft.text,
                    onTextChanged: (text) {
                      controller.setText(text);
                      ref
                          .read(aiSuggestionControllerProvider.notifier)
                          .onTextChanged(text);
                    },
                    onPickMedia: (source) => _onPickMedia(context, ref, source),
                  ),
                  if (draft.pickedMedia.isNotEmpty) ...[
                    const SizedBox(height: MoodBloomSpacing.md),
                    MediaThumbnailStrip(
                      media: draft.pickedMedia,
                      onRemove: controller.removeMedia,
                    ),
                  ],
                  const SizedBox(height: MoodBloomSpacing.md),
                  const AISuggestionPill(),
                  if (submission.errorMessage != null) ...[
                    const SizedBox(height: MoodBloomSpacing.sm),
                    Text(
                      submission.errorMessage!,
                      style: MbFonts.nunito(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _SaveBar(
              hasMood: hasMood,
              loading: submission.isSubmitting,
              onPressed: canSave ? () => _onSave(context, ref) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final entry = await ref.read(logMoodControllerProvider.notifier).save();
    if (entry == null) return;
    // Belt-and-braces: the controller's `_onSaveOk` already empties the
    // draft, but we also clear the AI pill and submission state so the
    // user lands on /history with a clean slate behind them.
    _resetAll(ref);
    if (context.mounted) {
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

/// Header row — Fraunces 20/600 title only. The previous build had a
/// back-arrow `MbIconButton`, which made no sense once Log moved into a
/// permanent bottom-nav slot (there is nothing to "go back" to — the tab
/// itself is the destination). Removing the button also bumps the title
/// flush-left so it matches every other tab root in the app.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      'How are you?',
      style: MbFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
    );
  }
}

/// "Intensity" section — section label + "n / 5" right, then a card with
/// the slider and `soft / vivid` end-caps. The slider pulls its tint from
/// the currently-picked mood.
class _IntensitySection extends StatelessWidget {
  const _IntensitySection({
    required this.intensity,
    required this.mood,
    required this.onChanged,
  });

  final int intensity;
  final MoodType? mood;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MbSectionLabel('Intensity'),
            Text(
              '$intensity / 5',
              style: MbFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: MoodBloomSpacing.sm),
        MbCard(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mb.card,
            border: Border.all(color: mb.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntensitySlider(
                intensity: intensity,
                mood: mood,
                onChanged: onChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'soft',
                    style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                  ),
                  Text(
                    'vivid',
                    style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Note card — 4-row text field, attach buttons row, and "n/500" counter
/// in the same card so the counter sits inside the same chrome as the
/// field, matching the prototype.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.onTextChanged,
    required this.onPickMedia,
  });

  final String text;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<MoodMediaSource> onPickMedia;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mb.card,
        border: Border.all(color: mb.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoodTextField(value: text, onChanged: onTextChanged),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MediaPickerButton(onPick: onPickMedia),
              Text(
                '${text.length}/${MoodTextField.maxChars}',
                style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sticky-bottom Save bar. Disabled until a mood is picked; flips its label
/// to a compassionate "Pick a feeling to continue" until then so the user
/// knows what the next step is.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.hasMood,
    required this.loading,
    required this.onPressed,
  });

  final bool hasMood;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.sm,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
      child: MbPrimaryButton(
        label: hasMood ? 'Save entry' : 'Pick a feeling to continue',
        onPressed: onPressed,
        loading: loading,
      ),
    );
  }
}
