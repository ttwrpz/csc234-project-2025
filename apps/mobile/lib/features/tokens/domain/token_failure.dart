import 'package:core/core.dart';

/// All failure modes for the token-economy data layer.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch
/// help from the analyzer. Mirrors the shape of `PatternFailure` —
/// narrow on purpose: v1.0 only needs surface for "the award write
/// failed and the next render should not assume it succeeded."
///
/// Imports only `package:core/core.dart` — domain-purity rule per
/// CLAUDE.md.
sealed class TokenFailure extends Failure {
  const TokenFailure({required super.message});

  const factory TokenFailure.unknown(String message) = _Unknown;
  const factory TokenFailure.network() = _Network;
  const factory TokenFailure.permissionDenied() = _PermissionDenied;
}

class _Unknown extends TokenFailure {
  const _Unknown(String message) : super(message: message);
}

class _Network extends TokenFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _PermissionDenied extends TokenFailure {
  const _PermissionDenied()
    : super(message: 'Token write was denied for this user.');
}
