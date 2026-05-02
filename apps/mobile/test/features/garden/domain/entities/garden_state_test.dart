import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';

void main() {
  group('GardenState', () {
    final today = DateTime(2026, 4, 29);
    final yesterday = today.subtract(const Duration(days: 1));

    GardenState makeState({
      int positiveCount = 0,
      int wiltingCount = 0,
      int rainCloudCount = 0,
      int streak = 0,
    }) => GardenState(
      positiveMoodCount: positiveCount,
      wiltingMoodCount: wiltingCount,
      rainCloudMoodCount: rainCloudCount,
      currentStreakDays: streak,
      last7Days: [
        DayBloom(day: today, kind: DayBloomKind.empty),
        DayBloom(day: yesterday, kind: DayBloomKind.empty),
      ],
    );

    test('isEmpty is true when all three glyph counts are 0', () {
      expect(makeState().isEmpty, isTrue);
    });

    test('isEmpty is false when at least one positive mood is logged', () {
      expect(makeState(positiveCount: 1).isEmpty, isFalse);
    });

    test('isEmpty is false when only wilting entries exist (S4)', () {
      expect(makeState(wiltingCount: 1).isEmpty, isFalse);
    });

    test('isEmpty is false when only rain-cloud entries exist (S4)', () {
      expect(makeState(rainCloudCount: 1).isEmpty, isFalse);
    });

    test('two equal states compare equal (Freezed value equality)', () {
      final a = makeState(positiveCount: 3, streak: 2);
      final b = makeState(positiveCount: 3, streak: 2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith mutates only the named field', () {
      final a = makeState(positiveCount: 3, streak: 2);
      final b = a.copyWith(currentStreakDays: 5);
      expect(b.currentStreakDays, 5);
      expect(b.positiveMoodCount, 3);
      expect(b.last7Days, equals(a.last7Days));
    });
  });

  group('DayBloom', () {
    test('equality is value-based', () {
      final a = DayBloom(day: DateTime(2026, 4, 29), kind: DayBloomKind.bloom);
      final b = DayBloom(day: DateTime(2026, 4, 29), kind: DayBloomKind.bloom);
      expect(a, equals(b));
    });
  });
}
