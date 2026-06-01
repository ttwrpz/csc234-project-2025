import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_balance.dart';

void main() {
  group('TokenBalance JSON round-trip', () {
    test('full state with non-null lastEarnedDate', () {
      final original = TokenBalance(
        balance: 47,
        earnedToday: 8,
        lastEarnedDate: DateTime.utc(2026, 5, 12),
      );

      final json = original.toJson();
      final decoded = TokenBalance.fromJson(json);

      expect(decoded.balance, 47);
      expect(decoded.earnedToday, 8);
      expect(decoded.lastEarnedDate, DateTime.utc(2026, 5, 12));
    });

    test('null lastEarnedDate (fresh user - never earned)', () {
      const original = TokenBalance(
        balance: 0,
        earnedToday: 0,
        lastEarnedDate: null,
      );

      final json = original.toJson();
      final decoded = TokenBalance.fromJson(json);

      expect(decoded.balance, 0);
      expect(decoded.earnedToday, 0);
      expect(decoded.lastEarnedDate, isNull);
    });

    test('JSON keys match Firestore field names', () {
      // The datasource writes to `tokenBalance / tokensEarnedToday /
      // lastTokenEarnedDate` directly via `tx.update`, NOT via
      // `toJson` - but if a future refactor wires JSON through to
      // Firestore, the keys must NOT collide with the user-doc
      // monotonic-up rule (which pins `tokenBalance`). The Freezed-
      // generated keys are the field names, so this acts as a
      // canary.
      final json = TokenBalance(
        balance: 1,
        earnedToday: 2,
        lastEarnedDate: DateTime.utc(2026, 5, 12),
      ).toJson();
      expect(json.keys, containsAll(<String>['balance', 'earnedToday']));
    });
  });
}
