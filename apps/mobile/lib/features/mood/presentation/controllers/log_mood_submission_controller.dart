import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'log_mood_submission_state.dart';

part 'log_mood_submission_controller.g.dart';

/// Sibling controller to [LogMoodController]. Holds only the transient
/// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
/// remain the canonical [MoodDraft] without UI noise.
@riverpod
class LogMoodSubmissionController extends _$LogMoodSubmissionController {
  @override
  LogMoodSubmissionState build() => const LogMoodSubmissionState();

  void begin() =>
      state = state.copyWith(isSubmitting: true, errorMessage: null);

  void succeed() => state = const LogMoodSubmissionState();

  void fail(String message) =>
      state = state.copyWith(isSubmitting: false, errorMessage: message);
}
