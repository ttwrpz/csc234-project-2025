import 'package:core/core.dart';

/// Failure modes for the PIN verification path (ADR-0013 Decision E §4).
///
/// The variants drive both the keypad UI affordance (cleared on
/// [PinVerifyFailure.wrong], greyed with countdown on
/// [PinVerifyFailure.locked]) and the rate-limit anchor write
/// (a wrong attempt increments `failedAttempts` in Firestore).
sealed class PinVerifyFailure extends Failure {
  const PinVerifyFailure({required super.message});

  /// Convenience accessor for the locked-state countdown end-time.
  /// Returns null for every variant except [PinVerifyFailure.locked].
  /// Keeps callers from having to pattern-match the file-private
  /// `_Locked` subclass.
  DateTime? get lockedUntil => null;

  /// The user entered an invalid PIN. The data layer has already
  /// incremented `failedAttempts` and (if applicable) set
  /// `lockedUntil` on the rate-limit doc.
  const factory PinVerifyFailure.wrong({required int remainingAttempts}) =
      _Wrong;

  /// The hash doc reads `lockedUntil > now`. The keypad is disabled
  /// until [until]; the UI shows a countdown.
  const factory PinVerifyFailure.locked({required DateTime until}) = _Locked;

  /// The user has not set up a PIN. Should be unreachable from the
  /// verify screen (only shown when a PIN exists) but kept here so
  /// the data-layer reads stay typed end-to-end.
  const factory PinVerifyFailure.noPinSet() = _NoPinSet;

  /// The supplied raw string was not 6 digits of `0-9`.
  const factory PinVerifyFailure.invalidFormat() = _InvalidFormat;

  /// Firestore read failed. The user is not held hostage by a transient
  /// network blip - the UI surfaces a retry affordance.
  const factory PinVerifyFailure.storage() = _Storage;

  /// Catch-all for unexpected exceptions. Wraps the cause for the
  /// data-layer logger.
  const factory PinVerifyFailure.unknown(Object? cause) = _Unknown;
}

class _Wrong extends PinVerifyFailure {
  const _Wrong({required this.remainingAttempts})
    : super(message: 'That PIN didn’t match.');
  final int remainingAttempts;
}

class _Locked extends PinVerifyFailure {
  const _Locked({required this.until})
    : super(message: 'Too many tries. Please wait a moment.');
  final DateTime until;

  @override
  DateTime? get lockedUntil => until;
}

class _NoPinSet extends PinVerifyFailure {
  const _NoPinSet() : super(message: 'No PIN is set on this account.');
}

class _InvalidFormat extends PinVerifyFailure {
  const _InvalidFormat() : super(message: 'PIN must be 6 digits.');
}

class _Storage extends PinVerifyFailure {
  const _Storage()
    : super(
        message: 'Could not verify right now. Please check your connection.',
      );
}

class _Unknown extends PinVerifyFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
