import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/providers.dart';
import '../../../mood/data/providers.dart' show saveMoodEntryUseCaseProvider;
import '../../../mood/domain/entities/mood_draft.dart';
import '../../../mood/domain/entities/mood_type.dart';
import '../../domain/entities/intervention_dispatch.dart';
import '../controllers/intervention_controller.dart';
import '../widgets/dispatch_safe_defaults.dart';
import '../widgets/intervention_opt_out_button.dart';

/// Tier 2 surface - gentle journaling prompt.
///
/// Renders the dispatched body, a deterministic rotating prompt question
/// (chosen by `dispatchId.hashCode % prompts.length` so the same dispatch
/// shows the same prompt across cold launches), a mood chip strip, and a
/// multi-line text field. Save invokes [SaveMoodEntryUseCase] with
/// `intensity: 3` - the journaling-as-therapy flow intentionally skips
/// the slider step to keep the surface lightweight; the test asserts
/// this explicitly so a future refactor that adds a slider here has to
/// update the contract.
///
/// CTA layout:
///   - "Save"        → primary; persists then `complete()` + pop.
///   - "Maybe later" → text; closes without saving + calls `complete()`.
///   - "I'm okay"    → outlined; opt-out via the shared button.
class JournalingPromptScreen extends ConsumerStatefulWidget {
  const JournalingPromptScreen({this.dispatch, super.key});

  final InterventionDispatch? dispatch;

  @override
  ConsumerState<JournalingPromptScreen> createState() =>
      _JournalingPromptScreenState();
}

class _JournalingPromptScreenState
    extends ConsumerState<JournalingPromptScreen> {
  /// The journaling prompts. Curated, compassionate; rotated per
  /// dispatch. The set is intentionally small so the prompts feel
  /// purposeful, not random.
  static const List<String> _prompts = [
    "What's been weighing on you?",
    "Is there anything you've been holding back?",
    'What would you want a kind friend to know about today?',
    'Notice one feeling. Where in your body does it sit?',
    'If today had a color, what would it be? Why?',
    'What small thing helped today, even a little?',
  ];

  final TextEditingController _textController = TextEditingController();

  /// Default mood is `sad` because Tier 2 fires from the sliding-5-of-7
  /// negative-day algorithm - the user is already in a heavier stretch.
  /// Letting them pick another mood is a single tap on the chip strip.
  MoodType _selectedMood = MoodType.sad;

  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _bodyText => widget.dispatch?.body ?? DispatchSafeDefaults.tier2;

  String get _prompt {
    final id = widget.dispatch?.dispatchId.hashCode ?? 0;
    final idx = id.abs() % _prompts.length;
    return _prompts[idx];
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = context;

    final uid = ref.read(currentUserStreamProvider).value?.uid;
    if (uid == null || uid.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save right now. Try again?")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final useCase = ref.read(saveMoodEntryUseCaseProvider);
    final draft = MoodDraft(
      mood: _selectedMood,
      // Intensity 3 is the neutral default; the journaling flow skips the
      // slider step on purpose (engineer-brief contract).
      intensity: 3,
      text: _textController.text,
    );
    final result = await useCase(userId: uid, draft: draft);
    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Ok():
        ref.read(interventionControllerProvider.notifier).complete();
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved to your journal.')),
        );
        if (navigator.mounted) navigator.pop();
      case Err():
        messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't save right now. Try again?")),
        );
    }
  }

  void _onMaybeLater() {
    ref.read(interventionControllerProvider.notifier).complete();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>();
    final textColor = mb?.text ?? theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: mb?.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      MbIconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _onMaybeLater,
                        semanticLabel: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A few quiet words',
                    style: MbFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _bodyText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _prompt,
                            style: MbFonts.fraunces(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final m in MoodType.values)
                                ChoiceChip(
                                  label: Text(_labelFor(m)),
                                  selected: _selectedMood == m,
                                  onSelected: (selected) {
                                    if (!selected) return;
                                    setState(() => _selectedMood = m);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // The shared `MbInputField` is single-line by
                          // contract - the journaling surface needs a
                          // taller multi-line input so we render a
                          // `TextField` styled to match the design-system
                          // input shell (mb.card surface, mb.line
                          // border, r14 radius).
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: mb?.card ?? theme.colorScheme.surface,
                              border: Border.all(
                                color:
                                    mb?.line ??
                                    theme.colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _textController,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: null,
                              minLines: 4,
                              style: MbFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Write a few lines, only if it helps…',
                                hintStyle: MbFonts.nunito(
                                  fontSize: 14,
                                  color:
                                      mb?.textDim ??
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom CTA row mirrors the prototype's Save/Maybe
                  // later/I'm okay pattern: save uses the design-system
                  // primary button, the opt-out keeps its compassionate
                  // ghost treatment, and "Maybe later" stays a text
                  // button so the user has a low-cost out.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : _onMaybeLater,
                        child: const Text('Maybe later'),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InterventionOptOutButton(
                            onTapped: () {
                              if (context.mounted) context.pop();
                            },
                          ),
                          const SizedBox(width: 8),
                          MbPrimaryButton(
                            label: 'Save',
                            fullWidth: false,
                            loading: _isSaving,
                            onPressed: _isSaving ? null : _onSave,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelFor(MoodType m) => switch (m) {
    MoodType.happy => 'Joyful',
    MoodType.calm => 'Calm',
    MoodType.okay => 'Okay',
    MoodType.sad => 'Sad',
    MoodType.angry => 'Angry',
    MoodType.anxious => 'Anxious',
  };
}
