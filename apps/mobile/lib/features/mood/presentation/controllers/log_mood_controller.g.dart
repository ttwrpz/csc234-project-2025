// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_mood_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$logMoodControllerHash() => r'4a63d3f358804ef9951538ffab4b70c54643c401';

/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.
///
/// Copied from [LogMoodController].
@ProviderFor(LogMoodController)
final logMoodControllerProvider =
    AutoDisposeNotifierProvider<LogMoodController, MoodDraft>.internal(
      LogMoodController.new,
      name: r'logMoodControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$logMoodControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LogMoodController = AutoDisposeNotifier<MoodDraft>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
