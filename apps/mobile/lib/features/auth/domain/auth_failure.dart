import 'package:core/core.dart';

/// All failure modes for the auth feature. Sealed so every consumer that
/// pattern-matches gets exhaustive-switch help from the analyzer.
///
/// Variants map 1:1 to `FirebaseAuthException` codes that we surface; raw
/// exceptions never cross the data/domain boundary.
sealed class AuthFailure extends Failure {
  const AuthFailure({required super.message});

  const factory AuthFailure.invalidEmail() = _InvalidEmail;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.wrongPassword() = _WrongPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.googleCancelled() = _GoogleCancelled;
  const factory AuthFailure.googleConfigMissing() = _GoogleConfigMissing;
  const factory AuthFailure.network() = _Network;
  const factory AuthFailure.tooManyRequests() = _TooManyRequests;
  const factory AuthFailure.biometricUnavailable() = _BiometricUnavailable;
  const factory AuthFailure.biometricCancelled() = _BiometricCancelled;
  const factory AuthFailure.biometricFailed(String reason) = _BiometricFailed;
  // Surfaced by `AuthRepository.deleteCurrentUser()` when Firebase
  // Auth's ~5-minute recent-login window has elapsed. This is a
  // *recoverable* state from a data-integrity standpoint - the server
  // cascade has already run, so the local Auth record being orphaned
  // is acceptable. The use case logs and proceeds to signOut.
  const factory AuthFailure.requiresRecentLogin() = _RequiresRecentLogin;
  const factory AuthFailure.unknown(Object? cause) = _Unknown;
}

class _InvalidEmail extends AuthFailure {
  const _InvalidEmail() : super(message: 'That email address looks off.');
}

class _WeakPassword extends AuthFailure {
  const _WeakPassword()
    : super(message: 'Use at least 8 characters for your password.');
}

class _WrongPassword extends AuthFailure {
  const _WrongPassword()
    : super(message: 'Email and password do not match our records.');
}

class _UserNotFound extends AuthFailure {
  const _UserNotFound()
    : super(message: 'We could not find an account with that email.');
}

class _EmailAlreadyInUse extends AuthFailure {
  const _EmailAlreadyInUse()
    : super(message: 'An account already exists for that email.');
}

class _GoogleCancelled extends AuthFailure {
  const _GoogleCancelled() : super(message: 'Google sign-in was cancelled.');
}

class _GoogleConfigMissing extends AuthFailure {
  const _GoogleConfigMissing()
    : super(message: 'Google sign-in is not available on this build.');
}

class _Network extends AuthFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _TooManyRequests extends AuthFailure {
  const _TooManyRequests()
    : super(message: 'Too many attempts. Please wait a moment and try again.');
}

class _BiometricUnavailable extends AuthFailure {
  const _BiometricUnavailable()
    : super(
        message: 'Add a fingerprint or face on your device to enable this.',
      );
}

class _BiometricCancelled extends AuthFailure {
  const _BiometricCancelled()
    : super(message: 'Biometric verification was cancelled.');
}

class _BiometricFailed extends AuthFailure {
  const _BiometricFailed(this.reason)
    : super(message: 'Couldn’t verify - please sign in again.');
  final String reason;
}

class _RequiresRecentLogin extends AuthFailure {
  const _RequiresRecentLogin()
    : super(
        message: 'For your security, please sign in again before continuing.',
      );
}

class _Unknown extends AuthFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
