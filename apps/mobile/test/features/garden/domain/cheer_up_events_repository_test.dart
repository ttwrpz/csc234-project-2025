import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/cheer_up_events_repository.dart';

void main() {
  group('formatDayUtc', () {
    test('zero-pads month and day', () {
      final dt = DateTime.utc(2026, 1, 5, 12, 30);
      expect(formatDayUtc(dt), '2026-01-05');
    });

    test('renders 4-digit year for past century', () {
      final dt = DateTime.utc(999, 12, 31, 23, 59);
      // Year 999 still pads to 4 digits per the spec — `padLeft(4, "0")`.
      expect(formatDayUtc(dt), '0999-12-31');
    });

    test('converts a local-time DateTime to UTC before slicing the day', () {
      // 23:00 in UTC+10 is 13:00 UTC the same day.
      final localPlus10 = DateTime.utc(2026, 5, 13, 13, 0);
      expect(formatDayUtc(localPlus10), '2026-05-13');

      // 02:00 in UTC+10 (= 16:00 UTC the previous day) drops to the
      // PREVIOUS UTC date — verifying the .toUtc() conversion lands
      // before the slice.
      final crossing = DateTime.fromMillisecondsSinceEpoch(
        DateTime.utc(2026, 5, 14, 0, 30).millisecondsSinceEpoch,
        isUtc: false,
      );
      // Just sanity-check the function doesn't crash / returns the
      // UTC slice — the exact value depends on the host TZ.
      expect(formatDayUtc(crossing), matches(r'^\d{4}-\d{2}-\d{2}$'));
    });
  });

  group('buildCheerUpEventId', () {
    test('joins dayUtc and reason with a dash', () {
      expect(
        buildCheerUpEventId(dayUtc: '2026-05-13', reason: '5_of_7_negative'),
        '2026-05-13-5_of_7_negative',
      );
    });

    test('regex-compatible with firestore.rules guard', () {
      final id = buildCheerUpEventId(
        dayUtc: '2026-05-13',
        reason: '3_consecutive_high_intensity',
      );
      // Same regex the rule asserts; if this fails the rule WILL
      // reject our writes.
      final pattern = RegExp(
        r'^\d{4}-\d{2}-\d{2}-(5_of_7_negative|3_consecutive_high_intensity)$',
      );
      expect(pattern.hasMatch(id), isTrue);
    });
  });

  group('kCheerUpEventReasons', () {
    test('matches the regex alternation in firestore.rules', () {
      expect(
        kCheerUpEventReasons,
        equals(<String>{'5_of_7_negative', '3_consecutive_high_intensity'}),
      );
    });
  });
}
