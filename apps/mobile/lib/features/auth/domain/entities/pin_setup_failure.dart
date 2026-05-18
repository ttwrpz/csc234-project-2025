import 'package:core/core.dart';

/// Failure modes for the PIN setup flow (ADR-0013 Decision G-2).
///
/// Each variant has a compassionate, user-facing [message]. UI surfaces
/// pattern-match on the runtime type so different variants can drive
/// distinct affordances (e.g. mismatch → clear keypad and re-enter;
/// network → retry button).
sealed class PinSetupFailure extends Failure {
  const PinSetupFailure({required super.message});

  /// Convenience for UI screens that branch on "this was a mismatch
  /// vs anything else" without having to import the file-private
  /// variants. Equivalent to `this is _Mismatch`.
  bool get isMismatch => false;

  /// The two-pass entry produced a mismatch. The setup screen clears
  /// the keypad and asks the user to start over.
  const factory PinSetupFailure.mismatch() = _Mismatch;

  /// The supplied raw string was not 6 digits of `0-9`. Should only
  /// fire if the keypad UI is bypassed (defence in depth).
  const factory PinSetupFailure.invalidFormat() = _InvalidFormat;

  /// Firestore reported an error writing the hash doc. The user is
  /// signed in; the setup did not persist; the toggle reverts to OFF
  /// per Decision G cancellation.
  const factory PinSetupFailure.storage() = _Storage;

  /// The user is not signed in. Setup is unreachable when signed out
  /// per ADR-0013 Open Follow-up #4; this variant is a defensive
  /// failsafe in case the UI gate drifts.
  const factory PinSetupFailure.notSignedIn() = _NotSignedIn;

  /// Catch-all for unexpected exceptions during setup. Wraps the
  /// original [cause] for the data-layer logger; never reach the UI.
  const factory PinSetupFailure.unknown(Object? cause) = _Unknown;
}

class _Mismatch extends PinSetupFailure {
  const _Mismatch() : super(message: 'PINs didn’t match — try again.');

  @override
  bool get isMismatch => true;
}

class _InvalidFormat extends PinSetupFailure {
  const _InvalidFormat() : super(message: 'PIN must be 6 digits.');
}

class _Storage extends PinSetupFailure {
  const _Storage()
    : super(message: 'Could not save your PIN. Please check your connection.');
}

class _NotSignedIn extends PinSetupFailure {
  const _NotSignedIn() : super(message: 'Sign in first to set up a PIN.');
}

class _Unknown extends PinSetupFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
