import 'package:core/core.dart';

/// Failure modes for the WebAuthn registration ceremony (ADR-0014
/// Decision B).
///
/// The variants drive distinct UI affordances: `pinRequired` routes the
/// user to PIN setup, `notProvisioned` surfaces the v1.5-dark message,
/// `userCanceled` is silent (the user dismissed the browser prompt),
/// `verificationFailed` / `network` get a retry button.
sealed class WebauthnRegisterFailure extends Failure {
  const WebauthnRegisterFailure({required super.message});

  /// The user has no PIN set. Per ADR-0014 Decision E, WebAuthn cannot
  /// be enabled without a PIN — the PIN is the recovery factor.
  const factory WebauthnRegisterFailure.pinRequired() = _PinRequired;

  /// The server returned `webauthn_not_provisioned` — the production
  /// origin is unset AND the caller's origin is not in the staging
  /// allow-list. This is the v1.5-dark safety net (ADR-0014 §"Origin
  /// handling").
  const factory WebauthnRegisterFailure.notProvisioned() = _NotProvisioned;

  /// The user dismissed the browser's WebAuthn prompt. No retry banner
  /// — the user knows what they did.
  const factory WebauthnRegisterFailure.userCanceled() = _UserCanceled;

  /// `webauthnRegisterFinish` returned `verification_failed`. The
  /// attestation was malformed or the challenge was tampered with.
  /// Rare; UI surfaces a generic retry.
  const factory WebauthnRegisterFailure.verificationFailed() =
      _VerificationFailed;

  /// CF call or browser API failed for a transient reason.
  const factory WebauthnRegisterFailure.network() = _Network;

  /// Catch-all for unexpected exceptions. Wraps the cause for logging.
  const factory WebauthnRegisterFailure.unknown(Object? cause) = _Unknown;
}

class _PinRequired extends WebauthnRegisterFailure {
  const _PinRequired()
    : super(
        message:
            "Set up a PIN first — it’s your fallback if you lose this device.",
      );
}

class _NotProvisioned extends WebauthnRegisterFailure {
  const _NotProvisioned()
    : super(
        message:
            'Security keys are not available in this build. '
            'Use your PIN to unlock the journal.',
      );
}

class _UserCanceled extends WebauthnRegisterFailure {
  const _UserCanceled() : super(message: 'Security key setup canceled.');
}

class _VerificationFailed extends WebauthnRegisterFailure {
  const _VerificationFailed()
    : super(message: 'We couldn’t verify that key. Please try again.');
}

class _Network extends WebauthnRegisterFailure {
  const _Network()
    : super(message: 'Couldn’t reach the server. Please check your connection.');
}

class _Unknown extends WebauthnRegisterFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
