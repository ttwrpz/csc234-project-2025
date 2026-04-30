import '../../../mood/domain/entities/mood_entry.dart';
import '../entities/calendar_state.dart';

/// Pure-Dart aggregation that turns a flat list of [MoodEntry]s into a
/// per-day [CalendarState] for the requested month.
///
/// Tie-break rules for days with multiple entries:
///   * `dominantCategory` is the category of the entry with the highest
///     `intensity`. On a tie, the entry with the **latest** `createdAt` wins.
///   * `mostRecentEntryId` is always the id of the entry with the latest
///     `createdAt` that day, regardless of intensity.
class ComputeCalendarStateUseCase {
  const ComputeCalendarStateUseCase();

  CalendarState call({
    required List<MoodEntry> entries,
    required DateTime month,
  }) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 1);

    // Bucket entries by their local-time midnight.
    final byDay = <DateTime, List<MoodEntry>>{};
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      if (local.isBefore(firstOfMonth) || !local.isBefore(nextMonth)) {
        continue;
      }
      final key = DateTime(local.year, local.month, local.day);
      (byDay[key] ??= <MoodEntry>[]).add(e);
    }

    final dots = <DateTime, DayDot>{};
    byDay.forEach((day, dayEntries) {
      // Sort newest-first by createdAt (used for both tie-break and
      // mostRecentEntryId selection).
      final sortedByRecency = [...dayEntries]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Pick the entry with the highest intensity. On ties, the most-recent
      // entry wins because we iterate sortedByRecency and use strict `>`.
      var dominant = sortedByRecency.first;
      for (final e in sortedByRecency.skip(1)) {
        if (e.intensity > dominant.intensity) {
          dominant = e;
        }
      }

      dots[day] = DayDot(
        day: day,
        dominantCategory: dominant.mood.category,
        totalEntries: dayEntries.length,
        mostRecentEntryId: sortedByRecency.first.id,
      );
    });

    return CalendarState(month: firstOfMonth, dotsByDay: dots);
  }
}
