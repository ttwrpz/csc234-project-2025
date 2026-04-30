import '../entities/biometric_capability.dart';
import '../repositories/biometric_repository.dart';

/// Returns the current biometric posture for the device + the user's opt-in.
///
/// Used by the router to decide whether to redirect to `/biometric-gate`
/// on cold boot, and by the settings tile to enable/disable the toggle.
class CheckBiometricCapabilityUseCase {
  const CheckBiometricCapabilityUseCase(this._repository);

  final BiometricRepository _repository;

  Future<BiometricCapability> call() => _repository.capability();
}
