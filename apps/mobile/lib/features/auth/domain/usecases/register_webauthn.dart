import 'package:core/core.dart';

import '../entities/webauthn_credential.dart';
import '../entities/webauthn_register_failure.dart';
import '../repositories/webauthn_repository.dart';

/// Register a new WebAuthn authenticator (ADR-0014 Decision D).
///
/// Thin orchestration over [WebauthnRepository.register] — the
/// repository owns the four-step CF + browser-API ceremony. The use
/// case exists for symmetry with the PIN family (`SetupPinUseCase`,
/// `VerifyPinUseCase`) so controllers consume use cases, never
/// repositories directly.
class RegisterWebauthnUseCase {
  const RegisterWebauthnUseCase(this._repository);

  final WebauthnRepository _repository;

  Future<Result<WebauthnCredential, WebauthnRegisterFailure>> call({
    required String userId,
  }) => _repository.register(uid: userId);
}
