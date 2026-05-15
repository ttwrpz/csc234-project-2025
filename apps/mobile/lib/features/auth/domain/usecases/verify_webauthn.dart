import 'package:core/core.dart';

import '../entities/webauthn_verify_failure.dart';
import '../repositories/webauthn_repository.dart';

/// Verify the user's registered WebAuthn authenticator (ADR-0014
/// Decision D).
///
/// Thin orchestration over [WebauthnRepository.verify]. Called from
/// `PinVerifyScreen` when the user taps "Use security key" above the
/// PIN keypad; on success the calling controller flips
/// `historyUnlockedThisSessionProvider` exactly as the PIN happy path
/// does today.
class VerifyWebauthnUseCase {
  const VerifyWebauthnUseCase(this._repository);

  final WebauthnRepository _repository;

  Future<Result<void, WebauthnVerifyFailure>> call({
    required String userId,
  }) => _repository.verify(uid: userId);
}
