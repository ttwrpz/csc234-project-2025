import 'package:core/core.dart';

/// Failure modes for removing (retiring) a registered WebAuthn credential
/// (ADR-0014). Removal goes through the authenticated
/// `webauthnRemoveCredential` Cloud Function; the client gates it behind a
/// step-up re-auth, so the failures here are about the delete call itself,
/// not the re-auth (which surfaces its own factor-specific failures).
sealed class WebauthnRemoveFailure extends Failure {
  const WebauthnRemoveFailure({required super.message});

  /// The CF call failed for a transient reason (offline, 5xx, timeout).
  const factory WebauthnRemoveFailure.network() = _Network;

  /// Catch-all for unexpected exceptions.
  const factory WebauthnRemoveFailure.unknown(Object? cause) = _Unknown;
}

class _Network extends WebauthnRemoveFailure {
  const _Network()
    : super(
        message: 'Couldn’t reach the server. Please check your connection.',
      );
}

class _Unknown extends WebauthnRemoveFailure {
  const _Unknown(this.cause)
    : super(message: 'Couldn’t remove the security key. Please try again.');
  final Object? cause;
}
