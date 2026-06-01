import 'package:core/core.dart';

/// All failure modes for the bipolar / medical disclaimer ack store.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch
/// help from the analyzer. Extends [Failure] directly - disclaimer
/// failures are conceptually distinct from auth, mood, or harvest
/// failures.
///
/// Imports only `package:core/core.dart` - domain-purity rule per
/// CLAUDE.md.
sealed class DisclaimerFailure extends Failure {
  const DisclaimerFailure({required super.message});

  const factory DisclaimerFailure.unknown(String message) = _Unknown;
  const factory DisclaimerFailure.network() = _Network;
  const factory DisclaimerFailure.permissionDenied() = _PermissionDenied;
}

class _Unknown extends DisclaimerFailure {
  const _Unknown(String message) : super(message: message);
}

class _Network extends DisclaimerFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _PermissionDenied extends DisclaimerFailure {
  const _PermissionDenied()
    : super(message: 'Disclaimer ack is not writable for this user.');
}
