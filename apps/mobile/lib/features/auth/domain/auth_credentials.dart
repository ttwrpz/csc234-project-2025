/// Pure-Dart sealed credentials envelope. Lives in the domain layer so
/// the use case can stay framework-free; implementations in `data/`
/// translate these to the corresponding Firebase Auth credential type
/// (`EmailAuthProvider.credential`, `GoogleAuthProvider`, etc.) at the
/// repository boundary.
///
/// Used by [AuthRepository.reauthenticate] to refresh the user's
/// recent-login window before destructive operations like
/// `currentUser.delete()`. Reauth is the security gate for account
/// deletion - the server-cascade via admin SDK CF requires a fresh
/// ID token.
sealed class AuthCredentials {
  const AuthCredentials();

  /// Email + password reauth. The data layer maps this to
  /// `EmailAuthProvider.credential(email: ..., password: ...)` and calls
  /// `currentUser.reauthenticateWithCredential(...)`.
  const factory AuthCredentials.password({
    required String email,
    required String password,
  }) = PasswordCredentials;

  /// Google OAuth reauth using a freshly-minted ID token from the
  /// platform sign-in flow. The data layer maps this to
  /// `GoogleAuthProvider.credential(idToken: idToken, accessToken: ...)`.
  const factory AuthCredentials.google({required String idToken}) =
      GoogleCredentials;

  /// Biometric reauth - the data layer reads the platform-keystore-
  /// cached Firebase Auth credential and reauthenticates via that. No
  /// payload is required at the domain boundary because the credential
  /// is held by the platform, not the caller.
  const factory AuthCredentials.biometric() = BiometricCredentials;
}

class PasswordCredentials extends AuthCredentials {
  const PasswordCredentials({required this.email, required this.password});
  final String email;
  final String password;
}

class GoogleCredentials extends AuthCredentials {
  const GoogleCredentials({required this.idToken});
  final String idToken;
}

class BiometricCredentials extends AuthCredentials {
  const BiometricCredentials();
}
