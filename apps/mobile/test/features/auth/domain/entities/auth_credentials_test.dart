import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/auth_credentials.dart';

void main() {
  group('AuthCredentials', () {
    test('emailPassword.toString redacts the password literal', () {
      const password = 'super-secret-pw-123';
      const creds = AuthCredentials.emailPassword(
        email: 'user@example.com',
        password: password,
      );
      final stringified = creds.toString();
      expect(
        stringified.contains(password),
        isFalse,
        reason:
            'Password literal must never appear in toString output (HB-001 invariant 4)',
      );
      expect(stringified, contains('user@example.com'));
      expect(stringified, contains('<redacted>'));
    });

    test('google.toString contains no sensitive payload', () {
      const creds = AuthCredentials.google();
      expect(creds.toString(), 'AuthCredentials.google()');
    });
  });
}
