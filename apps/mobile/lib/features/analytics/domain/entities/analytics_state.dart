import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../mood/domain/entities/mood_type.dart';

part 'analytics_state.freezed.dart';

/// One bucket on the line chart's X-axis: a single local-time day with the
/// mean intensity per [MoodCategory] for that day.
///
/// `meanIntensityByCategory` only contains categories that had entries that
/// day; missing keys mean "no entries of that category on this day".
@freezed
abstract class DailyMoodAggregate with _$DailyMoodAggregate {
  const factory DailyMoodAggregate({
    required DateTime day,
    required int totalEntries,
    required Map<MoodCategory, double> meanIntensityByCategory,
  }) = _DailyMoodAggregate;
}

/// Snapshot the analytics screen renders. `days` is newest-first and has
/// length equal to `window.days` — every slot in the window is present even
/// when it has zero entries, so the chart's X-axis is stable.
@freezed
abstract class AnalyticsState with _$AnalyticsState {
  const AnalyticsState._();

  const factory AnalyticsState({
    required MoodWindow window,
    required List<DailyMoodAggregate> days,
  }) = _AnalyticsState;

  /// True when no entries fall in the window. Drives the empty-state copy on
  /// the screen.
  bool get isEmpty => days.every((d) => d.totalEntries == 0);

  /// Total entries plotted in the window — useful for debug/log lines, never
  /// for PII (no entry text).
  int get totalEntries => days.fold(0, (sum, d) => sum + d.totalEntries);
}
