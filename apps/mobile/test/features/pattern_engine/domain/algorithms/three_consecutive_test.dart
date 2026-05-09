import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/algorithms/three_consecutive.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/daily_score.dart';

/// Pinned reference for "today" — mid-morning local time so that
/// `localMidnight(now)` reduces cleanly.
final _now = DateTime(2026, 5, 9, 10, 30);

DailyScore _day(DateTime when, double avgScore) =>
    DailyScore(day: localMidnight(when), avgScore: avgScore, entryCount: 1);

DateTime _ago(int days) => localMidnight(_now).subtract(Duration(days: days));

void main() {
  group('consecutiveHighIntensityCount — degenerate inputs', () {
    test('empty history → 0', () {
      expect(consecutiveHighIntensityCount(const [], now: _now), 0);
    });

    test('today not in history → 0 (no signal today)', () {
      // History exists but yesterday-and-earlier only; today is empty.
      final history = [
        _day(_ago(1), -0.7),
        _day(_ago(2), -0.7),
        _day(_ago(3), -0.7),
      ];
      expect(consecutiveHighIntensityCount(history, now: _now), 0);
    });
  });

  group('consecutiveHighIntensityCount — TC-26 + boundary cases', () {
    test(
      'TC-26: 3 consecutive days at exactly -0.6 → returns 3 (inclusive)',
      () {
        final history = [
          _day(_ago(0), -0.6),
          _day(_ago(1), -0.6),
          _day(_ago(2), -0.6),
        ];
        expect(consecutiveHighIntensityCount(history, now: _now), 3);
      },
    );

    test('3 consecutive days each at -0.7 → returns 3', () {
      final history = [
        _day(_ago(0), -0.7),
        _day(_ago(1), -0.7),
        _day(_ago(2), -0.7),
      ];
      expect(consecutiveHighIntensityCount(history, now: _now), 3);
    });

    test('today heavy, yesterday at -0.5 → returns 1 (streak breaks)', () {
      // Today's -0.7 counts; yesterday's -0.5 is not heavy → stop at 1.
      final history = [
        _day(_ago(0), -0.7),
        _day(_ago(1), -0.5),
        _day(_ago(2), -0.7),
      ];
      expect(consecutiveHighIntensityCount(history, now: _now), 1);
    });

    test('today heavy, yesterday missing → returns 1 (gap breaks)', () {
      final history = [_day(_ago(0), -0.7), _day(_ago(2), -0.7)];
      expect(consecutiveHighIntensityCount(history, now: _now), 1);
    });

    test('4 consecutive heavy days → returns 3 (caps)', () {
      // Function caps at 3 because the caller only checks `>= 3` and any
      // further walk-back is wasted work.
      final history = [
        _day(_ago(0), -0.8),
        _day(_ago(1), -0.7),
        _day(_ago(2), -0.7),
        _day(_ago(3), -0.7),
      ];
      expect(consecutiveHighIntensityCount(history, now: _now), 3);
    });

    test(
      'today -0.6, yesterday -0.6, day-before -0.59 → returns 2 (boundary)',
      () {
        // -0.59 is NOT heavy (predicate is `<= -0.6`). Streak breaks at i=2.
        final history = [
          _day(_ago(0), -0.6),
          _day(_ago(1), -0.6),
          _day(_ago(2), -0.59),
        ];
        expect(consecutiveHighIntensityCount(history, now: _now), 2);
      },
    );

    test('today positive → returns 0 (no streak starts)', () {
      final history = [
        _day(_ago(0), 0.4),
        _day(_ago(1), -0.7),
        _day(_ago(2), -0.7),
      ];
      expect(consecutiveHighIntensityCount(history, now: _now), 0);
    });

    test('predicate is inclusive at -0.6 exactly (-0.5999 NOT counted)', () {
      final history = [_day(_ago(0), -0.5999)];
      expect(consecutiveHighIntensityCount(history, now: _now), 0);
    });
  });

  group('consecutiveHighIntensityCount — caller wiring', () {
    test('count >= 3 fires Tier 3 (caller predicate, regression on cap)', () {
      // Even with 30 consecutive heavy days, the function returns 3 — the
      // caller's `>= 3` predicate then fires Tier 3 once. Mirrors the
      // contract documented in the function docstring.
      final history = [for (var i = 0; i < 30; i++) _day(_ago(i), -0.9)];
      expect(consecutiveHighIntensityCount(history, now: _now), 3);
    });
  });
}
