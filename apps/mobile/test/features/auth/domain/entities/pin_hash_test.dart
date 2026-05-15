import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/domain/entities/pin_hash.dart';

void main() {
  group('PinHash', () {
    PinHash _hash({
      String algorithm = 'pbkdf2-sha256',
      int iterations = 100000,
      String saltBase64 = 'AAAA',
      String hashBase64 = 'BBBB',
      DateTime? createdAt,
      int failedAttempts = 0,
      DateTime? lockedUntil,
    }) {
      return PinHash(
        algorithm: algorithm,
        iterations: iterations,
        saltBase64: saltBase64,
        hashBase64: hashBase64,
        createdAt: createdAt ?? DateTime.utc(2026, 5, 14),
        failedAttempts: failedAttempts,
        lockedUntil: lockedUntil,
      );
    }

    test('default failedAttempts is 0 and lockedUntil is null', () {
      final hash = PinHash(
        algorithm: 'pbkdf2-sha256',
        iterations: 100000,
        saltBase64: 'AAAA',
        hashBase64: 'BBBB',
        createdAt: DateTime.utc(2026, 5, 14),
      );
      expect(hash.failedAttempts, 0);
      expect(hash.lockedUntil, isNull);
    });

    test('Freezed equality — same values are ==', () {
      final a = _hash();
      final b = _hash();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Freezed inequality — differing iterations is !=', () {
      final a = _hash(iterations: 100000);
      final b = _hash(iterations: 200000);
      expect(a, isNot(equals(b)));
    });

    test('roundtrips through JSON', () {
      final lock = DateTime.utc(2026, 5, 14, 12, 30);
      final hash = _hash(
        failedAttempts: 3,
        lockedUntil: lock,
      );
      final json = hash.toJson();
      final restored = PinHash.fromJson(json);
      expect(restored, equals(hash));
    });

    test('copyWith updates only the named field', () {
      final original = _hash();
      final updated = original.copyWith(failedAttempts: 5);
      expect(updated.failedAttempts, 5);
      expect(updated.iterations, original.iterations);
      expect(updated.saltBase64, original.saltBase64);
    });
  });
}
