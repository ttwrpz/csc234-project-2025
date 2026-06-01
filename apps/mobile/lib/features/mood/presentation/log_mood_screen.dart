import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../domain/entities/mood_draft.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/entities/mood_type.dart';
import '../domain/repositories/mood_media_repository.dart';
import 'controllers/ai_suggestion_controller.dart';
import 'controllers/log_mood_controller.dart';
import 'controllers/log_mood_submission_controller.dart';
import 'controllers/log_mood_submission_state.dart';
import 'widgets/ai_suggestion_pill.dart';
import 'widgets/existing_media_strip.dart';
import 'widgets/intensity_slider.dart';
import 'widgets/media_picker_button.dart';
import 'widgets/media_thumbnail_strip.dart';
import 'widgets/mood_text_field.dart';
import 'widgets/mood_type_grid.dart';

/// Mood logging screen - intensity 1..5 entry plus the AI mood detection
/// entry point.
///
/// Visual treatment refreshed in v1.6 to match `LogMoodScreen` in
/// `prototype/screens-extra.jsx`:
/// - title "How are you feeling?" Fraunces 26 w600
/// - 3x2 mood grid (`MoodTypeGrid` w/ `MbMoodSvg` glyphs)
/// - 1..5 intensity slider with "barely" / "quite a bit" scale labels
/// - `MbInputField`-style "NOTE (OPTIONAL)" surface for the body text
/// - "Save to your garden" `MbPrimaryButton` with leading check icon
/// - footer disclaimer "Tokens are earned for showing up. Empty days are fine."
///
/// This is a ConsumerStatefulWidget specifically so we can reset the draft
/// + AI suggestion + submission state on every screen-enter. Without that,
/// the controllers persist across bottom-nav swaps and the user comes
/// back to a half-filled form from a previous session.
///
/// When [editEntryId] is non-null the screen enters edit mode: the draft
/// is hydrated from the existing entry on first build, the heading
/// changes to "Edit entry", and Save calls `updateExisting` instead of
/// `save`.
///
/// Layout: a single-column ListView on phones (<720dp wide) and a
/// two-column form on desktop / large tablets (>=720dp). The wide layout
/// puts the mood + intensity controls on the left and the note + media
/// + save on the right so a 1280-1440dp window doesn't waste real estate.
class LogMoodScreen extends ConsumerStatefulWidget {
  const LogMoodScreen({super.key, this.editEntryId});

  final String? editEntryId;

  /// Hard cap on the form's content width on extra-wide windows so the
  /// two columns don't stretch across a 1920dp monitor.
  static const double maxFormWidth = 1080;

  @override
  ConsumerState<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends ConsumerState<LogMoodScreen> {
  /// Entry being edited. Null on the create flow. Populated by the
  /// post-frame hydration callback; we hold a reference so
  /// `updateExisting` can preserve `id`/`userId`/`createdAt`.
  MoodEntry? _editing;

  /// True while the edit-mode hydration future is in flight. Suppresses
  /// the form so the user doesn't see a flash of empty inputs before
  /// the entry's values land.
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    // Riverpod state persists across bottom-nav swaps because the
    // navigation shell keeps every branch alive. The router uses
    // `ValueKey('log-mood:<edit>')` to force a fresh `State` whenever
    // the edit param changes, so this `initState` runs once per
    // create-or-edit visit. The post-frame deferral lets `_resetAll`
    // touch Riverpod notifiers safely (you can't write to a notifier
    // mid-build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enterScreen();
    });
  }

  /// Wipes any leftover draft / AI / submission state and, when in
  /// edit mode, fetches and hydrates the entry. Called from
  /// `initState` and re-callable if the route key strategy ever
  /// changes; defence in depth.
  Future<void> _enterScreen() async {
    _resetAll(ref);
    if (!mounted) return;
    setState(() => _editing = null);

    final id = widget.editEntryId;
    if (id == null) return;

    setState(() => _hydrating = true);
    final entry = await ref.read(moodEntryByIdProvider(id).future);
    if (!mounted) return;

    if (entry == null) {
      setState(() => _hydrating = false);
      if (context.mounted) context.go('/history');
      return;
    }
    if (entry.isLocked()) {
      // Defence in depth: never let an already-locked entry leak into
      // the editor (the detail screen disables Edit, but a stale deep
      // link could still land us here).
      setState(() => _hydrating = false);
      if (context.mounted) context.go('/history/$id');
      return;
    }
    ref.read(logMoodControllerProvider.notifier).loadFromEntry(entry);
    setState(() {
      _editing = entry;
      _hydrating = false;
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
    final mb = Theme.of(context).extension<MbColors>()!;

    final hasMood = draft.mood != null;
    final canSave = hasMood && !submission.isSubmitting;
    final isEditMode = _editing != null;
    final isCreatingViaEditUrl = widget.editEntryId != null && _editing == null;

    // Hydrating phase: route says "?edit=X" but we haven't pulled the
    // entry yet. Show a loading state instead of an empty form so the
    // user doesn't think nothing happened.
    if (_hydrating || isCreatingViaEditUrl) {
      return Scaffold(
        backgroundColor: mb.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(isEditMode: true),
                const SizedBox(height: MoodBloomSpacing.lg),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LogMoodScreen.maxFormWidth,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= MbBreakpoints.logMoodWide;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    MoodBloomSpacing.pagePadding,
                    MoodBloomSpacing.pagePadding,
                    MoodBloomSpacing.pagePadding,
                    MoodBloomSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(isEditMode: isEditMode),
                      if (isEditMode && _editing != null) ...[
                        const SizedBox(height: MoodBloomSpacing.md),
                        _EditModeBanner(
                          entry: _editing!,
                          onCancel: () =>
                              context.go('/history/${_editing!.id}'),
                        ),
                      ],
                      const SizedBox(height: MoodBloomSpacing.lg),
                      if (isWide)
                        _WideBody(
                          draft: draft,
                          submission: submission,
                          controller: controller,
                          hasMood: hasMood,
                          canSave: canSave,
                          isEditMode: isEditMode,
                          onSave: () => _onSave(context, ref),
                          onPickMedia: (source) =>
                              _onPickMedia(context, ref, source),
                        )
                      else
                        _NarrowBody(
                          draft: draft,
                          submission: submission,
                          controller: controller,
                          hasMood: hasMood,
                          canSave: canSave,
                          isEditMode: isEditMode,
                          onSave: () => _onSave(context, ref),
                          onPickMedia: (source) =>
                              _onPickMedia(context, ref, source),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final original = _editing;
    final entry = original == null
        ? await ref.read(logMoodControllerProvider.notifier).save()
        : await ref
              .read(logMoodControllerProvider.notifier)
              .updateExisting(original);
    if (entry == null) return;
    _resetAll(ref);
    if (context.mounted) {
      // Edit returns to the detail screen so the user can verify the
      // updated values. New-entry flows drop on the garden home (`/home`)
      // - the user just logged a mood and the SkyHeader / daily-score
      // strip is where they SEE the impact (atmosphere shift, EWMA tier,
      // today's cell).
      if (original != null) {
        context.go('/history/${entry.id}');
      } else {
        // Confirmation toast over the garden - the prototype's "Saved"
        // toast. Shown before navigating; it lives in the root overlay
        // so it floats over /home.
        MbAppToast.show(
          context,
          title: 'Saved',
          body: "Your mood is now part of this week's garden.",
        );
        context.go('/home');
      }
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

/// Phone layout - single column. Order per the prototype:
/// header (above) -> mood grid -> intensity slider -> AI suggestion ->
/// note field -> media row -> save -> disclaimer.
class _NarrowBody extends ConsumerWidget {
  const _NarrowBody({
    required this.draft,
    required this.submission,
    required this.controller,
    required this.hasMood,
    required this.canSave,
    required this.isEditMode,
    required this.onSave,
    required this.onPickMedia,
  });

  final MoodDraft draft;
  final LogMoodSubmissionState submission;
  final LogMoodController controller;
  final bool hasMood;
  final bool canSave;
  final bool isEditMode;
  final VoidCallback onSave;
  final ValueChanged<MoodMediaSource> onPickMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      key: const ValueKey('log-mood-narrow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MoodGridSection(draft: draft, controller: controller),
        const SizedBox(height: MoodBloomSpacing.lg),
        _IntensitySection(
          intensity: draft.intensity,
          mood: draft.mood,
          onChanged: controller.setIntensity,
        ),
        const SizedBox(height: MoodBloomSpacing.lg),
        // Note first; the AI suggestion sits BELOW it because the
        // suggestion is a reaction to what the user wrote.
        _NoteField(
          text: draft.text,
          onTextChanged: (text) {
            controller.setText(text);
            ref
                .read(aiSuggestionControllerProvider.notifier)
                .onTextChanged(text);
          },
        ),
        const SizedBox(height: MoodBloomSpacing.md),
        const AISuggestionPill(),
        const SizedBox(height: MoodBloomSpacing.md),
        _MediaSection(
          draft: draft,
          controller: controller,
          onPickMedia: onPickMedia,
          wideLayout: false,
        ),
        if (submission.errorMessage != null) ...[
          const SizedBox(height: MoodBloomSpacing.sm),
          Text(
            submission.errorMessage!,
            style: MbFonts.nunito(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: MoodBloomSpacing.lg),
        _SaveButton(
          hasMood: hasMood,
          loading: submission.isSubmitting,
          isEditMode: isEditMode,
          onPressed: canSave ? onSave : null,
        ),
        const SizedBox(height: MoodBloomSpacing.md),
        _DisclaimerFootnote(color: mb.textDim),
      ],
    );
  }
}

/// Tablet+/desktop layout - two columns. Left column hosts the mood
/// grid + intensity slider; right column hosts the AI pill + note field
/// + media + save + disclaimer.
class _WideBody extends ConsumerWidget {
  const _WideBody({
    required this.draft,
    required this.submission,
    required this.controller,
    required this.hasMood,
    required this.canSave,
    required this.isEditMode,
    required this.onSave,
    required this.onPickMedia,
  });

  final MoodDraft draft;
  final LogMoodSubmissionState submission;
  final LogMoodController controller;
  final bool hasMood;
  final bool canSave;
  final bool isEditMode;
  final VoidCallback onSave;
  final ValueChanged<MoodMediaSource> onPickMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      key: const ValueKey('log-mood-wide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoodGridSection(draft: draft, controller: controller),
              const SizedBox(height: MoodBloomSpacing.lg),
              _IntensitySection(
                intensity: draft.intensity,
                mood: draft.mood,
                onChanged: controller.setIntensity,
              ),
            ],
          ),
        ),
        const SizedBox(width: MoodBloomSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Note first; the AI suggestion sits below it because the
              // suggestion reacts to what the user wrote.
              _NoteField(
                text: draft.text,
                onTextChanged: (text) {
                  controller.setText(text);
                  ref
                      .read(aiSuggestionControllerProvider.notifier)
                      .onTextChanged(text);
                },
              ),
              const SizedBox(height: MoodBloomSpacing.md),
              const AISuggestionPill(),
              const SizedBox(height: MoodBloomSpacing.md),
              _MediaSection(
                draft: draft,
                controller: controller,
                onPickMedia: onPickMedia,
                wideLayout: true,
              ),
              if (submission.errorMessage != null) ...[
                const SizedBox(height: MoodBloomSpacing.sm),
                Text(
                  submission.errorMessage!,
                  style: MbFonts.nunito(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: MoodBloomSpacing.lg),
              _SaveButton(
                hasMood: hasMood,
                loading: submission.isSubmitting,
                isEditMode: isEditMode,
                onPressed: canSave ? onSave : null,
              ),
              const SizedBox(height: MoodBloomSpacing.md),
              _DisclaimerFootnote(color: mb.textDim),
            ],
          ),
        ),
      ],
    );
  }
}

/// Header - "How are you feeling?" (or "Edit entry" in edit mode).
class _Header extends StatelessWidget {
  const _Header({required this.isEditMode});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      isEditMode ? 'Edit entry' : 'How are you feeling?',
      style: MbFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
    );
  }
}

/// "How are you?" section eyebrow + 3x2 mood grid.
class _MoodGridSection extends StatelessWidget {
  const _MoodGridSection({required this.draft, required this.controller});

  final MoodDraft draft;
  final LogMoodController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('HOW ARE YOU?'),
        const SizedBox(height: MoodBloomSpacing.sm),
        MoodTypeGrid(selected: draft.mood, onSelect: controller.pickMood),
      ],
    );
  }
}

/// Intensity slider section - eyebrow + slider in a card + "barely" /
/// "quite a bit" end-cap labels.
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
        const MbSectionLabel('INTENSITY'),
        const SizedBox(height: MoodBloomSpacing.sm),
        MbCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntensitySlider(
                intensity: intensity,
                mood: mood,
                onChanged: onChanged,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'barely',
                    style: MbFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mb.textDim,
                    ),
                  ),
                  Text(
                    'quite a bit',
                    style: MbFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mb.textDim,
                    ),
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

/// Note field - "NOTE (OPTIONAL)" eyebrow over an `MbCard` that hosts the
/// 4-row text input plus a "n/500" counter. The placeholder matches the
/// prototype: "What's on your mind? (you can skip this)".
class _NoteField extends StatelessWidget {
  const _NoteField({required this.text, required this.onTextChanged});

  final String text;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('NOTE (OPTIONAL)'),
        const SizedBox(height: MoodBloomSpacing.sm),
        MbCard(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 138),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoodTextField(value: text, onChanged: onTextChanged),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${text.length}/${MoodTextField.maxChars}',
                    style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Media section - eyebrow + `MediaPickerButton` + existing thumbnails.
class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.draft,
    required this.controller,
    required this.onPickMedia,
    required this.wideLayout,
  });

  final MoodDraft draft;
  final LogMoodController controller;
  final ValueChanged<MoodMediaSource> onPickMedia;
  final bool wideLayout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('ATTACH'),
        const SizedBox(height: MoodBloomSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: MediaPickerButton(onPick: onPickMedia, wideLayout: wideLayout),
        ),
        if (draft.mediaRefs.isNotEmpty) ...[
          const SizedBox(height: MoodBloomSpacing.md),
          ExistingMediaStrip(
            gsUris: draft.mediaRefs,
            onRemove: controller.removeMediaRef,
          ),
        ],
        if (draft.pickedMedia.isNotEmpty) ...[
          const SizedBox(height: MoodBloomSpacing.md),
          MediaThumbnailStrip(
            media: draft.pickedMedia,
            onRemove: controller.removeMedia,
          ),
        ],
      ],
    );
  }
}

/// Save button - "Save to your garden" / "Save changes" with a leading
/// check icon, per the prototype's primary CTA.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.hasMood,
    required this.loading,
    required this.isEditMode,
    required this.onPressed,
  });

  final bool hasMood;
  final bool loading;
  final bool isEditMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = !hasMood
        ? 'Pick a feeling to continue'
        : (isEditMode ? 'Save changes' : 'Save to your garden');
    return MbPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      leading: hasMood
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }
}

/// Footer disclaimer line - "Tokens are earned for showing up. Empty days
/// are fine." Italic Nunito 12 / `textDim`, centered.
class _DisclaimerFootnote extends StatelessWidget {
  const _DisclaimerFootnote({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tokens are earned for showing up. Empty days are fine.',
      style: MbFonts.nunito(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Soft-coral banner shown at the top of Log Mood when in edit mode.
/// Tells the user (1) which entry they're editing - by date - and
/// (2) gives them a one-tap escape via Cancel that drops them back at
/// the detail screen unchanged.
class _EditModeBanner extends StatelessWidget {
  const _EditModeBanner({required this.entry, required this.onCancel});

  final MoodEntry entry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final created = entry.createdAt.toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: mb.softCoral,
        border: Border.all(color: MoodBloomColors.coral.withAlpha(0x55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_outlined, size: 18, color: mb.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing your entry from '
              '${_shortDate(created)} · ${_shortTime(created)}',
              style: MbFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: mb.text,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Cancel',
              style: MbFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _shortTime(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final mm = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'pm' : 'am';
    return '$h:$mm $ap';
  }
}
