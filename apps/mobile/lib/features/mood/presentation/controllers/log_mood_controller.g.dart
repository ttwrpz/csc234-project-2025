// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_mood_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.

@ProviderFor(LogMoodController)
final logMoodControllerProvider = LogMoodControllerProvider._();

/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.
final class LogMoodControllerProvider
    extends $NotifierProvider<LogMoodController, MoodDraft> {
  /// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
  /// canonical in-progress entry shape and does not need a wrapper.
  ///
  /// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
  /// sibling [LogMoodSubmissionController]. Navigation on success is performed
  /// by the screen, not this controller — keeps the controller free of
  /// `BuildContext` and `package:go_router` imports.
  LogMoodControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logMoodControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logMoodControllerHash();

  @$internal
  @override
  LogMoodController create() => LogMoodController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MoodDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MoodDraft>(value),
    );
  }
}

String _$logMoodControllerHash() => r'd60696ccfac6ddcfa09b8b518f9e6128e4759dcb';

/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.

abstract class _$LogMoodController extends $Notifier<MoodDraft> {
  MoodDraft build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MoodDraft, MoodDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MoodDraft, MoodDraft>,
              MoodDraft,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
