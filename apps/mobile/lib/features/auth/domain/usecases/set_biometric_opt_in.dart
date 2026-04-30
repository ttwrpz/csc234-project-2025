import '../repositories/biometric_repository.dart';

/// Persists the user's biometric opt-in toggle. Idempotent.
///
/// The settings tile calls this with `true` when the switch is flipped on,
/// then immediately runs [AuthenticateWithBiometricUseCase] to confirm — if
/// the user cancels, the tile reverts the toggle by calling this with
/// `false`.
class SetBiometricOptInUseCase {
  const SetBiometricOptInUseCase(this._repository);

  final BiometricRepository _repository;

  Future<void> call(bool enabled) => _repository.setOptIn(enabled);
}
