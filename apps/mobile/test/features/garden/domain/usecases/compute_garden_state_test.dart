import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/garden_state.dart';
import 'package:moodbloom/features/garden/domain/usecases/compute_garden_state.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

/// Helper: build a `MoodEntry` with the minimum required fields. The garden
/// only consumes `mood` and `createdAt`, so id/userId/text/intensity are
/// fixed.
MoodEntry _entry({
  required MoodType mood,
  required DateTime createdAt,
  int intensity = 3,
  String id = 'e',
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
  const useCase = ComputeGardenStateUseCase();

  // Pin "today" to a concrete local date for determinism. Using local-zone
  // DateTime (not UTC) so the use case's `.toLocal()` is a no-op and tests
  // are stable across CI machines.
  final now = DateTime(2026, 4, 29, 10, 30); // Wed Apr 29, 10:30 local
  final today = DateTime(2026, 4, 29);
  final yesterday = today.subtract(const Duration(days: 1));
  final twoDaysAgo = today.subtract(const Duration(days: 2));
  final eightDaysAgo = today.subtract(const Duration(days: 8));

  group('ComputeGardenStateUseCase', () {
    test('empty entries → zero counts and 7 empty days', () {
      final result = useCase(entries: const [], now: now);

      expect(result.positiveMoodCount, 0);
      expect(result.currentStreakDays, 0);
      expect(result.last7Days, hasLength(7));
      expect(
        result.last7Days.every((d) => d.kind == DayBloomKind.empty),
        isTrue,
      );
      expect(result.isEmpty, isTrue);
    });

    test('one happy entry today → count 1, streak 1, today is bloom', () {
      final result = useCase(
        entries: [_entry(mood: MoodType.happy, createdAt: now)],
        now: now,
      );

      expect(result.positiveMoodCount, 1);
      expect(result.currentStreakDays, 1);
      expect(result.last7Days.first.kind, DayBloomKind.bloom);
      expect(result.last7Days.first.day, today);
      // Remaining 6 cells stay empty.
      expect(
        result.last7Days.skip(1).every((d) => d.kind == DayBloomKind.empty),
        isTrue,
      );
    });

    test('three positive days in a row ending today → streak 3', () {
      final result = useCase(
        entries: [
          _entry(mood: MoodType.happy, createdAt: now),
          _entry(
            mood: MoodType.calm,
            createdAt: yesterday.add(const Duration(hours: 9)),
          ),
          _entry(
            mood: MoodType.happy,
            createdAt: twoDaysAgo.add(const Duration(hours: 18)),
          ),
        ],
        now: now,
      );

      expect(result.currentStreakDays, 3);
      expect(result.positiveMoodCount, 3);
      // Last 7 days: today, yesterday, twoDaysAgo are bloom; rest empty.
      expect(result.last7Days[0].kind, DayBloomKind.bloom);
      expect(result.last7Days[1].kind, DayBloomKind.bloom);
      expect(result.last7Days[2].kind, DayBloomKind.bloom);
      expect(result.last7Days[3].kind, DayBloomKind.empty);
    });

    test('gap in middle: today positive, yesterday missing, two-days-ago '
        'positive → streak 1 (chain breaks at yesterday)', () {
      final result = useCase(
        entries: [
          _entry(mood: MoodType.happy, createdAt: now),
          _entry(
            mood: MoodType.happy,
            createdAt: twoDaysAgo.add(const Duration(hours: 12)),
          ),
        ],
        now: now,
      );

      expect(result.currentStreakDays, 1);
      expect(result.last7Days[0].kind, DayBloomKind.bloom);
      expect(result.last7Days[1].kind, DayBloomKind.empty);
      expect(result.last7Days[2].kind, DayBloomKind.bloom);
    });

    test(
      'today missing but historical positives exist → streak 0 (silent break)',
      () {
        final result = useCase(
          entries: [
            _entry(mood: MoodType.happy, createdAt: yesterday),
            _entry(mood: MoodType.happy, createdAt: twoDaysAgo),
          ],
          now: now,
        );

        expect(result.currentStreakDays, 0);
        expect(result.positiveMoodCount, 2);
      },
    );

    test('negative-only history → count 0, streak 0, all 7 days empty', () {
      final result = useCase(
        entries: [
          _entry(mood: MoodType.sad, createdAt: now),
          _entry(mood: MoodType.angry, createdAt: yesterday),
          _entry(mood: MoodType.anxious, createdAt: twoDaysAgo),
          _entry(mood: MoodType.okay, createdAt: yesterday),
        ],
        now: now,
      );

      expect(result.positiveMoodCount, 0);
      expect(result.currentStreakDays, 0);
      expect(
        result.last7Days.every((d) => d.kind == DayBloomKind.empty),
        isTrue,
        reason: 'S3 does not visualise negatives; that is S4 scope.',
      );
      expect(result.isEmpty, isTrue);
    });

    test('mixed positive + negative on the same day → that day blooms', () {
      final result = useCase(
        entries: [
          _entry(mood: MoodType.sad, createdAt: now),
          _entry(
            mood: MoodType.happy,
            createdAt: now.add(const Duration(hours: 1)),
          ),
        ],
        now: now,
      );

      expect(result.last7Days.first.kind, DayBloomKind.bloom);
      expect(result.positiveMoodCount, 1);
      expect(result.currentStreakDays, 1);
    });

    test(
      'entry from 8 days ago → counted overall, NOT in last7Days window',
      () {
        final result = useCase(
          entries: [_entry(mood: MoodType.happy, createdAt: eightDaysAgo)],
          now: now,
        );

        expect(result.positiveMoodCount, 1);
        expect(result.currentStreakDays, 0);
        expect(
          result.last7Days.every((d) => d.kind == DayBloomKind.empty),
          isTrue,
          reason: '8 days ago is outside the 7-cell window.',
        );
      },
    );

    test(
      'entry created at 23:59 local time today still counts toward today',
      () {
        // The test runs in the host's local TZ; since we already build `now`
        // in local time, an "edge of day" entry at 23:59 local should bucket
        // into the same day as `now`.
        final lateToday = DateTime(2026, 4, 29, 23, 59, 30);
        final result = useCase(
          entries: [_entry(mood: MoodType.happy, createdAt: lateToday)],
          now: now,
        );

        expect(result.last7Days.first.kind, DayBloomKind.bloom);
        expect(result.currentStreakDays, 1);
      },
    );

    test('last7Days is always exactly 7 cells, newest first', () {
      final result = useCase(entries: const [], now: now);
      expect(result.last7Days, hasLength(7));
      // Newest first: index 0 is today, index 6 is six days ago.
      expect(result.last7Days[0].day, today);
      expect(result.last7Days[6].day, today.subtract(const Duration(days: 6)));
    });

    test('happy and calm both count as positive (category mapping)', () {
      // Defense check: if MoodCategory.positive ever expands beyond
      // happy+calm we want this test to flag the change.
      final result = useCase(
        entries: [
          _entry(mood: MoodType.happy, createdAt: now),
          _entry(mood: MoodType.calm, createdAt: now),
        ],
        now: now,
      );
      expect(result.positiveMoodCount, 2);
    });
  });
}
