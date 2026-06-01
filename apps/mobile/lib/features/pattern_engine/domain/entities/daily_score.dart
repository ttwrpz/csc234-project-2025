import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_score.freezed.dart';

/// Per-day aggregate consumed by every Pattern Engine algorithm.
///
/// `day` is at user-local-midnight (use `localMidnight(DateTime)` from
/// `package:core/core.dart` when constructing). `avgScore` is the mean of
/// `MoodScore.value` across the day's entries (pure-Dart computation; the
/// orchestrator on Day 3 will build these from the user's `MoodEntry` list).
/// `entryCount` is for diagnostics - the algorithms do not read it.
///
/// Pure-Dart entity - only imports `freezed_annotation` (annotation-only).
@freezed
abstract class DailyScore with _$DailyScore {
  const factory DailyScore({
    required DateTime day,
    required double avgScore,
    required int entryCount,
  }) = _DailyScore;
}
