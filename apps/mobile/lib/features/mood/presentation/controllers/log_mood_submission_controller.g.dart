// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_mood_submission_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$logMoodSubmissionControllerHash() =>
    r'7cc77312d3d1208d2a60b4de333dc7dd65c30d76';

/// Sibling controller to [LogMoodController]. Holds only the transient
/// submission flags (`isSubmitting`, `errorMessage`) so the draft state can
/// remain the canonical [MoodDraft] without UI noise.
///
/// Copied from [LogMoodSubmissionController].
@ProviderFor(LogMoodSubmissionController)
final logMoodSubmissionControllerProvider =
    AutoDisposeNotifierProvider<
      LogMoodSubmissionController,
      LogMoodSubmissionState
    >.internal(
      LogMoodSubmissionController.new,
      name: r'logMoodSubmissionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$logMoodSubmissionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LogMoodSubmissionController =
    AutoDisposeNotifier<LogMoodSubmissionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
