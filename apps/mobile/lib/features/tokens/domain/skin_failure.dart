import 'package:core/core.dart';

/// All failure modes for the skin-unlock data layer.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch
/// help from the analyzer. Mirrors the shape of [TokenFailure] —
/// narrow on purpose.
///
/// Imports only `package:core/core.dart` — domain-purity rule per
/// CLAUDE.md.
sealed class SkinFailure extends Failure {
  const SkinFailure({required super.message});

  /// User tried to unlock a skin but their token balance is below the
  /// cost. The modal surfaces this as a disabled state rather than a
  /// snackbar — but the use case must still defend against the rare
  /// case where the balance changed (e.g. token award racing the
  /// spend) between modal-open and confirm-tap.
  const factory SkinFailure.insufficientTokens({
    required int required,
    required int available,
  }) = _InsufficientTokens;

  /// User tried to unlock a skin already in their pool. Idempotency
  /// guard — the modal should never offer this path, but a retry under
  /// flaky network might land here.
  const factory SkinFailure.alreadyUnlocked() = _AlreadyUnlocked;

  /// Skin id is not in the catalog. Should never happen for production
  /// paths (the modal can only surface in-catalog skins), but defensive
  /// in case a stale client tries an unknown id.
  const factory SkinFailure.unknownSkin(String skinId) = _UnknownSkin;

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

class _UnknownSkin extends SkinFailure {
  const _UnknownSkin(this.skinId)
    : super(message: "We couldn't find that skin.");

  final String skinId;
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
