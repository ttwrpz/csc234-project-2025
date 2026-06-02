import 'package:core/core.dart';

import '../entities/webauthn_remove_failure.dart';
import '../repositories/webauthn_repository.dart';

/// Retire the user's registered WebAuthn credential (ADR-0014).
///
/// Thin orchestration over [WebauthnRepository.removeCredential]. The
/// caller (the Settings security-key tile) gates this behind a step-up
/// re-auth via the ConfirmIdentitySheet - removing a key drops a fallback
/// factor, so identity is confirmed first. This use case only performs the
/// delete once that gate has passed.
class RemoveWebauthnUseCase {
  const RemoveWebauthnUseCase(this._repository);

  final WebauthnRepository _repository;

  Future<Result<void, WebauthnRemoveFailure>> call({required String userId}) =>
      _repository.removeCredential(uid: userId);
}
