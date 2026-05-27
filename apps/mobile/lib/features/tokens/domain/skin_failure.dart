import 'package:core/core.dart';

/// All failure modes for the skin-unlock data layer.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch
/// help from the analyzer. Mirrors the shape of [TokenFailure] - narrow
/// on purpose.
///
/// Imports only `package:core/core.dart` - domain-purity rule per
/// CLAUDE.md.
sealed class SkinFailure extends Failure {
  const SkinFailure({required super.message});

  /// User tried to unlock a skin but their token balance is below the
  /// cost. The Skin Shop card already disables the Purchase button on
  /// insufficient balance, but the use case still defends against the
  /// rare case where the balance changed between modal-open and
  /// confirm-tap.
  const factory SkinFailure.insufficientTokens({
    required int required,
    required int available,
  }) = _InsufficientTokens;

  /// User tried to unlock a skin already in their pool (or the free
  /// default). Idempotency guard.
  const factory SkinFailure.alreadyUnlocked() = _AlreadyUnlocked;

  const factory SkinFailure.network() = _Network;
  const factory SkinFailure.permissionDenied() = _PermissionDenied;
  const factory SkinFailure.unknown(String message) = _Unknown;
}

class _InsufficientTokens extends SkinFailure {
  const _InsufficientTokens({required this.required, required this.available})
    : super(message: 'Not enough tokens to unlock this skin.');

  final int required;
  final int available;
}

class _AlreadyUnlocked extends SkinFailure {
  const _AlreadyUnlocked() : super(message: 'You already own this skin.');
}

class _Network extends SkinFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _PermissionDenied extends SkinFailure {
  const _PermissionDenied()
    : super(message: 'Skin unlock was denied for this user.');
}

class _Unknown extends SkinFailure {
  const _Unknown(String message) : super(message: message);
}
