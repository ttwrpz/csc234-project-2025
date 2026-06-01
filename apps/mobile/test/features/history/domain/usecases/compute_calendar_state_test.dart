import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/history/domain/usecases/compute_calendar_state.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

MoodEntry _entry({
  required String id,
  required MoodType mood,
  required int intensity,
  required DateTime createdAt,
}) {
  return MoodEntry(
    id: id,
    userId: 'u-1',
    mood: mood,
    intensity: intensity,
    text: '',
    createdAt: createdAt,
  );
}

void main() {
  const useCase = ComputeCalendarStateUseCase();

  group('ComputeCalendarStateUseCase', () {
    test('empty entries → state.isEmpty is true', () {
      final state = useCase(entries: const [], month: DateTime(2026, 4, 15));
      expect(state.isEmpty, isTrue);
      expect(state.month, DateTime(2026, 4, 1));
    });

    test('one happy entry today is dominant positive with 1 total', () {
      final today = DateTime(2026, 4, 15, 9, 30);
      final state = useCase(
        entries: [
          _entry(
            id: 'e1',
            mood: MoodType.happy,
            intensity: 4,
            createdAt: today,
          ),
        ],
        month: today,
      );
      final key = DateTime(2026, 4, 15);
      final dot = state.dotsByDay[key];
      expect(dot, isNotNull);
      expect(dot!.dominantCategory, MoodCategory.positive);
      expect(dot.totalEntries, 1);
      expect(dot.mostRecentEntryId, 'e1');
    });

    test('two same-day entries - higher intensity wins category, '
        'most-recent wins id', () {
      final morning = DateTime(2026, 4, 12, 8, 0);
      final evening = DateTime(2026, 4, 12, 20, 0);
      final state = useCase(
        entries: [
          _entry(
            id: 'morning',
            mood: MoodType.happy, // positive, intensity 3
            intensity: 3,
            createdAt: morning,
          ),
          _entry(
            id: 'evening',
            mood: MoodType.angry, // negativeStrong, intensity 5
            intensity: 5,
            createdAt: evening,
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      final dot = state.dotsByDay[DateTime(2026, 4, 12)]!;
      expect(dot.dominantCategory, MoodCategory.negativeStrong);
      expect(dot.totalEntries, 2);
      expect(dot.mostRecentEntryId, 'evening');
    });

    test('intensity tie → most-recent entry wins both id and category', () {
      final earlier = DateTime(2026, 4, 10, 9, 0);
      final later = DateTime(2026, 4, 10, 21, 0);
      final state = useCase(
        entries: [
          _entry(
            id: 'earlier',
            mood: MoodType.happy, // positive
            intensity: 4,
            createdAt: earlier,
          ),
          _entry(
            id: 'later',
            mood: MoodType.anxious, // negativeStrong
            intensity: 4,
            createdAt: later,
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      final dot = state.dotsByDay[DateTime(2026, 4, 10)]!;
      expect(dot.mostRecentEntryId, 'later');
      expect(
        dot.dominantCategory,
        MoodCategory.negativeStrong,
        reason: 'on intensity tie, most-recent entry sets the category',
      );
    });

    test('entry from a different month is not in dotsByDay', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'march',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 3, 20, 12),
          ),
          _entry(
            id: 'april',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 5, 12),
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      expect(state.dotsByDay, hasLength(1));
      expect(state.dotsByDay[DateTime(2026, 4, 5)], isNotNull);
      expect(state.dotsByDay[DateTime(2026, 3, 20)], isNull);
    });

    test('late-night entry (23:59 local) belongs to its own day key', () {
      final lateNight = DateTime(2026, 4, 18, 23, 59);
      final state = useCase(
        entries: [
          _entry(
            id: 'late',
            mood: MoodType.calm,
            intensity: 2,
            createdAt: lateNight,
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      expect(state.dotsByDay[DateTime(2026, 4, 18)], isNotNull);
      // The next day must NOT have a dot.
      expect(state.dotsByDay[DateTime(2026, 4, 19)], isNull);
    });

    test('mixed positive + negativeStrong same day → dominantCategory '
        'follows highest intensity', () {
      final day = DateTime(2026, 4, 7);
      final state = useCase(
        entries: [
          _entry(
            id: 'happy-mild',
            mood: MoodType.happy, // positive
            intensity: 2,
            createdAt: day.add(const Duration(hours: 9)),
          ),
          _entry(
            id: 'angry-strong',
            mood: MoodType.angry, // negativeStrong
            intensity: 5,
            createdAt: day.add(const Duration(hours: 10)),
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      expect(
        state.dotsByDay[day]!.dominantCategory,
        MoodCategory.negativeStrong,
      );
    });

    test('entries scattered across the month each get their own DayDot', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'd2',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 2, 10),
          ),
          _entry(
            id: 'd10',
            mood: MoodType.calm,
            intensity: 2,
            createdAt: DateTime(2026, 4, 10, 11),
          ),
          _entry(
            id: 'd25',
            mood: MoodType.sad,
            intensity: 4,
            createdAt: DateTime(2026, 4, 25, 12),
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      expect(state.dotsByDay, hasLength(3));
      expect(state.dotsByDay[DateTime(2026, 4, 2)]!.mostRecentEntryId, 'd2');
      expect(state.dotsByDay[DateTime(2026, 4, 10)]!.mostRecentEntryId, 'd10');
      expect(state.dotsByDay[DateTime(2026, 4, 25)]!.mostRecentEntryId, 'd25');
    });

    test('month is normalised to first-of-month local midnight', () {
      final state = useCase(
        entries: const [],
        month: DateTime(2026, 4, 18, 14, 32, 11),
      );
      expect(state.month, DateTime(2026, 4, 1));
    });

    test('entry on the first day of the requested month is included', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'first',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 1, 0, 5),
          ),
        ],
        month: DateTime(2026, 4, 15),
      );
      expect(state.dotsByDay[DateTime(2026, 4, 1)], isNotNull);
    });

    test('entry on the last day of the requested month is included', () {
      // April has 30 days.
      final state = useCase(
        entries: [
          _entry(
            id: 'last',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 30, 23, 30),
          ),
        ],
        month: DateTime(2026, 4, 1),
      );
      expect(state.dotsByDay[DateTime(2026, 4, 30)], isNotNull);
    });
  });
}
