import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/mood_draft.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_type.dart';
import 'log_mood_submission_controller.dart';

part 'log_mood_controller.g.dart';

/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.
@riverpod
class LogMoodController extends _$LogMoodController {
  @override
  MoodDraft build() => MoodDraft.empty();

  void pickMood(MoodType mood) => state = state.copyWith(mood: mood);

  void setIntensity(int value) => state = state.copyWith(intensity: value);

  void setText(String text) => state = state.copyWith(text: text);

  /// Validates the draft, calls the use case, and resets the draft on
  /// success. Returns the saved [MoodEntry] on success or `null` on failure
  /// (the caller routes only when the entry is non-null).
  Future<MoodEntry?> save() async {
    final submission = ref.read(logMoodSubmissionControllerProvider.notifier);
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      // Defense in depth — the router already prevents reaching this screen
      // unauthenticated.
      submission.fail('You need to be signed in.');
      return null;
    }
    submission.begin();
    final usecase = ref.read(saveMoodEntryUseCaseProvider);
    final result = await usecase(userId: user.uid, draft: state);
    return result.fold(
      ok: (entry) {
        submission.succeed();
        state = MoodDraft.empty();
        return entry;
      },
      err: (failure) {
        submission.fail(failure.message);
        return null;
      },
    );
  }
}
