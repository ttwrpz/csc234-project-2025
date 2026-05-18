import 'dart:math' as math;

import '../entities/daily_score.dart';

/// Returns the Z statistic of the Mann-Kendall trend test over the last
/// `windowDays` (default 14) of `history`.
///
/// Returns `null` when `history.length < 14` — not enough samples for a
/// defensible Z. A user newly onboarded within the past two weeks therefore
/// never trips Tier 1, which is the intended "warm-up" semantics.
///
/// Trigger semantics (caller decides — this function returns Z only):
///  * `Z < -1.96` → Tier 1 (gradual worsening, two-tailed α = 0.05).
///  * `Z > +1.96` → encouragement (no alert — gradual improvement).
///  * |Z| ≤ 1.96  → no signal.
///
/// Algorithm:
///   Step 1: S = Σ_{i<j} sign(x_j - x_i)
///   Step 2: V = n × (n - 1) × (2n + 5) / 18
///   Step 3: Z = (S - 1)/√V if S > 0
///         = 0              if S = 0
///         = (S + 1)/√V if S < 0
///
/// Pure-Dart function — no state, no async, no I/O. Imports only
/// `dart:math` and the sibling [DailyScore] entity.
///
/// Citations: Mann (1945), *Econometrica* 13, 245–259;
/// Kendall (1975), *Rank Correlation Methods*.
double? mannKendallZ(List<DailyScore> history, {int windowDays = 14}) {
  if (history.length < 14) return null;

  // Take the LAST `windowDays` (chronologically). The orchestrator hands us
  // an ascending-by-day list, so the tail is the most recent. Clamp the
  // window to the available history when `history.length` sits between 14
  // and `windowDays`.
  final n = math.min(history.length, windowDays);
  final start = history.length - n;
  final x = [for (var i = start; i < history.length; i++) history[i].avgScore];

  // Step 1: pairwise sign sum.
  var s = 0;
  for (var i = 0; i < n; i += 1) {
    for (var j = i + 1; j < n; j += 1) {
      final diff = x[j] - x[i];
      if (diff > 0) {
        s += 1;
      } else if (diff < 0) {
        s -= 1;
      }
      // diff == 0 contributes 0 (ties).
    }
  }

  // Step 2: variance.
  final v = n * (n - 1) * (2 * n + 5) / 18.0;
  final sqrtV = math.sqrt(v);

  // Step 3: Z statistic (continuity-corrected for non-zero S).
  if (s > 0) return (s - 1) / sqrtV;
  if (s < 0) return (s + 1) / sqrtV;
  return 0.0;
}
