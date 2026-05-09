import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/algorithms/mann_kendall.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/daily_score.dart';

/// Builds a `List<DailyScore>` from a list of `avgScore` values. Day field is
/// synthetic (Mann-Kendall is order-sensitive but day-value-agnostic; the
/// orchestrator on Day 3 is responsible for ascending-by-day sorting).
List<DailyScore> _series(List<double> scores) {
  final base = DateTime(2026, 4, 26); // 14 days before TC-27 reference today.
  return [
    for (var i = 0; i < scores.length; i++)
      DailyScore(
        day: base.add(Duration(days: i)),
        avgScore: scores[i],
        entryCount: 1,
      ),
  ];
}

void main() {
  group('mannKendallZ — sample-size guard', () {
    test('history.length = 13 → null (insufficient samples)', () {
      final history = _series(List.generate(13, (_) => 0.0));
      expect(mannKendallZ(history), isNull);
    });

    test('empty history → null', () {
      expect(mannKendallZ(const []), isNull);
    });
  });

  group('mannKendallZ — degenerate series', () {
    test('flat 14-day series (all 0.0) → Z = 0.0 (S = 0)', () {
      final history = _series(List<double>.filled(14, 0.0));
      final z = mannKendallZ(history);
      expect(z, isNotNull);
      expect(z!, closeTo(0.0, 0.005));
    });

    test('mixed series with no trend → |Z| < 1.96 (no Tier-1 trigger)', () {
      // 14-day alternation starting at +0.5. The pairwise sign sum is small
      // but non-zero (S = -7 due to the parity asymmetry of an even-length
      // series starting at +; Z ≈ -0.328 — well inside the no-trigger band).
      // The point of the case is to assert the algorithm does NOT cry trend
      // on a stationary, oscillating signal.
      final history = _series([
        0.5, -0.5, 0.5, -0.5, 0.5, -0.5, 0.5, //
        -0.5, 0.5, -0.5, 0.5, -0.5, 0.5, -0.5,
      ]);
      final z = mannKendallZ(history);
      expect(z, isNotNull);
      expect(z!.abs(), lessThan(1.96));
    });
  });

  group('mannKendallZ — strictly trending series', () {
    test(
      'strictly ascending 14-day series → Z > +1.96 (encouragement zone)',
      () {
        // 0.05, 0.10, …, 0.70 — every j>i pair is concordant up.
        final history = _series(List.generate(14, (i) => (i + 1) * 0.05));
        final z = mannKendallZ(history);
        expect(z, isNotNull);
        // S = C(14,2) = 91; V = 333.667; Z = 90/√V ≈ +4.927.
        expect(z!, greaterThan(1.96));
        expect(z, closeTo(4.927, 0.005));
      },
    );

    test('strictly descending 14-day series → Z < -1.96 (Tier 1 zone)', () {
      // Mirror of the ascending case: Z ≈ -4.927.
      final history = _series(List.generate(14, (i) => 0.70 - i * 0.05));
      final z = mannKendallZ(history);
      expect(z, isNotNull);
      expect(z!, lessThan(-1.96));
      expect(z, closeTo(-4.927, 0.005));
    });
  });

  group('mannKendallZ — TC-27 (spec §2.4 algorithm 1 worked example)', () {
    // Spec §7.27 prescribes Z = -2.21 to 2 d.p. for a "steadily declining"
    // 14-day window. Mann-Kendall's S is integer-valued, so the achievable
    // Z values are quantised. With n = 14, V = 333.667 and √V ≈ 18.2665:
    //   * S = -41 → Z = -40/√V ≈ -2.1898
    //   * S = -42 → Z = -41/√V ≈ -2.2445
    // Neither integer-S lands within 0.005 of -2.21. The brief's fallback
    // (HB-004 §"NEW — Five algorithm functions" algorithm 1) is to assert
    // Tier-1 firing on a clearly declining series and document the deviation.
    //
    // We do BOTH:
    //  (a) assert the Tier-1 trigger condition on a monotone non-increasing
    //      14-day series — the user-facing behaviour (Z < -1.96);
    //  (b) pin the closest-achievable Z (-2.1898 from S = -41) using a
    //      brute-found series so a future TC-27 reviewer can see exactly
    //      how close to -2.21 the algorithm gets.
    //
    // FOLLOW-UP: file an orchestrator review issue noting the spec says
    // -2.21 ± 0.005 but the integer-S quantisation only allows -2.190 or
    // -2.244. (Tracked in HB-004 deviation log; flagged for architect review
    // before the Day-3 orchestrator merges.)

    test('clearly declining series fires Tier 1 (Z < -1.96)', () {
      // Monotone non-increasing 14-day series. 10 days at 0.5 followed by
      // 0.4, 0.4, 0.4, 0.3 — gives S = -43, Z ≈ -2.299, well below the
      // -1.96 trigger.
      final history = _series([
        0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, //
        0.4, 0.4, 0.4, 0.3,
      ]);
      final z = mannKendallZ(history);
      expect(z, isNotNull);
      expect(z!, lessThan(-1.96));
      expect(z, closeTo(-2.299, 0.005));
    });

    test('closest-achievable Z to spec -2.21 → Z ≈ -2.1898 (S = -41)', () {
      // Brute-found 14-day series with S = -41 (the integer S closest to the
      // spec's target Z = -2.21). Tail has a small bump at the end which is
      // why the integer-S quantisation lands at -41 rather than the nearby
      // -42 (monotone) or -36 (under-bucketed).
      final history = _series([
        0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, //
        0.45, 0.4, 0.3, 0.45,
      ]);
      final z = mannKendallZ(history);
      expect(z, isNotNull);
      expect(z!, lessThan(-1.96)); // Tier-1 trigger holds.
      // Closest the algorithm can get to spec -2.21 with integer S.
      expect(z, closeTo(-2.190, 0.005));
    });
  });
}
