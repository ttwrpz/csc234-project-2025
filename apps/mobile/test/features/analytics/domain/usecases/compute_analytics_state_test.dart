import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/analytics/domain/usecases/compute_analytics_state.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';

MoodEntry _entry({
  required String id,
  required MoodType mood,
  required int intensity,
  required DateTime createdAt,
  String userId = 'u1',
  String text = '',
}) {
  return MoodEntry(
    id: id,
    userId: userId,
    mood: mood,
    intensity: intensity,
    text: text,
    createdAt: createdAt,
  );
}

void main() {
  const useCase = ComputeAnalyticsStateUseCase();
  // Pin "now" to a concrete local-time mid-afternoon so day-boundary tests
  // are unambiguous regardless of the developer machine's TZ.
  final now = DateTime(2026, 4, 29, 15, 30);

  group('ComputeAnalyticsStateUseCase — empty + boundaries', () {
    test(
      'empty entries → state.isEmpty is true; days length matches window',
      () {
        for (final w in MoodWindow.values) {
          final state = useCase(entries: [], window: w, now: now);
          expect(state.isEmpty, isTrue, reason: 'window=$w');
          expect(state.days, hasLength(w.days), reason: 'window=$w');
          for (final d in state.days) {
            expect(d.totalEntries, 0);
            expect(d.meanIntensityByCategory, isEmpty);
          }
        }
      },
    );

    test('days are newest-first', () {
      final state = useCase(entries: [], window: MoodWindow.week, now: now);
      expect(state.days.first.day, DateTime(2026, 4, 29));
      expect(state.days.last.day, DateTime(2026, 4, 23));
    });
  });

  group('ComputeAnalyticsStateUseCase — bucketing', () {
    test('one happy entry today → today positive mean = intensity', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'e1',
            mood: MoodType.happy,
            intensity: 4,
            createdAt: DateTime(2026, 4, 29, 10, 0),
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      expect(state.isEmpty, isFalse);
      expect(state.days.first.totalEntries, 1);
      expect(
        state.days.first.meanIntensityByCategory[MoodCategory.positive],
        4.0,
      );
    });

    test('two happy entries today (intensities 3, 5) → mean 4.0', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'a',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 29, 9),
          ),
          _entry(
            id: 'b',
            mood: MoodType.happy,
            intensity: 5,
            createdAt: DateTime(2026, 4, 29, 13),
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      expect(state.days.first.totalEntries, 2);
      expect(
        state.days.first.meanIntensityByCategory[MoodCategory.positive],
        4.0,
      );
    });

    test(
      'mixed positive + negativeMild same day → both categories present',
      () {
        final state = useCase(
          entries: [
            _entry(
              id: 'a',
              mood: MoodType.calm,
              intensity: 4,
              createdAt: DateTime(2026, 4, 29, 9),
            ),
            _entry(
              id: 'b',
              mood: MoodType.sad,
              intensity: 2,
              createdAt: DateTime(2026, 4, 29, 13),
            ),
          ],
          window: MoodWindow.week,
          now: now,
        );
        final today = state.days.first;
        expect(today.totalEntries, 2);
        expect(today.meanIntensityByCategory[MoodCategory.positive], 4.0);
        expect(today.meanIntensityByCategory[MoodCategory.negativeMild], 2.0);
      },
    );

    test('entry exactly window.days old is OUTSIDE the window', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'edge',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: now.subtract(const Duration(days: 7)),
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      expect(state.isEmpty, isTrue);
    });

    test('entry exactly (window.days - 1) days old is INSIDE the window', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'edge',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 23, 12), // 6 days ago
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      expect(state.isEmpty, isFalse);
      expect(state.days.last.totalEntries, 1); // oldest day in newest-first
    });

    test('30-day-old entry: in 30d window, NOT in 7d window', () {
      final entry = _entry(
        id: 'mid',
        mood: MoodType.happy,
        intensity: 3,
        createdAt: now.subtract(const Duration(days: 14)),
      );
      final week = useCase(entries: [entry], window: MoodWindow.week, now: now);
      final month = useCase(
        entries: [entry],
        window: MoodWindow.month,
        now: now,
      );
      expect(week.isEmpty, isTrue);
      expect(month.isEmpty, isFalse);
    });

    test('late-night entry (23:59 local) belongs to its own day', () {
      // 23:59 on Apr 28 (yesterday relative to now=Apr 29 15:30).
      final state = useCase(
        entries: [
          _entry(
            id: 'late',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: DateTime(2026, 4, 28, 23, 59),
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      // newest-first: today(Apr29), Apr28, ...; index 1 is yesterday.
      expect(state.days[0].totalEntries, 0);
      expect(state.days[1].totalEntries, 1);
      expect(state.days[1].day, DateTime(2026, 4, 28));
    });

    test('future-dated entry (clock skew) outside window → dropped', () {
      final state = useCase(
        entries: [
          _entry(
            id: 'future',
            mood: MoodType.happy,
            intensity: 3,
            createdAt: now.add(const Duration(days: 1)),
          ),
        ],
        window: MoodWindow.week,
        now: now,
      );
      expect(state.isEmpty, isTrue);
    });
  });
}
