import 'dart:math' as math;

import 'package:core/core.dart';

import '../entities/daily_score.dart';

/// Returns the current CUSUM statistic `C_t` after folding `history`
/// chronologically through the negative-side recursion:
///   `C_t = max(0, C_{t-1} + (μ_30 - k) - S_t)`
///   `k   = 0.5 × σ_30`   (slack)
///   `h   = 4   × σ_30`   (decision threshold; see [cusumThreshold])
///
/// Returns `0.0` when:
///   * `history` is empty,
///   * the baseline has fewer than 14 distinct days (warm-up),
///   * `σ_30 < sigmaEpsilon` (a flat baseline has no scale; the recursion
///     collapses to "today vs μ", which is more honestly a Z-score).
///
/// `C_0 = 0` at the start of `history`. The orchestrator does NOT carry
/// `c` across days; we fold from the start of `history` every time.
/// Acceptable because `history.length` is bounded by Drift cache + Firestore
/// page limits, and the recompute is < 1 ms even at 1000 days. No
/// persisted CUSUM state. (HB-004 open question 2 — closed in HB-006.)
///
/// **Variance divisor:** population stddev (`n`), matching [zScoreToday].
///
/// Trigger semantics (caller decides):
///   * `cusumC > cusumThreshold(history, now)` → Tier 3.
///
/// Pure-Dart function — imports only `dart:math`, `package:core/core.dart`,
/// and the sibling [DailyScore] entity.
///
/// Citation: Page (1954), *Continuous Inspection Schemes*, Biometrika 41.
double cusumC(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
}) {
  if (history.isEmpty) return 0.0;

  final stats = _baselineStats(
    history,
    now: now,
    baselineDays: baselineDays,
    sigmaEpsilon: sigmaEpsilon,
  );
  if (stats == null) return 0.0;

  final mu = stats.mu;
  final k = 0.5 * stats.sigma;

  // Sort ascending by day so the recursion folds chronologically. We sort a
  // local copy — we do not mutate the caller's list.
  final sorted = [...history]..sort((a, b) => a.day.compareTo(b.day));

  var c = 0.0;
  for (final entry in sorted) {
    final next = c + (mu - k) - entry.avgScore;
    c = next > 0 ? next : 0.0;
  }
  return c;
}

/// Returns `4 × σ_30` — the CUSUM decision threshold the orchestrator
/// compares `cusumC` against. Returns `0.0` when the baseline is too
/// small or too flat to support a defensible σ (matching [cusumC]'s
/// guards, so a `> threshold` comparison naturally never fires while the
/// engine is still warming up).
///
/// Sibling pure function so the orchestrator can pull `c` and `h` from
/// the same module without re-deriving σ_30. (HB-006 open question 1 —
/// architect default: a sibling function.)
double cusumThreshold(
  List<DailyScore> history, {
  required DateTime now,
  int baselineDays = 30,
  double sigmaEpsilon = 1e-9,
}) {
  final stats = _baselineStats(
    history,
    now: now,
    baselineDays: baselineDays,
    sigmaEpsilon: sigmaEpsilon,
  );
  if (stats == null) return 0.0;
  return 4 * stats.sigma;
}

/// `(μ, σ)` of the user's `baselineDays`-day baseline excluding today,
/// or `null` when the baseline is shorter than 14 days OR σ is below
/// [sigmaEpsilon]. Shared between [cusumC] and [cusumThreshold] so the
/// guards are identical.
({double mu, double sigma})? _baselineStats(
  List<DailyScore> history, {
  required DateTime now,
  required int baselineDays,
  required double sigmaEpsilon,
}) {
  final today = localMidnight(now);

  final byDay = <DateTime, double>{
    for (final entry in history) localMidnight(entry.day): entry.avgScore,
  };

  final baseline = <double>[];
  for (final MapEntry(:key, :value) in byDay.entries) {
    if (key == today) continue;
    final diff = today.difference(key).inDays;
    if (diff > 0 && diff <= baselineDays) {
      baseline.add(value);
    }
  }

  if (baseline.length < 14) return null;

  final mu = baseline.reduce((a, b) => a + b) / baseline.length;
  var sumSquares = 0.0;
  for (final v in baseline) {
    final d = v - mu;
    sumSquares += d * d;
  }
  final sigma = math.sqrt(sumSquares / baseline.length);
  if (sigma < sigmaEpsilon) return null;

  return (mu: mu, sigma: sigma);
}
