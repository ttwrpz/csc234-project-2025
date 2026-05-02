import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// Snapshot of all Remote Config-driven feature flags read at app start.
///
/// The `defaults()` factory mirrors the defaults registered in `main.dart`
/// before `fetchAndActivate()` completes, and is the value
/// `featureFlagsProvider` returns when [FeatureFlagSource] throws (e.g.
/// Remote Config not yet initialised). Keep these two sources in sync —
/// see CLAUDE.md "Feature flag (rollback plan)".
@freezed
abstract class FeatureFlags with _$FeatureFlags {
  const factory FeatureFlags({
    required bool aiPatternAnalysisEnabled,
    required bool geminiDetectionEnabled,
  }) = _FeatureFlags;

  const FeatureFlags._();

  factory FeatureFlags.defaults() => const FeatureFlags(
    aiPatternAnalysisEnabled: true,
    geminiDetectionEnabled: true,
  );
}

/// Indirection between [FeatureFlags] reads and any concrete flag store.
/// The production binding wraps `FirebaseRemoteConfig`; tests provide a
/// hand-rolled fake. Keeping this seam pure-Dart lets the provider test
/// run without touching Firebase platform channels.
abstract class FeatureFlagSource {
  bool getBool(String key);
}
