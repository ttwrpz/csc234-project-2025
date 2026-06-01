import 'package:freezed_annotation/freezed_annotation.dart';

part 'biometric_capability.freezed.dart';

/// Snapshot of the device's biometric posture combined with the user's
/// in-app opt-in.
///
/// All three booleans must be true for the cold-boot biometric gate to run -
/// see [shouldGate]. The flags are independent so the settings tile can show
/// distinct messaging (e.g. "no biometric enrolled" vs. "user has opted out").
@freezed
abstract class BiometricCapability with _$BiometricCapability {
  const factory BiometricCapability({
    /// Hardware supports biometric (fingerprint, face, etc.).
    required bool isAvailable,

    /// At least one biometric is enrolled on the device.
    required bool hasEnrolledBiometrics,

    /// User has accepted the in-app opt-in toggle.
    required bool userOptedIn,
  }) = _BiometricCapability;

  const BiometricCapability._();

  /// All three conditions met → the cold-boot gate should run.
  bool get shouldGate => isAvailable && hasEnrolledBiometrics && userOptedIn;
}
