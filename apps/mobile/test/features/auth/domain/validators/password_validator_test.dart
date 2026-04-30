import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/validators/password_validator.dart';

void main() {
  group('passwordIsValid', () {
    test('rejects empty string', () {
      expect(passwordIsValid(''), isFalse);
    });

    test('rejects 7-character password', () {
      expect(passwordIsValid('1234567'), isFalse);
    });

    test('accepts exactly 8 characters', () {
      expect(passwordIsValid('12345678'), isTrue);
    });

    test('accepts long password', () {
      expect(passwordIsValid('a-very-long-and-strong-password'), isTrue);
    });
  });
}
