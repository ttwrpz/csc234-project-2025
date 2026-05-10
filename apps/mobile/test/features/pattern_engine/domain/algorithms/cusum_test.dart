import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/algorithms/cusum.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/daily_score.dart';

/// Pinned reference for "today".
final _now = DateTime(2026, 5, 9, 10, 30);

DailyScore _day(DateTime when, double avgScore) =>
    DailyScore(day: localMidnight(when), avgScore: avgScore, entryCount: 1);

DateTime _ago(int days) => localMidnight(_now).subtract(Duration(days: days));

void main() {
  group('cusumC — guards', () {
    test('empty history → 0.0', () {
      expect(cusumC(const [], now: _now), 0.0);
      expect(cusumThreshold(const [], now: _now), 0.0);
    });

    test('baseline shorter than 14 distinct days → C = 0.0', () {
      // 13 baseline days + today = baseline.length == 13 < 14.
      final history = [
        _day(_ago(0), -0.9),
        for (var i = 1; i <= 13; i++) _day(_ago(i), 0.2),
      ];
      expect(cusumC(history, now: _now), 0.0);
      expect(cusumThreshold(history, now: _now), 0.0);
    });

    test('flat baseline (σ ≈ 0) → C = 0.0', () {
      // 15 identical baseline days; σ collapses to 0.
      final history = [
        _day(_ago(0), -0.9),
        for (var i = 1; i <= 15; i++) _day(_ago(i), 0.3),
      ];
      expect(cusumC(history, now: _now), 0.0);
      expect(cusumThreshold(history, now: _now), 0.0);
    });
  });

  group('cusumC — flat or near-flat trajectories', () {
    test('flat series matching baseline mean → C ≈ 0', () {
      // 16-day baseline (excluding today) alternating 0.32 / 0.28 →
      // μ = 0.3, small σ. Today is also at 0.3 — every day's contribution
      // is near zero and `max(0, ...)` clamps any small negatives.
      final history = [
        _day(_ago(0), 0.3),
        for (var i = 1; i <= 16; i++) _day(_ago(i), i.isOdd ? 0.32 : 0.28),
      ];
      final c = cusumC(history, now: _now);
      // Allow a small positive drift from the floating-point recursion.
      expect(c, lessThan(0.5));
    });

    test('positive spike near the start → C resets via max(0, ...)', () {
      // Start with a single very positive day (suppresses the recursion to
      // 0 immediately), then 15 days at the baseline mean. C stays low.
      final history = [
        for (var i = 0; i <= 15; i++) _day(_ago(i), i.isOdd ? 0.32 : 0.28),
        _day(_ago(16), 1.0),
      ];
      final c = cusumC(history, now: _now);
      expect(c, lessThan(0.5));
    });
  });

  group('cusumC — TC-29 sustained drop', () {
    // Construction:
    //   * 30 baseline days at avgScore = +0.3 alternating with +0.4 to give
    //     μ = 0.35, σ ≈ 0.05 (a tight, slightly varying baseline).
    //   * Then 5 days at avgScore = -0.5 (sustained drop).
    //   * Today is in the drop → engine sees the recent regime change.
    //
    // Per-step contribution during the drop (approx):
    //   c_next = max(0, c + (μ - k) - S_t)
    //          = max(0, c + (0.35 - 0.025) - (-0.5))
    //          = max(0, c + 0.825)
    // So C accumulates roughly +0.825 × 5 ≈ 4.125 by today.
    // Threshold h = 4 × σ ≈ 0.2.
    // C clearly exceeds h → caller fires Tier 3.

    test('TC-29: sustained drop drives C past h = 4σ → Tier 3', () {
      const baselineDays = 30;
      // Baseline: alternating 0.3 / 0.4 over 30 days (excluding today
      // and the 5 drop days). Place baseline 6..35 days ago.
      final history = <DailyScore>[
        // 5 sustained-drop days ending today.
        for (var i = 0; i < 5; i++) _day(_ago(i), -0.5),
        // 30-day baseline before the drop.
        for (var i = 5; i < 5 + baselineDays; i++)
          _day(_ago(i), i.isOdd ? 0.3 : 0.4),
      ];
      final c = cusumC(history, now: _now);
      final h = cusumThreshold(history, now: _now);
      // Both must be defined (baseline length ≥ 14, σ > 0).
      expect(h, greaterThan(0.0));
      // Sustained drop accumulates well past the threshold.
      expect(c, greaterThan(h));
      // Caller's predicate `c > h` fires Tier 3.
    });
  });

  group('cusumC — chronological folding', () {
    test('history order is irrelevant — input is sorted internally', () {
      // Same series in two orders should produce the same C.
      final ordered = <DailyScore>[
        for (var i = 0; i < 5; i++) _day(_ago(i), -0.5),
        for (var i = 5; i < 35; i++) _day(_ago(i), i.isOdd ? 0.3 : 0.4),
      ];
      final shuffled = List<DailyScore>.from(ordered)..shuffle();
      expect(
        cusumC(ordered, now: _now),
        closeTo(cusumC(shuffled, now: _now), 0.005),
      );
    });
  });
}
