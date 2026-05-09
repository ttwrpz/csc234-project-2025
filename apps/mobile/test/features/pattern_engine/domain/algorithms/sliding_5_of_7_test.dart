import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/algorithms/sliding_5_of_7.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/daily_score.dart';

/// Pinned reference for "today" in the 7-day window. Mid-morning local time
/// so that `localMidnight(now)` reduces cleanly to 2026-05-09 00:00.
final _now = DateTime(2026, 5, 9, 10, 30);

DailyScore _day(DateTime when, double avgScore) =>
    DailyScore(day: localMidnight(when), avgScore: avgScore, entryCount: 1);

/// `today - i days`, at local midnight, for building scenario history.
DateTime _ago(int days) => localMidnight(_now).subtract(Duration(days: days));

void main() {
  group('slidingNegCount — degenerate inputs', () {
    test('empty history → 0', () {
      expect(slidingNegCount(const [], now: _now), 0);
    });

    test('all 7 days positive → 0', () {
      final history = [for (var i = 0; i < 7; i++) _day(_ago(i), 0.5)];
      expect(slidingNegCount(history, now: _now), 0);
    });

    test('all 7 days negative → 7', () {
      final history = [for (var i = 0; i < 7; i++) _day(_ago(i), -0.5)];
      expect(slidingNegCount(history, now: _now), 7);
    });
  });

  group('slidingNegCount — TC-25 (5 of 7) and neighbouring patterns', () {
    test('TC-25: 5 negative + 2 positive → 5 (caller fires Tier 2)', () {
      final history = [
        _day(_ago(0), -0.4),
        _day(_ago(1), -0.5),
        _day(_ago(2), -0.6),
        _day(_ago(3), -0.3),
        _day(_ago(4), -0.7),
        _day(_ago(5), 0.4),
        _day(_ago(6), 0.5),
      ];
      expect(slidingNegCount(history, now: _now), 5);
    });

    test('5 negative + 2 empty days → 5 (empty days do not count)', () {
      // Days 5 and 6 ago have NO DailyScore — they are empty. The predicate
      // is calendar-day based: empty days contribute 0, not negative.
      final history = [
        _day(_ago(0), -0.4),
        _day(_ago(1), -0.5),
        _day(_ago(2), -0.6),
        _day(_ago(3), -0.3),
        _day(_ago(4), -0.7),
      ];
      expect(slidingNegCount(history, now: _now), 5);
    });

    test('4 negative + 3 empty days → 4 (NOT 7 — empty ≠ negative)', () {
      // Architect's answer to HB-004 open question 1: empty days contribute
      // 0, not "negative because no positive logged." A user who logs only 4
      // negative entries in a 7-day window does NOT trigger Tier 2 simply
      // because they skipped logging on the other 3 days.
      final history = [
        _day(_ago(0), -0.4),
        _day(_ago(1), -0.5),
        _day(_ago(2), -0.6),
        _day(_ago(3), -0.3),
        // days 4..6 ago: empty
      ];
      expect(slidingNegCount(history, now: _now), 4);
    });
  });

  group('slidingNegCount — window boundaries', () {
    test('negative entries from 8+ days ago are ignored (outside window)', () {
      final history = [
        _day(_ago(7), -0.9),
        _day(_ago(8), -0.9),
        _day(_ago(15), -0.9),
        _day(_ago(0), -0.5), // inside window — counts.
      ];
      expect(slidingNegCount(history, now: _now), 1);
    });

    test('pre-aggregated DailyScore: same day not double-counted', () {
      // The orchestrator (Day 3) builds at most one DailyScore per day,
      // but defensively we accept duplicates; same-day entries collapse to
      // one bucket inside the function.
      final history = [
        _day(_ago(0), -0.4),
        _day(_ago(0), -0.6), // duplicate of today; last-write-wins.
      ];
      expect(slidingNegCount(history, now: _now), 1);
    });
  });

  group('slidingNegCount — sign boundary', () {
    test('avgScore == 0.0 is NOT negative (strict < 0)', () {
      final history = [
        _day(_ago(0), 0.0),
        _day(_ago(1), 0.0),
        _day(_ago(2), 0.0),
        _day(_ago(3), 0.0),
        _day(_ago(4), 0.0),
        _day(_ago(5), 0.0),
        _day(_ago(6), 0.0),
      ];
      expect(slidingNegCount(history, now: _now), 0);
    });

    test('avgScore = -0.0001 → counted as negative', () {
      final history = [_day(_ago(0), -0.0001)];
      expect(slidingNegCount(history, now: _now), 1);
    });
  });
}
