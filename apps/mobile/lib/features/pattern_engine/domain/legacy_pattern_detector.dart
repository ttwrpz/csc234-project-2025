import 'package:core/core.dart';

import '../../garden/domain/entities/intervention_state.dart';
import '../../mood/domain/entities/mood_entry.dart';
import '../../mood/domain/entities/mood_type.dart';

/// Legacy pure-Dart pattern detector. Implements the legacy 2-rule
/// trigger model (5-of-7 negative days + 3-consecutive heavy negatives)
/// plus the 48h cooldown / 10-day escalation gates.
///
/// **Deprecated.** Replaced by `RunPatternEngineUseCase` in
/// `apps/mobile/lib/features/pattern_engine/domain/usecases/run_pattern_engine.dart`,
/// which runs five academic-grade algorithms (Mann-Kendall, sliding 5-of-7,
/// 3-consecutive S ≤ -0.6, Z-score, CUSUM). Retained as a regression
/// baseline only.
///
/// Rules (preserved exactly for the legacy code path):
///  * **5-of-7 days**: at least 5 distinct local-midnight days within the
///    last 7 contain ≥1 negative-category entry.
///  * **3-consecutive ≥4 negative**: the last 3 distinct days each
///    contain ≥1 entry with `mood.category != positive` AND
///    `intensity ≥ 4`. Mixed neg types count.
///
/// Note: `okay` is classified as `positive` in `MoodType.category`, so
/// the `mood.category != positive` predicate below excludes `okay` entries
/// from the 5-of-7 or 3-consecutive counts.
///  * **48h cooldown**: if `lastTriggeredAt` is within 48h of `now`,
///    suppress (`triggered: false`, `reason: 'cooldown'`).
///  * **10-day escalation**: if currently triggering AND
///    `firstTriggeredAt` is ≥ 10 days ago, set `escalated: true`.
///
/// `now` is injected so tests can pin "today". `lastTriggeredAt` and
/// `firstTriggeredAt` come from persistence.
@Deprecated(
  'Replaced by RunPatternEngineUseCase. Retained as a regression baseline.',
)
InterventionState detectPattern(
  List<MoodEntry> entries, {
  required DateTime now,
  DateTime? lastTriggeredAt,
  DateTime? firstTriggeredAt,
}) {
  // Cooldown gate first - a recent trigger suppresses re-firing regardless
  // of current pattern.
  if (lastTriggeredAt != null &&
      now.difference(lastTriggeredAt) < const Duration(hours: 48)) {
    return const InterventionState(
      triggered: false,
      escalated: false,
      reason: 'cooldown',
    );
  }

  if (entries.isEmpty) return InterventionState.none();

  final today = localMidnight(now);

  // Bucket entries by their local-midnight day. For each day, track:
  //   * has any negative entry → contributes to the 5-of-7 rule
  //   * has any negative entry with intensity ≥ 4 → contributes to the
  //     3-consecutive heavy rule
  final hasNegativeOnDay = <DateTime, bool>{};
  final hasHeavyOnDay = <DateTime, bool>{};
  for (final entry in entries) {
    final day = localMidnight(entry.createdAt);
    final isNegative = entry.mood.category != MoodCategory.positive;
    if (!isNegative) continue;
    hasNegativeOnDay[day] = true;
    if (entry.intensity >= 4) {
      hasHeavyOnDay[day] = true;
    }
  }

  // Rule 1: 5-of-7. Count distinct negative days in the inclusive 7-day
  // window ending at `today`.
  var negativeDayCount = 0;
  for (var i = 0; i < 7; i += 1) {
    final day = today.subtract(Duration(days: i));
    if (hasNegativeOnDay[day] == true) negativeDayCount += 1;
  }
  if (negativeDayCount >= 5) {
    return _withEscalation(
      reason: '5_of_7_negative',
      now: now,
      firstTriggeredAt: firstTriggeredAt,
    );
  }

  // Rule 2: 3 consecutive heavy-negative days ending today (or yesterday -
  // we walk back from today and count up to three consecutive heavy days).
  var consecutiveHeavy = 0;
  for (var i = 0; i < 3; i += 1) {
    final day = today.subtract(Duration(days: i));
    if (hasHeavyOnDay[day] != true) {
      consecutiveHeavy = 0;
      break;
    }
    consecutiveHeavy += 1;
  }
  if (consecutiveHeavy >= 3) {
    return _withEscalation(
      reason: '3_consecutive_high_intensity',
      now: now,
      firstTriggeredAt: firstTriggeredAt,
    );
  }

  return InterventionState.none();
}

InterventionState _withEscalation({
  required String reason,
  required DateTime now,
  required DateTime? firstTriggeredAt,
}) {
  final escalated =
      firstTriggeredAt != null &&
      now.difference(firstTriggeredAt) >= const Duration(days: 10);
  return InterventionState(
    triggered: true,
    escalated: escalated,
    reason: reason,
  );
}
