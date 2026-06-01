import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/biometric_capability.dart';

void main() {
  group('BiometricCapability', () {
    BiometricCapability cap({
      required bool a,
      required bool e,
      required bool o,
    }) {
      return BiometricCapability(
        isAvailable: a,
        hasEnrolledBiometrics: e,
        userOptedIn: o,
      );
    }

    test('shouldGate truth table - all 8 combinations', () {
      // Only the all-true row gates.
      expect(cap(a: true, e: true, o: true).shouldGate, isTrue);

      // Any single false flips shouldGate off.
      expect(cap(a: false, e: true, o: true).shouldGate, isFalse);
      expect(cap(a: true, e: false, o: true).shouldGate, isFalse);
      expect(cap(a: true, e: true, o: false).shouldGate, isFalse);

      // Two falses still false.
      expect(cap(a: false, e: false, o: true).shouldGate, isFalse);
      expect(cap(a: false, e: true, o: false).shouldGate, isFalse);
      expect(cap(a: true, e: false, o: false).shouldGate, isFalse);

      // All false.
      expect(cap(a: false, e: false, o: false).shouldGate, isFalse);
    });

    test('Freezed equality - same values are ==', () {
      const a = BiometricCapability(
        isAvailable: true,
        hasEnrolledBiometrics: true,
        userOptedIn: false,
      );
      const b = BiometricCapability(
        isAvailable: true,
        hasEnrolledBiometrics: true,
        userOptedIn: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Freezed inequality - differing user opt-in is !=', () {
      const a = BiometricCapability(
        isAvailable: true,
        hasEnrolledBiometrics: true,
        userOptedIn: false,
      );
      const b = BiometricCapability(
        isAvailable: true,
        hasEnrolledBiometrics: true,
        userOptedIn: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith - flips userOptedIn without disturbing other fields', () {
      const initial = BiometricCapability(
        isAvailable: true,
        hasEnrolledBiometrics: true,
        userOptedIn: false,
      );
      final updated = initial.copyWith(userOptedIn: true);
      expect(updated.shouldGate, isTrue);
      expect(updated.isAvailable, isTrue);
      expect(updated.hasEnrolledBiometrics, isTrue);
    });
  });
}
