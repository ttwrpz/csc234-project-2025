import 'package:core/core.dart';

import '../../../mood/domain/entities/mood_entry.dart';
import '../entities/weekly_garden.dart';
import '../harvest_failure.dart';
import '../repositories/harvest_repository.dart';
import 'compute_weekly_summary.dart';

/// Archives the week containing [weekStart] (HB-005 Track 6.1).
///
/// Pure-Dart use case; the I/O contract is delegated to [HarvestRepository].
/// The use case does NOT mutate the flat `users/{uid}/moods/` collection —
/// the harvest is purely additive (a new doc at
/// `users/{uid}/weeklyGardens/{weekId}`), so the Pattern Engine's
/// 14-day Mann-Kendall and 30-day Z-score / CUSUM windows are unaffected
/// across week boundaries (TC-30).
///
/// Internal flow per HB-005:
///  1. Reject empty weeks with [HarvestFailure.noEntries] — there's
///     nothing to summarise yet.
///  2. Compute `weekId = '${year}-W${isoWeekNumber.padLeft(2, '0')}'`
///     using ISO-8601 week semantics (Mon = day 1; week 1 of a year is
///     the week containing Jan-4).
///  3. Build [WeeklySummary] via [ComputeWeeklySummaryUseCase].
///  4. Build [WeeklyGarden] with `weekEnd = weekStart + 7d` and
///     `archivedAt = now`.
///  5. Forward to the repository's `archive`. The repo enforces
///     write-once via the Firestore rule — collisions surface as
///     [HarvestFailure.alreadyArchived].
class ArchiveWeeklyGardenUseCase {
  const ArchiveWeeklyGardenUseCase({
    required HarvestRepository repository,
    required ComputeWeeklySummaryUseCase computeSummary,
  }) : _repository = repository,
       _computeSummary = computeSummary;

  final HarvestRepository _repository;
  final ComputeWeeklySummaryUseCase _computeSummary;

  Future<Result<WeeklyGarden, HarvestFailure>> call({
    required String userId,
    required DateTime weekStart,
    required DateTime now,
    required List<MoodEntry> weekEntries,
    required List<double> dailyHealthHistory,
    int triggeredTierCount = 0,
  }) async {
    if (weekEntries.isEmpty) {
      return const Err(HarvestFailure.noEntries());
    }

    final weekId = formatWeekId(weekStart);
    final summary = _computeSummary(
      weekEntries: weekEntries,
      dailyHealthHistory: dailyHealthHistory,
      triggeredTierCount: triggeredTierCount,
    );

    final garden = WeeklyGarden(
      weekId: weekId,
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 7)),
      entries: List.unmodifiable(weekEntries),
      healthHistory: List.unmodifiable(dailyHealthHistory),
      summary: summary,
      archivedAt: now,
    );

    return _repository.archive(userId: userId, garden: garden);
  }

  /// Public for testability — the repository impl uses the same id format
  /// when round-tripping through `getByWeekId`.
  ///
  /// `'YYYY-Www'` per HB-005 (zero-padded week ordinal). Visible for
  /// tests so the doc-id contract is asserted alongside the use case.
  static String formatWeekId(DateTime weekStart) {
    final week = isoWeekNumber(weekStart).toString().padLeft(2, '0');
    return '${isoWeekYear(weekStart)}-W$week';
  }

  /// ISO-8601 week number of [date] (Mon = day 1; week 1 of a year is
  /// the week containing Jan-4). Implemented inline so we don't pull in
  /// `package:intl` just for this one helper.
  ///
  /// Algorithm (Wikipedia "ISO week date" §"Calculating the week number
  /// from a month and day of the month"): for the Thursday of the same
  /// ISO week as [date], the week number equals
  /// `((Thursday's ordinal day) + 9) / 7` truncated.
  static int isoWeekNumber(DateTime date) {
    final thursday = _isoWeekThursday(date);
    final dayOfYear = thursday.difference(DateTime(thursday.year)).inDays + 1;
    return ((dayOfYear - 1) ~/ 7) + 1;
  }

  /// ISO-8601 week-numbering year (the year that owns the ISO week,
  /// which can differ from `date.year` near year boundaries — e.g.
  /// 2026-01-01 is in ISO week 2026-W01 but 2027-01-01 is in 2026-W53).
  static int isoWeekYear(DateTime date) {
    return _isoWeekThursday(date).year;
  }

  /// Returns the Thursday of [date]'s ISO week (Mon=1..Sun=7). The week
  /// number / week year are both derived from this Thursday.
  static DateTime _isoWeekThursday(DateTime date) {
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    // Monday = 1, ..., Sunday = 7; we want Thursday = 4.
    final delta = 4 - day.weekday;
    return day.add(Duration(days: delta));
  }
}
