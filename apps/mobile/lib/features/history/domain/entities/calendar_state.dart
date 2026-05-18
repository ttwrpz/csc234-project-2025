import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../mood/domain/entities/mood_type.dart';

part 'calendar_state.freezed.dart';

/// Aggregated, presentation-friendly snapshot of one calendar month for
/// the History calendar view. Computed in pure Dart by
/// `ComputeCalendarStateUseCase` from the user's mood entries.
///
/// `month` is normalised to local-time midnight on the first of the month.
/// `dotsByDay` keys are also local-time midnight `DateTime`s.
@freezed
abstract class CalendarState with _$CalendarState {
  const CalendarState._();

  const factory CalendarState({
    required DateTime month,
    required Map<DateTime, DayDot> dotsByDay,
  }) = _CalendarState;

  /// `true` when the month has no entries; the view shows a compassionate
  /// empty state.
  bool get isEmpty => dotsByDay.isEmpty;
}

/// One day's worth of presentation data: which dot color to paint, how many
/// entries the user logged, and the id of the most-recent entry to navigate to
/// when the cell is tapped.
@freezed
abstract class DayDot with _$DayDot {
  const factory DayDot({
    required DateTime day,
    required MoodCategory dominantCategory,
    required int totalEntries,
    required String mostRecentEntryId,
  }) = _DayDot;
}
