import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_credentials.freezed.dart';

/// Sealed credentials passed from controllers to use cases.
///
/// `emailPassword` overrides [toString] to redact the password
/// literal — the password must never appear in any log line, crash
/// report, or error trace. The redaction is asserted by
/// `auth_credentials_test.dart`.
@freezed
sealed class AuthCredentials with _$AuthCredentials {
  const AuthCredentials._();

  const factory AuthCredentials.emailPassword({
    required String email,
    required String password,
  }) = EmailPasswordCredentials;

  const factory AuthCredentials.google() = GoogleCredentials;

  @override
  String toString() => switch (this) {
    EmailPasswordCredentials(:final email) =>
      'AuthCredentials.emailPassword(email: $email, password: <redacted>)',
    GoogleCredentials() => 'AuthCredentials.google()',
  };
}
