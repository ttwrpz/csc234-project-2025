import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/notifications/domain/daily_check_in_schedule.dart';

void main() {
  group('DailyCheckInSchedule.nextOccurrenceAfter', () {
    const schedule = DailyCheckInSchedule(enabled: true, hour: 21, minute: 30);

    test('rolls to today when the target time is later today', () {
      final from = DateTime(2026, 5, 27, 9, 0);
      final next = schedule.nextOccurrenceAfter(from);
      expect(next, DateTime(2026, 5, 27, 21, 30));
    });

    test('rolls to tomorrow when the target time already passed today', () {
      final from = DateTime(2026, 5, 27, 22, 0);
      final next = schedule.nextOccurrenceAfter(from);
      expect(next, DateTime(2026, 5, 28, 21, 30));
    });

    test('rolls to tomorrow when called exactly at the target time', () {
      // At 21:30:00 we roll forward so re-arming on the dot does not fire
      // an immediate duplicate.
      final from = DateTime(2026, 5, 27, 21, 30);
      final next = schedule.nextOccurrenceAfter(from);
      expect(next, DateTime(2026, 5, 28, 21, 30));
    });

    test('one minute before the target stays today', () {
      final from = DateTime(2026, 5, 27, 21, 29);
      final next = schedule.nextOccurrenceAfter(from);
      expect(next, DateTime(2026, 5, 27, 21, 30));
    });

    test('handles a month/year boundary roll-forward', () {
      const newYearsEve = DailyCheckInSchedule(
        enabled: true,
        hour: 0,
        minute: 5,
      );
      final from = DateTime(2026, 12, 31, 23, 59);
      final next = newYearsEve.nextOccurrenceAfter(from);
      expect(next, DateTime(2027, 1, 1, 0, 5));
    });

    test('midnight reminder rolls to tomorrow when already past', () {
      const midnight = DailyCheckInSchedule(enabled: true, hour: 0, minute: 0);
      final from = DateTime(2026, 5, 27, 0, 1);
      final next = midnight.nextOccurrenceAfter(from);
      expect(next, DateTime(2026, 5, 28, 0, 0));
    });
  });

  group('DailyCheckInSchedule value semantics', () {
    test('copyWith overrides only the named fields', () {
      const base = DailyCheckInSchedule(enabled: false, hour: 21, minute: 30);
      expect(
        base.copyWith(enabled: true),
        const DailyCheckInSchedule(enabled: true, hour: 21, minute: 30),
      );
      expect(
        base.copyWith(hour: 8, minute: 0),
        const DailyCheckInSchedule(enabled: false, hour: 8, minute: 0),
      );
    });

    test('equality and hashCode are value-based', () {
      const a = DailyCheckInSchedule(enabled: true, hour: 9, minute: 15);
      const b = DailyCheckInSchedule(enabled: true, hour: 9, minute: 15);
      const c = DailyCheckInSchedule(enabled: true, hour: 9, minute: 16);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('rejects out-of-range hour/minute via assert', () {
      expect(
        () => DailyCheckInSchedule(enabled: true, hour: 24, minute: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DailyCheckInSchedule(enabled: true, hour: 0, minute: 60),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
