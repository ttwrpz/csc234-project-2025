import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error for empty string', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('test.user@domain.co.th'), isNull);
      expect(Validators.email(' user@example.com '), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for empty string', () {
      expect(Validators.password(''), isNotNull);
    });

    test('returns error for null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('returns error for short password', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('StrongPass1!'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns error when passwords do not match', () {
      expect(Validators.confirmPassword('abc', '123'), isNotNull);
    });

    test('returns error for empty confirmation', () {
      expect(Validators.confirmPassword('', 'password'), isNotNull);
    });

    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('mypass', 'mypass'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('returns error for empty name', () {
      expect(Validators.displayName(''), isNotNull);
    });

    test('returns error for single character', () {
      expect(Validators.displayName('A'), isNotNull);
    });

    test('returns null for valid name', () {
      expect(Validators.displayName('John'), isNull);
    });
  });

  group('Validators.getPasswordStrength', () {
    test('weak for short passwords', () {
      expect(Validators.getPasswordStrength('12345'), PasswordStrength.weak);
    });

    test('medium for moderate passwords', () {
      expect(Validators.getPasswordStrength('Abcdefgh'),
          PasswordStrength.medium);
    });

    test('strong for complex passwords', () {
      expect(Validators.getPasswordStrength('Str0ng!Pass'),
          PasswordStrength.strong);
    });
  });
}
