import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../mood/data/providers.dart';
import '../../../mood/domain/entities/mood_entry.dart';
import '../../data/providers.dart';
import '../../domain/entities/weekly_garden.dart';
import '../../domain/harvest_failure.dart';
import '../../domain/usecases/archive_weekly_garden.dart';

/// Pending-harvest signal: `true` when the user's earliest unarchived
/// week has crossed its 7-day boundary AND no archive doc yet exists
/// for that week.
///
/// Computation:
///  1. Find the earliest entry across the full mood history. Its
///     `localMidnight` floored to the previous Monday is the user's
///     `earliestActiveWeekStart`.
///  2. Walk the archive newest-first; the user's `currentActiveWeekStart`
///     is the first Monday after the most recent archived `weekEnd`.
///     Falls back to `earliestActiveWeekStart` when the archive is empty.
///  3. Pending = `now >= currentActiveWeekStart + 7d` AND at least one
///     entry exists in `[currentActiveWeekStart, currentActiveWeekStart + 7d)`.
///
/// Returns `false` when no entries exist (no week to harvest), or when
/// any of the upstream providers are still loading.
final harvestPendingProvider = Provider<bool>((ref) {
  final entries = ref.watch(myMoodsStreamProvider).value;
  final history = ref.watch(weeklyGardenHistoryProvider).value;
  if (entries == null || history == null) return false;
  if (entries.isEmpty) return false;

  final activeWeekStart = activeWeekStartFor(
    entries: entries,
    history: history,
  );
  if (activeWeekStart == null) return false;

  final now = DateTime.now();
  final weekEnd = activeWeekStart.add(const Duration(days: 7));
  if (now.isBefore(weekEnd)) return false;

  // Only flag pending if the active week actually has any logs — an
  // empty week is not "pending" because there's nothing to summarise
  // yet (the archive use case rejects with `noEntries` anyway).
  return entries.any(
    (e) =>
        !localMidnight(e.createdAt).isBefore(activeWeekStart) &&
        localMidnight(e.createdAt).isBefore(weekEnd),
  );
});

/// Returns the Monday-midnight of the earliest week that has not yet
/// been archived. `null` when [entries] is empty.
///
/// Visible for tests so the gating logic can be exercised in isolation
/// from the streamed providers.
DateTime? activeWeekStartFor({
  required List<MoodEntry> entries,
  required List<WeeklyGarden> history,
}) {
  if (entries.isEmpty) return null;

  // Latest archived weekStart across the history. `archivedAt` ordering
  // is a proxy but not a guarantee (clock skew / replays), so we walk
  // every doc and pick the maximum weekStart.
  DateTime? latestArchivedWeekStart;
  for (final h in history) {
    final ws = localMidnight(h.weekStart);
    if (latestArchivedWeekStart == null ||
        ws.isAfter(latestArchivedWeekStart)) {
      latestArchivedWeekStart = ws;
    }
  }

  if (latestArchivedWeekStart != null) {
    // Active week begins on the Monday after the most recent archive's
    // weekEnd. `weekEnd = weekStart + 7d` so equivalently `start + 7d`.
    return latestArchivedWeekStart.add(const Duration(days: 7));
  }

  // No archive yet — start from the Monday of the earliest entry.
  final earliest = entries
      .map((e) => localMidnight(e.createdAt))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return _mondayOf(earliest);
}

/// Floors [day] to the Monday-midnight of its ISO week.
DateTime _mondayOf(DateTime day) {
  final local = DateTime(day.year, day.month, day.day);
  // Monday = 1 .. Sunday = 7 → subtract `weekday - 1` to land on Monday.
  return local.subtract(Duration(days: local.weekday - 1));
}

/// Status of the pending-harvest archive call. The screen renders
/// idle / running / failure states off this; on success the controller
/// flips `harvestPendingProvider` back to `false` automatically (the
/// underlying `weeklyGardenHistoryProvider` will refresh once the new
/// archive doc lands).
sealed class HarvestArchiveStatus {
  const HarvestArchiveStatus();
}

class HarvestArchiveIdle extends HarvestArchiveStatus {
  const HarvestArchiveIdle();
}

class HarvestArchiveRunning extends HarvestArchiveStatus {
  const HarvestArchiveRunning();
}

class HarvestArchiveSuccess extends HarvestArchiveStatus {
  const HarvestArchiveSuccess(this.garden);
  final WeeklyGarden garden;
}

/// Cross-device race outcome: Firestore reported the week was already
/// archived by another device. The user's intent ("harvest this week")
/// is fulfilled - the canonical archive doc exists - so presentation
/// treats this like Success (close the popup) rather than Error.
class HarvestArchiveAlreadyDone extends HarvestArchiveStatus {
  const HarvestArchiveAlreadyDone({required this.weekId});
  final String weekId;
}

class HarvestArchiveError extends HarvestArchiveStatus {
  const HarvestArchiveError(this.failure);
  final HarvestFailure failure;
}

/// Controller for the WeeklySummary CTA. The state machine is
/// idle → running → success | error. The screen calls
/// [acknowledge] from the Continue button.
///
/// Hand-rolled `Notifier` (not the @riverpod codegen) because the
/// state shape is a sealed class with a value-carrying `success`
/// variant — the codegen pipeline doesn't infer that cleanly today,
/// and the gain from codegen is small for a 4-state machine.
class WeeklySummaryController extends Notifier<HarvestArchiveStatus> {
  @override
  HarvestArchiveStatus build() => const HarvestArchiveIdle();

  /// Triggers the archive of the user's currently-pending week.
  /// Returns the persisted [WeeklyGarden] on success, or null when
  /// preconditions fail (no signed-in user, nothing to harvest).
  ///
  /// Idempotent: a second call after [HarvestArchiveSuccess] is a no-op
  /// (the screen should pop on success, but defense in depth in case
  /// the user double-taps Continue).
  Future<WeeklyGarden?> acknowledge() async {
    if (state is HarvestArchiveRunning ||
        state is HarvestArchiveSuccess ||
        state is HarvestArchiveAlreadyDone) {
      return null;
    }

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      state = const HarvestArchiveError(
        HarvestFailure.unknown('not-signed-in'),
      );
      return null;
    }

    final entries = ref.read(myMoodsStreamProvider).value ?? const [];
    final history = ref.read(weeklyGardenHistoryProvider).value ?? const [];
    final activeWeekStart = activeWeekStartFor(
      entries: entries,
      history: history,
    );
    if (activeWeekStart == null) {
      state = const HarvestArchiveError(HarvestFailure.noEntries());
      return null;
    }

    final weekEnd = activeWeekStart.add(const Duration(days: 7));
    final weekEntries =
        entries
            .where(
              (e) =>
                  !localMidnight(e.createdAt).isBefore(activeWeekStart) &&
                  localMidnight(e.createdAt).isBefore(weekEnd),
            )
            .toList(growable: false)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = const HarvestArchiveRunning();

    final useCase = ref.read(archiveWeeklyGardenUseCaseProvider);
    final result = await useCase(
      userId: user.uid,
      weekStart: activeWeekStart,
      now: DateTime.now(),
      weekEntries: weekEntries,
      // Per-day health history is reconstructed by the Garden state
      // computation each render, but the archive only needs the ending
      // tier — we pass an empty list and the use case falls back to
      // `PlantTier.resting`. Future work: pipe the EWMA history in
      // once the GardenState entity surfaces it.
      dailyHealthHistory: const [],
    );

    return result.fold(
      ok: (garden) {
        state = HarvestArchiveSuccess(garden);
        return garden;
      },
      err: (failure) {
        if (failure.isAlreadyArchived) {
          // Cross-device race: another device wrote the canonical
          // archive while this device's snapshot listener hadn't caught
          // up. Invalidating the history provider forces a re-subscribe
          // so the local cache pulls the canonical doc; flipping to
          // HarvestArchiveAlreadyDone lets the screen pop via the same
          // listener that handles HarvestArchiveSuccess.
          ref.invalidate(weeklyGardenHistoryProvider);
          state = HarvestArchiveAlreadyDone(
            weekId: ArchiveWeeklyGardenUseCase.formatWeekId(activeWeekStart),
          );
          return null;
        }
        state = HarvestArchiveError(failure);
        return null;
      },
    );
  }

  /// Dismisses an error state back to idle so the user can retry.
  void resetError() {
    if (state is HarvestArchiveError) {
      state = const HarvestArchiveIdle();
    }
  }

  /// Resets any terminal status (success or error) back to idle.
  /// Called by the home screen before pushing a fresh harvest screen so
  /// the previous week's `HarvestArchiveSuccess` doesn't make
  /// [acknowledge] a no-op on the next Continue tap. Running state is
  /// preserved — we never drop an in-flight archive write.
  void reset() {
    if (state is HarvestArchiveRunning) return;
    state = const HarvestArchiveIdle();
  }
}

final weeklySummaryControllerProvider =
    NotifierProvider<WeeklySummaryController, HarvestArchiveStatus>(
      WeeklySummaryController.new,
    );

/// Pre-archive preview of the pending week's summary. Returns `null`
/// when no harvest is pending (i.e. [harvestPendingProvider] is false).
///
/// Computed from the same active-week entries the controller's
/// [WeeklySummaryController.acknowledge] will pass to the use case, so
/// the on-screen numbers match the persisted [WeeklyGarden.summary] 1:1.
final pendingWeeklySummaryProvider = Provider<PendingWeekSummary?>((ref) {
  final pending = ref.watch(harvestPendingProvider);
  if (!pending) return null;

  final entries = ref.watch(myMoodsStreamProvider).value ?? const [];
  final history = ref.watch(weeklyGardenHistoryProvider).value ?? const [];
  final weekStart = activeWeekStartFor(entries: entries, history: history);
  if (weekStart == null) return null;

  final weekEnd = weekStart.add(const Duration(days: 7));
  final weekEntries = entries
      .where(
        (e) =>
            !localMidnight(e.createdAt).isBefore(weekStart) &&
            localMidnight(e.createdAt).isBefore(weekEnd),
      )
      .toList(growable: false);

  if (weekEntries.isEmpty) return null;

  final summary = ref
      .watch(computeWeeklySummaryUseCaseProvider)
      .call(
        weekEntries: weekEntries,
        dailyHealthHistory: const [],
        triggeredTierCount: 0,
      );
  return PendingWeekSummary(
    weekStart: weekStart,
    summary: summary,
    entries: weekEntries,
  );
});

/// Carrier for the pending week's metadata + computed summary. Only
/// [pendingWeeklySummaryProvider] emits one; the WeeklySummary screen
/// + garden routing wire-up consume it directly. [entries] are the
/// week's mood entries (already filtered to the active week) so the
/// summary screen's hero [GardenBed] can render real plants without
/// re-querying the stream.
class PendingWeekSummary {
  const PendingWeekSummary({
    required this.weekStart,
    required this.summary,
    required this.entries,
  });

  final DateTime weekStart;
  final WeeklySummary summary;
  final List<MoodEntry> entries;
}
