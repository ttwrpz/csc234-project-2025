import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';

void main() {
  group('AuthFailure variants — construction smoke tests', () {
    test('invalidEmail', () {
      const f = AuthFailure.invalidEmail();
      expect(f.message, contains('email'));
    });
    test('weakPassword', () {
      const f = AuthFailure.weakPassword();
      expect(f.message, contains('characters'));
    });
    test('wrongPassword', () {
      const f = AuthFailure.wrongPassword();
      expect(f.message, contains('do not match'));
    });
    test('userNotFound', () {
      const f = AuthFailure.userNotFound();
      expect(f.message, contains('account'));
    });
    test('emailAlreadyInUse', () {
      const f = AuthFailure.emailAlreadyInUse();
      expect(f.message, contains('already exists'));
    });
    test('googleCancelled', () {
      const f = AuthFailure.googleCancelled();
      expect(f.message, contains('Google'));
    });
    test('googleConfigMissing', () {
      const f = AuthFailure.googleConfigMissing();
      expect(f.message, contains('Google'));
    });
    test('network', () {
      const f = AuthFailure.network();
      expect(f.message, contains('Network'));
    });
    test('tooManyRequests', () {
      const f = AuthFailure.tooManyRequests();
      expect(f.message, contains('Too many'));
    });
    test('biometricUnavailable', () {
      const f = AuthFailure.biometricUnavailable();
      expect(f.message, contains('fingerprint'));
    });
    test('biometricCancelled', () {
      const f = AuthFailure.biometricCancelled();
      expect(f.message, contains('cancelled'));
    });
    test('biometricFailed carries reason; user message is generic', () {
      const f = AuthFailure.biometricFailed('hardware error');
      expect(f.message, contains('verify'));
    });
    test('unknown carries cause', () {
      final f = AuthFailure.unknown('oops');
      expect(f.message, contains('Something'));
    });
  });
}
