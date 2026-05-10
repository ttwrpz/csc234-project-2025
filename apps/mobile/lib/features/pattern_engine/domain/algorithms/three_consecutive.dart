import 'package:core/core.dart';

import '../entities/daily_score.dart';

/// Returns the count of trailing consecutive days (ending today) where
/// `avgScore <= -0.6`. Capped at 3 — the caller compares against `>= 3`
/// for Tier 3 and any further walk-back is wasted work.
///
/// A missing day in the trailing 3-day window breaks the streak (returns
/// 0, 1, or 2). Today's score is counted only if today exists in
/// `history`; otherwise the function returns 0 (no signal today).
///
/// The boundary is **inclusive** at `-0.6`: a day whose `avgScore` is
/// exactly `-0.6` counts as heavy. (Equivalent to `<= -0.6`, NOT `< -0.6`.)
///
/// Trigger semantics (caller decides):
///  * count `>= 3` → Tier 3.
///
/// Pure-Dart function — imports only `package:core/core.dart` (for
/// `localMidnight`) and the sibling [DailyScore] entity. No Flutter /
/// Firebase imports per CLAUDE.md.
///
/// See HB-004 §"Five algorithm functions" algorithm 3 + spec §2.4.
int consecutiveHighIntensityCount(
  List<DailyScore> history, {
  required DateTime now,
}) {
  if (history.isEmpty) return 0;

  final today = localMidnight(now);

  // Bucket by local-midnight day for O(1) lookup. Defensive last-write-wins
  // on duplicate `day` keys mirrors `slidingNegCount`'s contract; the
  // orchestrator pre-aggregates to one DailyScore per day in practice.
  final byDay = <DateTime, double>{
    for (final entry in history) localMidnight(entry.day): entry.avgScore,
  };

  var count = 0;
  for (var i = 0; i < 3; i += 1) {
    final day = today.subtract(Duration(days: i));
    final score = byDay[day];
    if (score == null || score > -0.6) break;
    count += 1;
  }
  return count;
}
