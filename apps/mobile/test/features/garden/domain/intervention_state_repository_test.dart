import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/intervention_state_repository.dart';

/// The [InterventionStateRepository] interface is pure-Dart with no
/// observable behaviour beyond the value types it composes. The data-
/// layer impl carries the interesting logic and is tested separately.
/// These tests cover the value types so future refactors don't drift the
/// `==` / `copyWith` semantics that callers (and the impl mirroring
/// step) depend on.
void main() {
  group('InterventionAnchors', () {
    test('default constructor → both fields null', () {
      const a = InterventionAnchors();
      expect(a.lastTriggeredAt, isNull);
      expect(a.firstTriggeredAt, isNull);
    });

    test('equality + hashCode honour both fields', () {
      final t1 = DateTime(2026, 5, 1);
      final t2 = DateTime(2026, 5, 2);

      expect(
        InterventionAnchors(lastTriggeredAt: t1, firstTriggeredAt: t2) ==
            InterventionAnchors(lastTriggeredAt: t1, firstTriggeredAt: t2),
        isTrue,
      );
      expect(
        InterventionAnchors(lastTriggeredAt: t1).hashCode ==
            InterventionAnchors(lastTriggeredAt: t1).hashCode,
        isTrue,
      );
      expect(
        InterventionAnchors(lastTriggeredAt: t1) ==
            InterventionAnchors(lastTriggeredAt: t2),
        isFalse,
      );
    });

    test('copyWith with nulls leaves both fields unchanged', () {
      final t = DateTime(2026, 5, 1);
      final original = InterventionAnchors(lastTriggeredAt: t);
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('copyWith with a new last preserves first', () {
      final last = DateTime(2026, 5, 1);
      final first = DateTime(2026, 4, 25);
      final original = InterventionAnchors(
        lastTriggeredAt: last,
        firstTriggeredAt: first,
      );
      final newer = DateTime(2026, 5, 2);
      final copy = original.copyWith(lastTriggeredAt: newer);
      expect(copy.lastTriggeredAt, equals(newer));
      expect(copy.firstTriggeredAt, equals(first));
    });

    test('withClearedFirst nulls firstTriggeredAt and preserves last', () {
      final last = DateTime(2026, 5, 1);
      final first = DateTime(2026, 4, 25);
      final original = InterventionAnchors(
        lastTriggeredAt: last,
        firstTriggeredAt: first,
      );
      final cleared = original.withClearedFirst();
      expect(cleared.lastTriggeredAt, equals(last));
      expect(cleared.firstTriggeredAt, isNull);
    });
  });

  group('InterventionStateFailure', () {
    test('factories produce sealed sub-types with safe messages', () {
      const network = InterventionStateFailure.network();
      const permission = InterventionStateFailure.permission();
      const unknown = InterventionStateFailure.unknown('boom');

      // Messages must never include PII; they are operator-facing only.
      expect(network.message, equals('Network unavailable.'));
      expect(permission.message, equals('Permission denied.'));
      expect(unknown.message, equals('Something went wrong.'));
    });

    test('exhaustive switch compiles and matches each variant', () {
      String label(InterventionStateFailure f) => switch (f) {
        _ when f.message == 'Network unavailable.' => 'network',
        _ when f.message == 'Permission denied.' => 'permission',
        _ => 'unknown',
      };

      expect(label(const InterventionStateFailure.network()), 'network');
      expect(label(const InterventionStateFailure.permission()), 'permission');
      expect(label(const InterventionStateFailure.unknown(null)), 'unknown');
    });
  });
}
