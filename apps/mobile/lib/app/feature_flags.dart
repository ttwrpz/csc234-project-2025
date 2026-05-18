import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// Build-time flag for the WebAuthn fallback factor.
///
/// WebAuthn ships `dark` — the full domain/data/CF surface is in the
/// repo and tested, but no UI tile or verify-button is reachable
/// because this build-time flag is `false`. The reason: WebAuthn
/// credentials bind to a specific origin at registration time, and the
/// current build ships as a local demo with no production hosting target.
/// Flipping this flag to `true` requires:
///   1. A deployed production origin (`WEBAUTHN_PRODUCTION_ORIGIN`
///      in `functions/src/webauthnConstants.ts`).
///   2. The FIDO2 RPID rules verified against that domain (Chrome
///      accepts `*.web.app`; Firefox may not — cross-browser smoke).
///   3. Security-reviewer pass on the lit-up flow.
///
/// This is intentionally a top-level compile-time `const` rather than a
/// Remote Config field on [FeatureFlags]. Compile-time means dead-code
/// elimination keeps the WebAuthn JS-interop out of production binaries
/// entirely when the flag is `false`.
const bool kEnableWebauthn = false;

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

    /// Gates the cheer-up dispatcher path (`cheer_up_controller` +
    /// `sendCheerUpPush` Cloud Function). Default `false`: the
    /// client-side Pattern Engine writes `users/{uid}/patterns/{date}`
    /// regardless, but no notification fires. Flip to `true` once the
    /// dispatcher reads `patterns/{date}.triggeredTier`, the Quote
    /// Library safety filter is attached, and the bipolar/medical
    /// disclaimer footer is in place.
    required bool interventionDispatchEnabled,

    /// Master kill-switch for the History privacy gate. Default
    /// `true`: the gate is honored when the user has opted in via
    /// Settings. Flipping to `false` short-circuits the router
    /// redirect — users are never locked out of `/history`, the
    /// PRIVACY card in Settings is hidden, and existing stored PIN
    /// hashes stay at rest (no data loss). Use this if a critical
    /// post-release bug surfaces.
    required bool historyPrivacyLockEnabled,
  }) = _FeatureFlags;

  const FeatureFlags._();

  factory FeatureFlags.defaults() => const FeatureFlags(
    aiPatternAnalysisEnabled: true,
    geminiDetectionEnabled: true,
    interventionDispatchEnabled: false,
    historyPrivacyLockEnabled: true,
  );
}

/// Indirection between [FeatureFlags] reads and any concrete flag store.
/// The production binding wraps `FirebaseRemoteConfig`; tests provide a
/// hand-rolled fake. Keeping this seam pure-Dart lets the provider test
/// run without touching Firebase platform channels.
abstract class FeatureFlagSource {
  bool getBool(String key);
}
