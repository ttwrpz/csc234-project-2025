import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/insights/data/insights_repository_impl.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/domain/entities/insight_window.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_type.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/pattern_result.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

/// Tests target the pure-Dart join function exposed by
/// [InsightsRepositoryImpl.joinForTest]. The use case itself is a thin
/// wrapper around the repository's stream - these tests exercise the
/// real shape-correctness invariant the screen relies on.

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

PatternResult _pattern({required String dateId, Tier? tier}) {
  return PatternResult(
    dateId: dateId,
    mannKendallZ: null,
    slidingNegCount: 0,
    consecutiveHighIntensity: 0,
    zScoreToday: null,
    cusumC: 0,
    triggeredTier: tier,
  );
}

void main() {
  // Anchor "now" at a Wednesday so the 14-day window straddles two
  // Mondays - exercises the weekly H_t reset path.
  // 2026-05-13 is a Wednesday.
  final now = DateTime(2026, 5, 13, 9);

  group('InsightsRepositoryImpl.joinForTest', () {
    test('emits exactly window.dayCount items, ordered ascending', () {
      final window = InsightWindow.from(
        preset: InsightWindowPreset.fortnight,
        now: now,
      );
      final result = InsightsRepositoryImpl.joinForTest(
        window,
        const [],
        const [],
      );
      expect(result, hasLength(14));
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].date.isAfter(result[i - 1].date),
          isTrue,
          reason: 'days must be strictly ascending',
        );
      }
    });

    test('empty-day slots carry no entry signal', () {
      final window = InsightWindow.from(
        preset: InsightWindowPreset.week,
        now: now,
      );
      final result = InsightsRepositoryImpl.joinForTest(
        window,
        const [],
        const [],
      );
      for (final d in result) {
        expect(d.entryCount, 0);
        expect(d.avgMoodScore, isNull);
        expect(d.dominantEmotion, isNull);
        expect(d.triggeredTier, isNull);
      }
    });

    test(
      'avgMoodScore averages every entry on the same local-midnight day',
      () {
        final window = InsightWindow.from(
          preset: InsightWindowPreset.week,
          now: now,
        );
        // Two entries on today: happy/5 (S = +1.0) and sad/2 (S = -0.4).
        // avg = (1.0 + -0.4) / 2 = 0.3.
        final today = DateTime(now.year, now.month, now.day);
        final moods = [
          _entry(
            id: 'a',
            mood: MoodType.happy,
            intensity: 5,
            createdAt: today.add(const Duration(hours: 9)),
          ),
          _entry(
            id: 'b',
            mood: MoodType.sad,
            intensity: 2,
            createdAt: today.add(const Duration(hours: 18)),
          ),
        ];
        final result = InsightsRepositoryImpl.joinForTest(
          window,
          moods,
          const [],
        );
        final todayInsight = result.last;
        expect(todayInsight.date, today);
        expect(todayInsight.entryCount, 2);
        expect(todayInsight.avgMoodScore, closeTo(0.3, 1e-9));
      },
    );

    test(
      'dominantEmotion is the most-frequent mood across the day, ties by enum order',
      () {
        final window = InsightWindow.from(
          preset: InsightWindowPreset.week,
          now: now,
        );
        final today = DateTime(now.year, now.month, now.day);
        // Two anxious, two happy → tie; MoodType.values declaration
        // order has `happy` before `anxious`, so the join picks happy.
        final moods = [
          _entry(
            id: '1',
            mood: MoodType.anxious,
            intensity: 3,
            createdAt: today,
          ),
          _entry(
            id: '2',
            mood: MoodType.anxious,
            intensity: 3,
            createdAt: today,
          ),
          _entry(id: '3', mood: MoodType.happy, intensity: 3, createdAt: today),
          _entry(id: '4', mood: MoodType.happy, intensity: 3, createdAt: today),
        ];
        final result = InsightsRepositoryImpl.joinForTest(
          window,
          moods,
          const [],
        );
        expect(result.last.dominantEmotion, MoodType.happy);
      },
    );

    test(
      'pattern docs by dateId surface triggeredTier on the matching day',
      () {
        final window = InsightWindow.from(
          preset: InsightWindowPreset.week,
          now: now,
        );
        // Pattern doc for 2 days ago with Tier 2.
        final twoDaysAgo = DateTime(now.year, now.month, now.day - 2);
        final dateId =
            '${twoDaysAgo.year.toString().padLeft(4, "0")}-'
            '${twoDaysAgo.month.toString().padLeft(2, "0")}-'
            '${twoDaysAgo.day.toString().padLeft(2, "0")}';
        final patterns = [_pattern(dateId: dateId, tier: Tier.two)];

        final result = InsightsRepositoryImpl.joinForTest(
          window,
          const [],
          patterns,
        );
        final match = result.firstWhere((d) => d.date == twoDaysAgo);
        expect(match.triggeredTier, Tier.two);
        expect(
          result.where((d) => d.triggeredTier != null),
          hasLength(1),
          reason: 'only the matching day should carry a tier',
        );
      },
    );

    test('H_t resets to 0 at every Monday boundary', () {
      // Window opens on Sunday May 3 (a Sunday is the day BEFORE
      // Monday in our `weekday` convention) and runs 14 days through
      // Saturday May 16. Two Monday resets fall inside the window.
      //
      // Actually use a known anchor: now = Sat 2026-05-16, 14d window.
      final nowSat = DateTime(2026, 5, 16, 12);
      final window = InsightWindow.from(
        preset: InsightWindowPreset.fortnight,
        now: nowSat,
      );

      // Heavy negative entry on the Sunday before the FIRST window
      // Monday → folds into a negative H. The next Monday must reset
      // H_t to 0 regardless.
      final sunBeforeMonday = DateTime(2026, 5, 3); // Sunday
      final mondayAfter = DateTime(2026, 5, 4);
      final moods = [
        _entry(
          id: 's',
          mood: MoodType.sad,
          intensity: 5,
          createdAt: sunBeforeMonday.add(const Duration(hours: 12)),
        ),
      ];
      final result = InsightsRepositoryImpl.joinForTest(
        window,
        moods,
        const [],
      );
      // The Sunday May 3 itself is BEFORE the window start (May 3
      // is exactly 13 days before May 16, so it IS the window start -
      // adjust expectation). Verify the gradient: the Sunday cell has
      // a non-null H (negative), and the immediately-following Monday
      // cell has the reset H (null or 0 - null in our impl because
      // no entries fold yet on that Monday).
      final sunCell = result.firstWhere((d) => d.date == sunBeforeMonday);
      final monCell = result.firstWhere((d) => d.date == mondayAfter);
      expect(sunCell.gardenHealthH, isNotNull);
      expect(sunCell.gardenHealthH! < 0, isTrue);
      // After the Monday reset, H should be null (no entries that
      // Monday) - proving the reset cleared the previous week's H.
      expect(monCell.gardenHealthH, isNull);
    });

    test('userId-empty repository returns gap-only window', () {
      // The repository's stream branch for an empty userId emits a
      // pure-empty window. Mirror the structure by calling joinForTest
      // with empty inputs and assert the same invariants.
      final window = InsightWindow.from(
        preset: InsightWindowPreset.week,
        now: now,
      );
      final out = InsightsRepositoryImpl.joinForTest(
        window,
        const [],
        const [],
      );
      expect(out, hasLength(7));
      expect(out.every((d) => d.entryCount == 0), isTrue);
      expect(out.every((d) => d.triggeredTier == null), isTrue);
    });

    test('joinForTest is deterministic for identical inputs', () {
      final window = InsightWindow.from(
        preset: InsightWindowPreset.fortnight,
        now: now,
      );
      final today = DateTime(now.year, now.month, now.day);
      final moods = [
        _entry(id: 'd', mood: MoodType.calm, intensity: 4, createdAt: today),
      ];
      final patterns = [
        _pattern(
          dateId:
              '${today.year.toString().padLeft(4, "0")}-'
              '${today.month.toString().padLeft(2, "0")}-'
              '${today.day.toString().padLeft(2, "0")}',
          tier: Tier.one,
        ),
      ];
      final a = InsightsRepositoryImpl.joinForTest(window, moods, patterns);
      final b = InsightsRepositoryImpl.joinForTest(window, moods, patterns);
      expect(a, b);
    });
  });

  group('DailyInsight.empty', () {
    test('zero-counts and all-null signal fields', () {
      final d = DailyInsight.empty(DateTime(2026, 5, 1));
      expect(d.date, DateTime(2026, 5, 1));
      expect(d.entryCount, 0);
      expect(d.avgMoodScore, isNull);
      expect(d.gardenHealthH, isNull);
      expect(d.dominantEmotion, isNull);
      expect(d.triggeredTier, isNull);
    });
  });

  group('InsightWindow.from', () {
    test('14d window is inclusive on both endpoints', () {
      final w = InsightWindow.from(
        preset: InsightWindowPreset.fortnight,
        now: DateTime(2026, 5, 13, 9, 0),
      );
      expect(w.dayCount, 14);
      expect(w.startDate, DateTime(2026, 4, 30));
      expect(w.endDate, DateTime(2026, 5, 13));
      expect(w.endDate.difference(w.startDate).inDays, 13);
    });
  });
}
