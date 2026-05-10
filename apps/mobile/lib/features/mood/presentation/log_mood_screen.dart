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

/// Mood logging screen — pivot feature #1 (intensity 1..5) and the entry
/// point for AI mood detection.
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
/// + save on the right so a 1280–1440dp window doesn't waste real estate.
class LogMoodScreen extends ConsumerStatefulWidget {
  const LogMoodScreen({super.key, this.editEntryId});

  final String? editEntryId;

  /// Width threshold above which the screen switches to the two-column
  /// desktop layout. Chosen at 720dp because that's the typical handoff
  /// point between phone landscape and tablet/portrait — and it matches
  /// the breakpoint already used by the History DayEntriesSheet dialog.
  static const double wideBreakpoint = 720;

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
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= LogMoodScreen.wideBreakpoint;
            if (isWide) {
              return _WideLayout(
                draft: draft,
                submission: submission,
                controller: controller,
                isEditMode: isEditMode,
                editing: _editing,
                hasMood: hasMood,
                canSave: canSave,
                onSave: () => _onSave(context, ref),
                onPickMedia: (source) => _onPickMedia(context, ref, source),
                onCancelEdit: _editing == null
                    ? null
                    : () => context.go('/history/${_editing!.id}'),
              );
            }
            return _NarrowLayout(
              draft: draft,
              submission: submission,
              controller: controller,
              isEditMode: isEditMode,
              editing: _editing,
              hasMood: hasMood,
              canSave: canSave,
              onSave: () => _onSave(context, ref),
              onPickMedia: (source) => _onPickMedia(context, ref, source),
              onCancelEdit: _editing == null
                  ? null
                  : () => context.go('/history/${_editing!.id}'),
            );
          },
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
      // updated values; create flows still drop on /history.
      if (original != null) {
        context.go('/history/${entry.id}');
      } else {
        context.go('/history');
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

/// Original phone layout — single-column ListView with the sticky-bottom
/// Save bar. Preserved verbatim from the pre-redesign version so existing
/// goldens / widget tests stay green.
class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.draft,
    required this.submission,
    required this.controller,
    required this.isEditMode,
    required this.editing,
    required this.hasMood,
    required this.canSave,
    required this.onSave,
    required this.onPickMedia,
    required this.onCancelEdit,
  });

  final MoodDraft draft;
  final LogMoodSubmissionState submission;
  final LogMoodController controller;
  final bool isEditMode;
  final MoodEntry? editing;
  final bool hasMood;
  final bool canSave;
  final VoidCallback onSave;
  final ValueChanged<MoodMediaSource> onPickMedia;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('log-mood-narrow'),
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
              _Header(isEditMode: isEditMode),
              if (isEditMode && editing != null) ...[
                const SizedBox(height: MoodBloomSpacing.md),
                _EditModeBanner(
                  entry: editing!,
                  onCancel: onCancelEdit ?? () {},
                ),
              ],
              const SizedBox(height: MoodBloomSpacing.lg),
              const MbSectionLabel('Choose a feeling'),
              const SizedBox(height: MoodBloomSpacing.sm),
              MoodTypeGrid(selected: draft.mood, onSelect: controller.pickMood),
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
                onPickMedia: onPickMedia,
                wideLayout: false,
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
          isEditMode: isEditMode,
          onPressed: canSave ? onSave : null,
        ),
      ],
    );
  }
}

/// Two-column desktop layout. Left column hosts the "what you're feeling"
/// inputs (mood grid + intensity); right column hosts the "tell us about
/// it" inputs (note, media, AI pill, save). Constrained to
/// [LogMoodScreen.maxFormWidth] and centered so the form doesn't stretch
/// across an ultra-wide monitor.
class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.draft,
    required this.submission,
    required this.controller,
    required this.isEditMode,
    required this.editing,
    required this.hasMood,
    required this.canSave,
    required this.onSave,
    required this.onPickMedia,
    required this.onCancelEdit,
  });

  final MoodDraft draft;
  final LogMoodSubmissionState submission;
  final LogMoodController controller;
  final bool isEditMode;
  final MoodEntry? editing;
  final bool hasMood;
  final bool canSave;
  final VoidCallback onSave;
  final ValueChanged<MoodMediaSource> onPickMedia;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('log-mood-wide'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LogMoodScreen.maxFormWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.xl,
            MoodBloomSpacing.pagePadding,
            MoodBloomSpacing.xl,
            MoodBloomSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(isEditMode: isEditMode),
              if (isEditMode && editing != null) ...[
                const SizedBox(height: MoodBloomSpacing.md),
                _EditModeBanner(
                  entry: editing!,
                  onCancel: onCancelEdit ?? () {},
                ),
              ],
              const SizedBox(height: MoodBloomSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 55,
                    child: _LeftColumn(
                      key: const ValueKey('log-mood-wide-left'),
                      draft: draft,
                      controller: controller,
                    ),
                  ),
                  const SizedBox(width: MoodBloomSpacing.xl),
                  Expanded(
                    flex: 45,
                    child: _RightColumn(
                      key: const ValueKey('log-mood-wide-right'),
                      draft: draft,
                      submission: submission,
                      controller: controller,
                      hasMood: hasMood,
                      canSave: canSave,
                      isEditMode: isEditMode,
                      onSave: onSave,
                      onPickMedia: onPickMedia,
                      errorTextStyle: MbFonts.nunito(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({super.key, required this.draft, required this.controller});

  final MoodDraft draft;
  final LogMoodController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('Choose a feeling'),
        const SizedBox(height: MoodBloomSpacing.sm),
        MoodTypeGrid(selected: draft.mood, onSelect: controller.pickMood),
        const SizedBox(height: MoodBloomSpacing.xl),
        _IntensitySection(
          intensity: draft.intensity,
          mood: draft.mood,
          onChanged: controller.setIntensity,
        ),
      ],
    );
  }
}

class _RightColumn extends ConsumerWidget {
  const _RightColumn({
    super.key,
    required this.draft,
    required this.submission,
    required this.controller,
    required this.hasMood,
    required this.canSave,
    required this.isEditMode,
    required this.onSave,
    required this.onPickMedia,
    required this.errorTextStyle,
  });

  final MoodDraft draft;
  final LogMoodSubmissionState submission;
  final LogMoodController controller;
  final bool hasMood;
  final bool canSave;
  final bool isEditMode;
  final VoidCallback onSave;
  final ValueChanged<MoodMediaSource> onPickMedia;
  final TextStyle errorTextStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          onPickMedia: onPickMedia,
          wideLayout: true,
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
        const SizedBox(height: MoodBloomSpacing.md),
        const AISuggestionPill(),
        if (submission.errorMessage != null) ...[
          const SizedBox(height: MoodBloomSpacing.sm),
          Text(submission.errorMessage!, style: errorTextStyle),
        ],
        const SizedBox(height: MoodBloomSpacing.lg),
        _SaveButton(
          hasMood: hasMood,
          loading: submission.isSubmitting,
          isEditMode: isEditMode,
          onPressed: canSave ? onSave : null,
        ),
      ],
    );
  }
}

/// Header row — Fraunces 20/600 title only. Title flips to "Edit entry"
/// when the screen is opened with `?edit=<id>` so the user knows they
/// are mutating an existing record, not creating a new one.
class _Header extends StatelessWidget {
  const _Header({required this.isEditMode});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      isEditMode ? 'Edit entry' : 'How are you?',
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
///
/// In wide layouts the attach affordance becomes a single full-width
/// "Attach a photo" outlined button that sits BELOW the counter row, so
/// both rows stay readable instead of competing for horizontal space
/// with the icon-only buttons.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.onTextChanged,
    required this.onPickMedia,
    required this.wideLayout,
  });

  final String text;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<MoodMediaSource> onPickMedia;
  final bool wideLayout;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final counter = Text(
      '${text.length}/${MoodTextField.maxChars}',
      style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
    );
    final picker = MediaPickerButton(
      onPick: onPickMedia,
      wideLayout: wideLayout,
    );

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
          if (wideLayout) ...[
            Align(alignment: Alignment.centerRight, child: counter),
            const SizedBox(height: 8),
            picker,
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [picker, counter],
            ),
        ],
      ),
    );
  }
}

/// Sticky-bottom Save bar used by the narrow phone layout. Padded so the
/// button breathes above the system gesture inset.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.sm,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
      child: _SaveButton(
        hasMood: hasMood,
        loading: loading,
        isEditMode: isEditMode,
        onPressed: onPressed,
      ),
    );
  }
}

/// Inner Save button — extracted from `_SaveBar` so the wide layout can
/// embed it at the bottom of the right column without the bar's outer
/// padding.
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
        : (isEditMode ? 'Save changes' : 'Save entry');
    return MbPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }
}

/// Soft-coral banner shown at the top of Log Mood when in edit mode.
/// Tells the user (1) which entry they're editing — by date — and
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
