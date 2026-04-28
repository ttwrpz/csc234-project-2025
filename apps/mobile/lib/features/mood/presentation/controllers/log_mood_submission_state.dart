import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_mood_submission_state.freezed.dart';

/// Transient submission state for `LogMoodScreen`.
///
/// Lives separately from [MoodDraft] so the draft (which is the canonical
/// in-progress entry shape) is not coupled to UI loading flags. The screen
/// watches both the draft and this state.
@freezed
class LogMoodSubmissionState with _$LogMoodSubmissionState {
  const factory LogMoodSubmissionState({
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _LogMoodSubmissionState;
}
