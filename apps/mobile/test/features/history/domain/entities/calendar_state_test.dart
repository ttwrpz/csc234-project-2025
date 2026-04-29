import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/history/domain/entities/calendar_state.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

void main() {
  group('CalendarState', () {
    test('isEmpty is true when dotsByDay is empty', () {
      final state = CalendarState(
        month: DateTime(2026, 4, 1),
        dotsByDay: const {},
      );
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty is false when at least one day has a dot', () {
      final day = DateTime(2026, 4, 12);
      final state = CalendarState(
        month: DateTime(2026, 4, 1),
        dotsByDay: {
          day: DayDot(
            day: day,
            dominantCategory: MoodCategory.positive,
            totalEntries: 1,
            mostRecentEntryId: 'e1',
          ),
        },
      );
      expect(state.isEmpty, isFalse);
    });

    test('two states with the same shape compare equal (Freezed eq)', () {
      final day = DateTime(2026, 4, 12);
      final a = CalendarState(
        month: DateTime(2026, 4, 1),
        dotsByDay: {
          day: DayDot(
            day: day,
            dominantCategory: MoodCategory.positive,
            totalEntries: 1,
            mostRecentEntryId: 'e1',
          ),
        },
      );
      final b = CalendarState(
        month: DateTime(2026, 4, 1),
        dotsByDay: {
          day: DayDot(
            day: day,
            dominantCategory: MoodCategory.positive,
            totalEntries: 1,
            mostRecentEntryId: 'e1',
          ),
        },
      );
      expect(a, equals(b));
    });
  });

  group('DayDot', () {
    test('two dots with the same fields compare equal', () {
      final day = DateTime(2026, 4, 12);
      final a = DayDot(
        day: day,
        dominantCategory: MoodCategory.negativeStrong,
        totalEntries: 3,
        mostRecentEntryId: 'e9',
      );
      final b = DayDot(
        day: day,
        dominantCategory: MoodCategory.negativeStrong,
        totalEntries: 3,
        mostRecentEntryId: 'e9',
      );
      expect(a, equals(b));
    });

    test('differing entry id breaks equality', () {
      final day = DateTime(2026, 4, 12);
      final a = DayDot(
        day: day,
        dominantCategory: MoodCategory.positive,
        totalEntries: 1,
        mostRecentEntryId: 'e1',
      );
      final b = DayDot(
        day: day,
        dominantCategory: MoodCategory.positive,
        totalEntries: 1,
        mostRecentEntryId: 'e2',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
