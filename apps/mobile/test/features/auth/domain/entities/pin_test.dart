import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/pin.dart';

void main() {
  group('Pin.tryFrom', () {
    test('accepts exactly 6 ASCII digits', () {
      final pin = Pin.tryFrom('123456');
      expect(pin, isNotNull);
      expect(pin!.digits, '123456');
    });

    test('rejects fewer than 6 digits', () {
      expect(Pin.tryFrom(''), isNull);
      expect(Pin.tryFrom('1'), isNull);
      expect(Pin.tryFrom('12345'), isNull);
    });

    test('rejects more than 6 digits', () {
      expect(Pin.tryFrom('1234567'), isNull);
      expect(Pin.tryFrom('1234567890'), isNull);
    });

    test('rejects 6-char strings with non-digit characters', () {
      expect(Pin.tryFrom('12345a'), isNull);
      expect(Pin.tryFrom('abcdef'), isNull);
      expect(Pin.tryFrom('12345 '), isNull);
      expect(Pin.tryFrom('1234.5'), isNull);
    });

    test('does NOT trim whitespace — UI owns input shaping', () {
      // A user pasting " 12345" should not be silently accepted as
      // valid; we let the UI fix that explicitly.
      expect(Pin.tryFrom(' 12345'), isNull);
      expect(Pin.tryFrom('12345 '), isNull);
    });

    test('accepts edge digits (all zeros, all nines)', () {
      expect(Pin.tryFrom('000000'), isNotNull);
      expect(Pin.tryFrom('999999'), isNotNull);
    });
  });

  group('Pin equality + toString', () {
    test('equal digits compare equal', () {
      final a = Pin.tryFrom('123456')!;
      final b = Pin.tryFrom('123456')!;
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different digits compare unequal', () {
      final a = Pin.tryFrom('123456')!;
      final b = Pin.tryFrom('654321')!;
      expect(a, isNot(equals(b)));
    });

    test('toString never leaks the digits', () {
      final pin = Pin.tryFrom('123456')!;
      final str = pin.toString();
      expect(str, isNot(contains('123456')));
      expect(str, equals('Pin(***)'));
    });
  });

  group('Pin.unchecked', () {
    test('skips validation for test fixtures', () {
      // Intentionally bypassing — confirms the escape hatch exists
      // for fixture construction. Production should always use
      // `tryFrom`.
      const bypassed = Pin.unchecked('not-a-real-pin');
      expect(bypassed.digits, 'not-a-real-pin');
    });
  });
}
