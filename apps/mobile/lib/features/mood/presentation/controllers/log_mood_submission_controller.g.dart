// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_mood_submission_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sibling controller to [LogMoodController]. Holds only the transient
/// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
/// remain the canonical [MoodDraft] without UI noise.

@ProviderFor(LogMoodSubmissionController)
final logMoodSubmissionControllerProvider =
    LogMoodSubmissionControllerProvider._();

/// Sibling controller to [LogMoodController]. Holds only the transient
/// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
/// remain the canonical [MoodDraft] without UI noise.
final class LogMoodSubmissionControllerProvider
    extends
        $NotifierProvider<LogMoodSubmissionController, LogMoodSubmissionState> {
  /// Sibling controller to [LogMoodController]. Holds only the transient
  /// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
  /// remain the canonical [MoodDraft] without UI noise.
  LogMoodSubmissionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logMoodSubmissionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logMoodSubmissionControllerHash();

  @$internal
  @override
  LogMoodSubmissionController create() => LogMoodSubmissionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogMoodSubmissionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogMoodSubmissionState>(value),
    );
  }
}

String _$logMoodSubmissionControllerHash() =>
    r'7cc77312d3d1208d2a60b4de333dc7dd65c30d76';

/// Sibling controller to [LogMoodController]. Holds only the transient
/// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
/// remain the canonical [MoodDraft] without UI noise.

abstract class _$LogMoodSubmissionController
    extends $Notifier<LogMoodSubmissionState> {
  LogMoodSubmissionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<LogMoodSubmissionState, LogMoodSubmissionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LogMoodSubmissionState, LogMoodSubmissionState>,
              LogMoodSubmissionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
