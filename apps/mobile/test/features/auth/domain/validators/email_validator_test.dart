import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/validators/email_validator.dart';

void main() {
  group('emailIsValid', () {
    test('rejects empty string', () {
      expect(emailIsValid(''), isFalse);
    });

    test('rejects whitespace-only string', () {
      expect(emailIsValid('   '), isFalse);
    });

    test('rejects string without @', () {
      expect(emailIsValid('plainaddress'), isFalse);
    });

    test('rejects string with @ at start', () {
      expect(emailIsValid('@example.com'), isFalse);
    });

    test('rejects string with @ at end', () {
      expect(emailIsValid('user@'), isFalse);
    });

    test('rejects string with multiple @', () {
      expect(emailIsValid('a@b@c.com'), isFalse);
    });

    test('accepts a typical email', () {
      expect(emailIsValid('user@example.com'), isTrue);
    });

    test('accepts an email with subdomain', () {
      expect(emailIsValid('user@mail.example.co.th'), isTrue);
    });

    test('rejects an email longer than 254 chars', () {
      final long = '${'a' * 250}@a.io';
      expect(long.length, greaterThan(254));
      expect(emailIsValid(long), isFalse);
    });

    test('trims surrounding whitespace before validating', () {
      expect(emailIsValid('  user@example.com  '), isTrue);
    });
  });
}
