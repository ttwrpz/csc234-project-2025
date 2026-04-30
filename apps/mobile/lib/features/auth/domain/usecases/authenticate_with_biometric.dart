import 'package:core/core.dart';

import '../auth_failure.dart';
import '../repositories/biometric_repository.dart';

/// Triggers the OS biometric prompt and returns a domain `Result`.
///
/// Behaviour:
/// - success → `Ok(null)`
/// - user cancellation → `Err(AuthFailure.biometricCancelled())`
/// - hardware/config error → `Err(AuthFailure.biometricFailed(reason))`
///
/// The use case (rather than the repo) does the failure mapping so the data
/// layer keeps its `bool` / typed-exception contract.
class AuthenticateWithBiometricUseCase {
  const AuthenticateWithBiometricUseCase(this._repository);

  final BiometricRepository _repository;

  Future<Result<void, AuthFailure>> call({required String reason}) async {
    try {
      final ok = await _repository.authenticate(reason: reason);
      if (ok) return const Ok(null);
      return const Err(AuthFailure.biometricCancelled());
    } catch (e) {
      // Hardware / configuration error. We capture the runtimeType only —
      // never the underlying message, which can include user-identifying
      // platform diagnostics.
      return Err(AuthFailure.biometricFailed(e.runtimeType.toString()));
    }
  }
}
