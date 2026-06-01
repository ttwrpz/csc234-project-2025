import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// Build-time flag for the WebAuthn fallback factor.
///
/// When `true`, the WebAuthn surface is **reachable from the UI**:
///   * `WebauthnSettingsTile` (Settings → Privacy) is interactive.
///   * `PrivacyLockScreen` exposes the "Use security key" affordance.
///   * `webauthnAvailableProvider` returns `true` on web platforms.
///
/// The server-side fence still owns the deploy-blocker: when
/// `WEBAUTHN_PRODUCTION_ORIGIN` (functions/src/webauthnConstants.ts) is
/// empty AND the caller is not on a staging origin, every
/// `webauthn*Start` CF returns `{ok: false, code: 'webauthn_not_provisioned'}`.
/// The UI surfaces that gracefully as a snackbar, then falls back to
/// PIN. Staging origins (`localhost:5173`, etc.) keep working under the
/// default env-var values.
///
/// Flip-to-false rollback path: the const can drop to `false` in a
/// hotfix build to hide the whole surface without touching CFs. The
/// Remote Config `historyPrivacyLockEnabled` switch (ADR-0014 Decision
/// G) hides the entire Privacy card on top of this for the runtime
/// kill-switch path.
///
/// This is intentionally a top-level compile-time `const` rather than a
/// Remote Config field on [FeatureFlags]. Compile-time means dead-code
/// elimination keeps the WebAuthn JS-interop out of native binaries
/// entirely.
const bool kEnableWebauthn = true;

/// Snapshot of all Remote Config-driven feature flags read at app start.
///
/// The `defaults()` factory mirrors the defaults registered in `main.dart`
/// before `fetchAndActivate()` completes, and is the value
/// `featureFlagsProvider` returns when [FeatureFlagSource] throws (e.g.
/// Remote Config not yet initialised). Keep these two sources in sync -
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
  }) = _FeatureFlags;

  const FeatureFlags._();

  factory FeatureFlags.defaults() => const FeatureFlags(
    aiPatternAnalysisEnabled: true,
    geminiDetectionEnabled: true,
    interventionDispatchEnabled: false,
  );
}

/// Indirection between [FeatureFlags] reads and any concrete flag store.
/// The production binding wraps `FirebaseRemoteConfig`; tests provide a
/// hand-rolled fake. Keeping this seam pure-Dart lets the provider test
/// run without touching Firebase platform channels.
abstract class FeatureFlagSource {
  bool getBool(String key);
}
