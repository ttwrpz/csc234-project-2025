import 'package:flutter_test/flutter_test.dart';
import 'package:user_centric_mobile_app/utils/date_helpers.dart';

void main() {
  group('DateHelpers.formatFull', () {
    test('formats date correctly', () {
      final date = DateTime(2026, 4, 15, 15, 42);
      final result = DateHelpers.formatFull(date);
      expect(result, contains('April'));
      expect(result, contains('15'));
      expect(result, contains('2026'));
    });
  });

  group('DateHelpers.formatShort', () {
    test('formats short date', () {
      final date = DateTime(2026, 4, 15);
      final result = DateHelpers.formatShort(date);
      expect(result, contains('Apr'));
      expect(result, contains('15'));
    });
  });

  group('DateHelpers.isSameDay', () {
    test('returns true for same day', () {
      final a = DateTime(2026, 4, 15, 10, 30);
      final b = DateTime(2026, 4, 15, 22, 0);
      expect(DateHelpers.isSameDay(a, b), isTrue);
    });

    test('returns false for different days', () {
      final a = DateTime(2026, 4, 15);
      final b = DateTime(2026, 4, 16);
      expect(DateHelpers.isSameDay(a, b), isFalse);
    });
  });

  group('DateHelpers.calculateStreak', () {
    test('returns 0 for empty list', () {
      expect(DateHelpers.calculateStreak([]), 0);
    });

    test('returns 1 for today only', () {
      final today = DateTime.now();
      expect(DateHelpers.calculateStreak([today]), 1);
    });

    test('returns correct streak for consecutive days', () {
      final now = DateTime.now();
      final dates = [
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 2)),
      ];
      expect(DateHelpers.calculateStreak(dates), 3);
    });

    test('returns 0 if streak is broken (no today or yesterday)', () {
      final dates = [
        DateTime.now().subtract(const Duration(days: 3)),
        DateTime.now().subtract(const Duration(days: 4)),
      ];
      expect(DateHelpers.calculateStreak(dates), 0);
    });

    test('handles duplicate dates on same day', () {
      final now = DateTime.now();
      final dates = [
        now,
        now.subtract(const Duration(hours: 3)),
        now.subtract(const Duration(days: 1)),
      ];
      expect(DateHelpers.calculateStreak(dates), 2);
    });
  });

  group('DateHelpers.getGreeting', () {
    test('returns a non-empty greeting', () {
      final greeting = DateHelpers.getGreeting();
      expect(greeting, isNotEmpty);
      expect(
        ['Good morning', 'Good afternoon', 'Good evening'],
        contains(greeting),
      );
    });
  });

  group('DateHelpers.getWeekDays', () {
    test('returns 7 days', () {
      expect(DateHelpers.getWeekDays().length, 7);
    });

    test('starts on Monday', () {
      final days = DateHelpers.getWeekDays();
      expect(days.first.weekday, DateTime.monday);
    });
  });
}
