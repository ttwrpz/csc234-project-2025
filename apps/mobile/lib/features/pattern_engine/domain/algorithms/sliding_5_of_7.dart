import 'package:core/core.dart';

import '../entities/daily_score.dart';

/// Counts distinct local-midnight days in the inclusive 7-day window
/// `[now-6d, now]` where `avgScore < 0`.
///
/// `now` anchors "today" (use `DateTime.now()` in production; tests pin a
/// fixed instant for determinism). The function reduces `now` to local
/// midnight before bucketing; the [DailyScore] entity already carries
/// local-midnight `day` values per its docstring, so the comparison is direct.
///
/// Empty days (no entry) contribute **0** — they are NOT counted as negative
/// even if surrounded by negative days. The predicate is calendar-day-based
/// (`count(S_t < 0 in last 7 calendar days)`), NOT log-frequency-based —
/// mirrors PHQ-9's "more than half the days." See HB-004 open question 1
/// (architect default).
///
/// The strict `< 0` boundary is intentional: a day whose `avgScore` is
/// exactly 0.0 is not negative. (`avgScore = -0.0001` IS negative.)
///
/// Trigger semantics (caller decides):
///  * count `>= 5` → Tier 2.
///
/// Pure-Dart function — imports only `package:core/core.dart` (for
/// `localMidnight`) and the sibling [DailyScore] entity. No Flutter /
/// Firebase imports per CLAUDE.md.
int slidingNegCount(List<DailyScore> history, {required DateTime now}) {
  if (history.isEmpty) return 0;

  final today = localMidnight(now);

  // Bucket history by local-midnight day for O(7) lookup. Multiple entries on
  // the same day are pre-aggregated upstream into a single DailyScore, so the
  // bucket is degenerate by construction; we still defensively last-write-wins
  // if a caller hands us a duplicate `day`.
  final byDay = <DateTime, double>{
    for (final entry in history) localMidnight(entry.day): entry.avgScore,
  };

  var count = 0;
  for (var i = 0; i < 7; i += 1) {
    final day = today.subtract(Duration(days: i));
    final score = byDay[day];
    if (score != null && score < 0) {
      count += 1;
    }
  }
  return count;
}
