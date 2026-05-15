import 'package:core/core.dart';

/// Failure modes for the WebAuthn assertion ceremony (ADR-0014
/// Decision B).
///
/// `counterRegression` deserves the explicit variant because it
/// indicates a potential cloned-authenticator attack (ADR-0014 §"Counter
/// rollover") — the UI silently routes the user to PIN and the server
/// emits a structured log line, but the variant is preserved here so
/// telemetry / debug screens can distinguish it from a benign
/// `verificationFailed`.
sealed class WebauthnVerifyFailure extends Failure {
  const WebauthnVerifyFailure({required super.message});

  /// Convenience accessor for the locked-state countdown end-time.
  /// Returns null for every variant except [WebauthnVerifyFailure.rateLimited].
  DateTime? get lockedUntil => null;

  /// No credential is registered for this account. UI should hide the
  /// "Use security key" button when this surfaces.
  const factory WebauthnVerifyFailure.noCredential() = _NoCredential;

  /// The user dismissed the browser's WebAuthn prompt. No retry banner.
  const factory WebauthnVerifyFailure.userCanceled() = _UserCanceled;

  /// The asserted signature counter is not strictly greater than the
  /// stored counter (and the stored counter is non-zero). Indicates a
  /// cloned authenticator OR a stateless authenticator that always
  /// returns 0 — either way, v1.5 fails closed per ADR-0014.
  const factory WebauthnVerifyFailure.counterRegression() = _CounterRegression;

  /// The 5-minute challenge TTL elapsed before the user completed the
  /// browser prompt. UI offers a fresh "Try again" affordance.
  const factory WebauthnVerifyFailure.challengeExpired() = _ChallengeExpired;

  /// Rate-limit hit. The keypad / button is disabled until [until].
  const factory WebauthnVerifyFailure.rateLimited({required DateTime until}) =
      _RateLimited;

  /// CF call or browser API failed for a transient reason.
  const factory WebauthnVerifyFailure.network() = _Network;

  /// Catch-all for unexpected exceptions.
  const factory WebauthnVerifyFailure.unknown(Object? cause) = _Unknown;
}

class _NoCredential extends WebauthnVerifyFailure {
  const _NoCredential()
    : super(message: 'No security key is registered on this account.');
}

class _UserCanceled extends WebauthnVerifyFailure {
  const _UserCanceled() : super(message: 'Security key prompt canceled.');
}

class _CounterRegression extends WebauthnVerifyFailure {
  // Copy is deliberately neutral — the user shouldn't be told they may
  // have been targeted by a cloned-authenticator attack. PIN is the
  // safe fallback.
  const _CounterRegression()
    : super(message: 'We couldn’t verify that key. Please use your PIN.');
}

class _ChallengeExpired extends WebauthnVerifyFailure {
  const _ChallengeExpired()
    : super(message: 'That request expired. Please try again.');
}

class _RateLimited extends WebauthnVerifyFailure {
  const _RateLimited({required this.until})
    : super(message: 'Too many tries. Please wait a moment.');
  final DateTime until;

  @override
  DateTime? get lockedUntil => until;
}

class _Network extends WebauthnVerifyFailure {
  const _Network()
    : super(message: 'Couldn’t reach the server. Please check your connection.');
}

class _Unknown extends WebauthnVerifyFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
