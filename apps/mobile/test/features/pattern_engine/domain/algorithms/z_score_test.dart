import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/algorithms/z_score.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/daily_score.dart';

/// Pinned reference for "today".
final _now = DateTime(2026, 5, 9, 10, 30);

DailyScore _day(DateTime when, double avgScore) =>
    DailyScore(day: localMidnight(when), avgScore: avgScore, entryCount: 1);

DateTime _ago(int days) => localMidnight(_now).subtract(Duration(days: days));

void main() {
  group('zScoreToday - guards', () {
    test('today not in history → null (no signal today)', () {
      // Plenty of baseline but no entry for today.
      final history = [
        for (var i = 1; i <= 14; i++) _day(_ago(i), 0.3 + (i % 3) * 0.05),
      ];
      expect(zScoreToday(history, now: _now), isNull);
    });

    test('baseline length == 13 → null (warm-up; need >= 14)', () {
      final history = [
        _day(_ago(0), -0.5),
        for (var i = 1; i <= 13; i++) _day(_ago(i), 0.3),
      ];
      expect(zScoreToday(history, now: _now), isNull);
    });

    test('flat baseline (σ ≈ 0) → null (15 identical baseline days)', () {
      final history = [
        _day(_ago(0), -0.5),
        for (var i = 1; i <= 15; i++) _day(_ago(i), 0.3),
      ];
      expect(zScoreToday(history, now: _now), isNull);
    });

    test('empty history → null', () {
      expect(zScoreToday(const [], now: _now), isNull);
    });
  });

  group('zScoreToday - TC-28 worked example', () {
    // Baseline series (14 distinct days, lookback excludes today):
    //   [0.5, 0.4, 0.3, 0.2, 0.1, 0.4, 0.3, 0.2, 0.5, 0.3, 0.3, 0.3, 0.2, 0.4]
    // → μ ≈ 0.31429, population σ ≈ 0.11247.
    // Today = -0.9 → z ≈ (-0.9 - 0.31429) / 0.11247 ≈ -10.795.
    //
    // Spec TC-28 wants `z_day < -2.5` to fire Tier 3; this construction
    // sails far past that threshold so the assertion is robust against
    // small variance-divisor changes (n vs n-1). The pinned z value is
    // verified by the implementation; if a future divisor change shifts
    // it, recompute and update - the Tier-3 inequality is the user-facing
    // contract.

    test('TC-28: z ≈ -10.80 (well below -2.5 → Tier 3 trigger)', () {
      final baselineSeries = [
        0.5, 0.4, 0.3, 0.2, 0.1, 0.4, 0.3, //
        0.2, 0.5, 0.3, 0.3, 0.3, 0.2, 0.4,
      ];
      final history = [
        _day(_ago(0), -0.9),
        for (var i = 0; i < baselineSeries.length; i++)
          _day(_ago(i + 1), baselineSeries[i]),
      ];
      final z = zScoreToday(history, now: _now);
      expect(z, isNotNull);
      expect(z!, lessThan(-2.5));
      // Pinned numerically - see header comment for derivation.
      expect(z, closeTo(-10.795, 0.005));
    });

    test('today equals baseline mean → z ≈ 0', () {
      // 14 distinct baseline days with μ = 0.3 by construction.
      // Use `[0.32, 0.28, 0.32, 0.28, ...]` - μ = 0.3, small but non-zero σ.
      final history = [
        _day(_ago(0), 0.3), // today
        for (var i = 1; i <= 14; i++) _day(_ago(i), i.isOdd ? 0.32 : 0.28),
      ];
      final z = zScoreToday(history, now: _now);
      expect(z, isNotNull);
      expect(z!, closeTo(0.0, 0.005));
    });
  });

  group('zScoreToday - threshold neighbourhood', () {
    test('z just under -2.5 is reported (caller decides Tier 3)', () {
      // Construct baseline so today's z lands at ≈ -2.49:
      //   μ = 0.0, σ ≈ 0.4, today = -2.49 × 0.4 ≈ -0.996.
      // Baseline of `[+0.4, -0.4, ...]` over 14 days: μ=0, σ=0.4.
      final history = [
        _day(_ago(0), -0.996),
        for (var i = 1; i <= 14; i++) _day(_ago(i), i.isOdd ? 0.4 : -0.4),
      ];
      final z = zScoreToday(history, now: _now);
      expect(z, isNotNull);
      // Within 0.01 of -2.49.
      expect(z!, closeTo(-2.49, 0.01));
      expect(z, greaterThan(-2.5)); // would NOT fire Tier 3.
    });

    test('z just past -2.5 is reported (caller fires Tier 3)', () {
      // μ = 0.0, σ = 0.4, today = -2.51 × 0.4 = -1.004.
      final history = [
        _day(_ago(0), -1.004),
        for (var i = 1; i <= 14; i++) _day(_ago(i), i.isOdd ? 0.4 : -0.4),
      ];
      final z = zScoreToday(history, now: _now);
      expect(z, isNotNull);
      expect(z!, closeTo(-2.51, 0.01));
      expect(z, lessThan(-2.5)); // WOULD fire Tier 3.
    });
  });

  group('zScoreToday - baseline window', () {
    test(
      'days outside the 30-day window are not in the baseline (custom window)',
      () {
        // Use baselineDays=10 to exercise the lookback bound deterministically.
        // Today + 10 days at 0.4 (in window) + 5 days at -1.0 (outside window).
        // Baseline = 10 days × 0.4 → still `< 14` → null (warm-up).
        final history = [
          _day(_ago(0), 0.0),
          for (var i = 1; i <= 10; i++) _day(_ago(i), 0.4),
          for (var i = 12; i <= 16; i++) _day(_ago(i), -1.0),
        ];
        expect(zScoreToday(history, now: _now, baselineDays: 10), isNull);
      },
    );
  });
}
