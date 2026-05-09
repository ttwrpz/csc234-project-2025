/// Exponentially-weighted moving average of per-day mood-score means
/// that drives the slow "how is the week trending?" signal feeding
/// [PlantTier]. See ADR-0010 §3 and spec §2.3 for the derivation
/// (α=0.15 from the PHQ-9 2-week reflection window).
///
/// Recurrence:
///   H_t = α × S_day + (1 − α) × H_{t-1}
///   α = 0.15 (default)
///   H_0 = 0 (resets weekly — caller passes only the current week's
///   `dailyScores`)
///
/// Pure Dart — no Flutter/Firebase imports.
library;

/// Folds [dailyScores] (per-day mean `S_day`, chronological order) into
/// `H_t` using the EWMA recurrence. Empty list returns `0.0` (`H_0`).
///
/// `dailyScores` should contain one entry per day on which the user
/// actually logged at least one mood — empty days are *not* zero-folded
/// (a missing day means "no signal", not "neutral"; folding a zero
/// would bias H toward 0 over time, which is wrong). The use case is
/// responsible for filtering empty days out before calling this.
double foldGardenHealthEwma(List<double> dailyScores, {double alpha = 0.15}) {
  var h = 0.0;
  for (final s in dailyScores) {
    h = alpha * s + (1 - alpha) * h;
  }
  return h;
}

/// Single-step variant of the EWMA recurrence — useful when the caller
/// already has `H_{t-1}` (e.g. read from a Firestore doc) and wants to
/// fold today's `S_day` without rebuilding the full sequence.
///
/// Returns `α × sDay + (1 − α) × previousH`.
double stepGardenHealthEwma(
  double previousH,
  double sDay, {
  double alpha = 0.15,
}) {
  return alpha * sDay + (1 - alpha) * previousH;
}
