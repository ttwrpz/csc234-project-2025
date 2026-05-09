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

    test(
      'mostly-negative history (S4) → wilting/rain cells, streak still 0',
      () {
        // Sprint 4 reframing: negatives (sad/angry/anxious) surface as
        // wilting (i ≤ 3) or rainCloud (i ≥ 4) cells. Per ADR-0010,
        // `okay` was reclassified to positive, so the okay@1 entry on
        // `yesterday` now contributes a bloom on that day (and bloom wins
        // over the same-day rain). The streak counter remains positive-
        // only (regression guard against streak-shaming) — today has no
        // positive entry, so the streak is still 0.
        final result = useCase(
          entries: [
            _entry(mood: MoodType.sad, createdAt: now, intensity: 2), // wilt
            _entry(
              mood: MoodType.angry,
              createdAt: yesterday,
              intensity: 5,
            ), // rain
            _entry(
              mood: MoodType.anxious,
              createdAt: twoDaysAgo,
              intensity: 4,
            ), // rain
            _entry(
              mood: MoodType.okay,
              createdAt: yesterday,
              intensity: 1,
            ), // bloom (ADR-0010: okay is positive)
          ],
          now: now,
        );

        expect(result.positiveMoodCount, 1);
        expect(result.wiltingMoodCount, 1);
        expect(result.rainCloudMoodCount, 2);
        expect(result.currentStreakDays, 0);
        expect(result.last7Days[0].kind, DayBloomKind.wilting);
        expect(
          result.last7Days[1].kind,
          DayBloomKind.bloom,
          reason: 'Day with bloom + rain → bloom wins (priority).',
        );
        expect(result.last7Days[2].kind, DayBloomKind.rainCloud);
        expect(result.isEmpty, isFalse);
      },
    );

    test('mixed positive + negative on the same day → that day blooms', () {
      // Day-priority `bloom > rainCloud > wilting > empty` (ADR-0006).
      final result = useCase(
        entries: [
          _entry(mood: MoodType.sad, createdAt: now, intensity: 5), // rain
          _entry(
            mood: MoodType.happy,
            createdAt: now.add(const Duration(hours: 1)),
          ),
        ],
        now: now,
      );

      expect(result.last7Days.first.kind, DayBloomKind.bloom);
      expect(result.positiveMoodCount, 1);
      expect(result.rainCloudMoodCount, 1);
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

    // ───── S4 (ADR-0006): compassionate reframing ─────

    test('kind() table: every (MoodType × intensity 1..5)', () {
      // Pure rule: positives → bloom regardless of intensity; negatives
      // split on user-felt intensity (≤3 wilting, ≥4 rainCloud). Per
      // ADR-0010, `okay` is part of the positive bucket, so it always
      // blooms regardless of intensity.
      final expected = <(MoodType, int), DayBloomKind>{
        // Positives — always bloom.
        for (final i in [1, 2, 3, 4, 5]) ...{
          (MoodType.happy, i): DayBloomKind.bloom,
          (MoodType.calm, i): DayBloomKind.bloom,
          (MoodType.okay, i): DayBloomKind.bloom,
        },
        // Negatives — intensity-based.
        for (final m in [MoodType.sad, MoodType.angry, MoodType.anxious]) ...{
          (m, 1): DayBloomKind.wilting,
          (m, 2): DayBloomKind.wilting,
          (m, 3): DayBloomKind.wilting,
          (m, 4): DayBloomKind.rainCloud,
          (m, 5): DayBloomKind.rainCloud,
        },
      };

      for (final entry in expected.entries) {
        final (mood, intensity) = entry.key;
        expect(
          ComputeGardenStateUseCase.kind(mood, intensity),
          entry.value,
          reason: 'kind(${mood.name}, $intensity) should be ${entry.value}',
        );
      }
    });

    test('intensity boundary: sad@3 wilts, sad@4 rains', () {
      expect(
        ComputeGardenStateUseCase.kind(MoodType.sad, 3),
        DayBloomKind.wilting,
      );
      expect(
        ComputeGardenStateUseCase.kind(MoodType.sad, 4),
        DayBloomKind.rainCloud,
      );
    });

    test('intensity is clamped defensively to [1, 5]', () {
      // Out-of-range intensity (should never happen — MoodEntry validates)
      // is clamped rather than crashing. 0 → wilting, 99 → rainCloud.
      expect(
        ComputeGardenStateUseCase.kind(MoodType.sad, 0),
        DayBloomKind.wilting,
      );
      expect(
        ComputeGardenStateUseCase.kind(MoodType.sad, 99),
        DayBloomKind.rainCloud,
      );
    });

    test('day priority: only wilting on a day → wilting cell', () {
      final result = useCase(
        entries: [_entry(mood: MoodType.sad, createdAt: now, intensity: 2)],
        now: now,
      );
      expect(result.last7Days[0].kind, DayBloomKind.wilting);
      expect(result.wiltingMoodCount, 1);
      expect(result.rainCloudMoodCount, 0);
    });

    test('day priority: wilting + rainCloud on a day → rainCloud cell', () {
      final result = useCase(
        entries: [
          _entry(mood: MoodType.sad, createdAt: now, intensity: 2), // wilt
          _entry(
            mood: MoodType.angry,
            createdAt: now.add(const Duration(hours: 2)),
            intensity: 5,
          ), // rain
        ],
        now: now,
      );
      expect(result.last7Days[0].kind, DayBloomKind.rainCloud);
      expect(result.wiltingMoodCount, 1);
      expect(result.rainCloudMoodCount, 1);
    });

    test(
      'streak regression: negatives between positives do NOT extend streak',
      () {
        // today positive, yesterday negative-only, twoDaysAgo positive.
        // Streak must still break at yesterday — wilting/rain days are
        // intentionally NOT streak-eligible (no streak-shaming, no
        // streak-rewarding negatives either).
        final result = useCase(
          entries: [
            _entry(mood: MoodType.happy, createdAt: now),
            _entry(mood: MoodType.sad, createdAt: yesterday, intensity: 5),
            _entry(mood: MoodType.happy, createdAt: twoDaysAgo),
          ],
          now: now,
        );
        expect(result.currentStreakDays, 1);
        expect(result.last7Days[1].kind, DayBloomKind.rainCloud);
      },
    );

    test('isEmpty is false when only wilting entries exist', () {
      final result = useCase(
        entries: [_entry(mood: MoodType.sad, createdAt: now, intensity: 1)],
        now: now,
      );
      expect(result.isEmpty, isFalse);
    });
  });
}
