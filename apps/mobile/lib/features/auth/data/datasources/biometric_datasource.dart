import 'package:flutter/services.dart';
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
  /// Translates `PlatformException` codes into the typed exceptions below.
  /// `biometricOnly: true` is critical — it prevents the OS from falling
  /// back to a device PIN/passcode, which is NOT what we want for a biometric
  /// gate. `stickyAuth: true` keeps the prompt alive across config changes.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
        case 'NotEnrolled':
        case 'PasscodeNotSet':
          throw const BiometricUnavailableException();
        case 'auth_in_progress':
        case 'user_cancel':
        case 'UserCancel':
          throw const BiometricCancelledException();
        default:
          throw BiometricFailedException(e.code);
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
