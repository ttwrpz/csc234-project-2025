import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// Build-time flag for the WebAuthn fallback factor (ADR-0014).
///
/// v1.5 ships WebAuthn `dark` — the full domain/data/CF surface is in
/// the repo and tested, but no UI tile or verify-button is reachable
/// because this build-time flag is `false`. The reason: WebAuthn
/// credentials bind to a specific origin at registration time, and
/// v1.5 ships as a local demo with no production hosting target.
/// Flipping this flag to `true` requires:
///   1. A deployed production origin (`WEBAUTHN_PRODUCTION_ORIGIN`
///      in `functions/src/webauthnConstants.ts`).
///   2. The FIDO2 RPID rules verified against that domain (Chrome
///      accepts `*.web.app`; Firefox may not — cross-browser smoke).
///   3. Security-reviewer pass 2 (the v1.5 pass 1 covers the dormant
///      code; the lit-up flow needs a re-audit).
/// See ADR-0014 §Decision F and §"Open follow-ups" #1.
///
/// This is intentionally a top-level compile-time `const` rather than a
/// Remote Config field on [FeatureFlags] — the orchestrator's explicit
/// instruction (ADR-0014 §"Decision G", "No new `webauthnEnabled` flag").
/// Compile-time means dead-code elimination keeps the WebAuthn JS-interop
/// out of production binaries entirely when the flag is `false`.
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

    /// Gates the legacy cheer-up dispatcher path (`cheer_up_controller`
    /// + `sendCheerUpPush` Cloud Function). Default `false` in v1.0:
    /// the new client-side Pattern Engine writes
    /// `users/{uid}/patterns/{date}` regardless, but no notification
    /// fires. Sprint 5 re-points the dispatcher at the new
    /// `patterns/{date}.triggeredTier` field, attaches the Quote
    /// Library safety filter and the Bipolar/medical disclaimer
    /// footer, and flips this flag to `true`. See ADR-0011 §4.
    required bool interventionDispatchEnabled,

    /// Master kill-switch for the History privacy gate (ADR-0013).
    /// Default `true`: the gate is honored when the user has opted in
    /// via Settings. Flipping to `false` short-circuits the router
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
