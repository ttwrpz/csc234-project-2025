import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `LocalAuthentication`. This is the boundary between
/// `package:local_auth` and the rest of the app — no domain types, no
/// widgets. Methods either return primitives or throw a typed exception
/// from this file (mapped upstream by [BiometricRepositoryImpl]).
class BiometricDatasource {
  BiometricDatasource({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// True when the device hardware supports biometric or device credential.
  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  /// True when the device hardware specifically supports biometric (face,
  /// fingerprint, iris). Independent of whether anything is enrolled.
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  /// The biometric methods currently enrolled by the user.
  Future<List<BiometricType>> getEnrolledBiometrics() =>
      _localAuth.getAvailableBiometrics();

  /// Show the OS biometric prompt. Returns true on success.
  ///
  /// `biometricOnly: true` is critical — it prevents the OS from falling
  /// back to a device PIN/passcode, which is NOT what we want for a biometric
  /// gate. `persistAcrossBackgrounding: true` keeps the prompt alive across
  /// config changes (replaces `stickyAuth` from local_auth 2.x).
  ///
  /// Migrated to local_auth 3.x: errors are now [LocalAuthException]
  /// with a typed [LocalAuthExceptionCode] enum instead of stringly-typed
  /// `PlatformException` codes.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          throw const BiometricUnavailableException();
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          throw const BiometricCancelledException();
        default:
          throw BiometricFailedException(e.code.name);
      }
    }
  }
}

/// Hardware doesn't support biometric, no biometric is enrolled, or the
/// device has no passcode set.
class BiometricUnavailableException implements Exception {
  const BiometricUnavailableException();
}

/// User dismissed the OS biometric prompt.
class BiometricCancelledException implements Exception {
  const BiometricCancelledException();
}

/// Catch-all for hardware/config errors that aren't user cancellation.
/// Carries only the platform error code — never the message — to avoid
/// leaking user-identifying diagnostics into logs.
class BiometricFailedException implements Exception {
  const BiometricFailedException(this.code);
  final String code;
}
