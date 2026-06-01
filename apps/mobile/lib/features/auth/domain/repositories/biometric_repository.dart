import '../entities/biometric_capability.dart';

/// Contract for any backing implementation that gates app access behind a
/// biometric prompt. The concrete impl in `data/` wraps `local_auth` and
/// `SharedPreferences`; tests inject a fake.
///
/// Returning `bool` from [authenticate] (instead of throwing on cancel) keeps
/// the user-cancellation path quiet - cancellation isn't an error, it's a
/// choice. Hardware/config errors still propagate as exceptions and are
/// translated into `AuthFailure.biometricFailed` upstream.
abstract class BiometricRepository {
  /// Probe the device for biometric capability + read the user's opt-in.
  Future<BiometricCapability> capability();

  /// Persist the user's opt-in toggle. Idempotent.
  Future<void> setOptIn(bool enabled);

  /// Show the OS biometric prompt. Returns `true` on success, `false` on
  /// user cancellation, throws on hardware error.
  Future<bool> authenticate({required String reason});
}
