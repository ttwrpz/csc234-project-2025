import 'package:core/core.dart';

import '../entities/weekly_garden.dart';
import '../harvest_failure.dart';

/// Contract for any backing store that persists archived [WeeklyGarden]
/// documents (HB-005 Track 6.1).
///
/// Implementations live in `data/` and may use Firestore, Drift, or a
/// fake. The Day-4 concrete implementation writes to
/// `users/{userId}/weeklyGardens/{weekId}` via `set(merge: false)`. The
/// firestore rule denies update + delete on this collection — calling
/// [archive] for an existing weekId surfaces as
/// [HarvestFailure.alreadyArchived].
///
/// Pure-Dart contract — imports only `package:core/core.dart` and sibling
/// domain entities. Domain-purity rule per CLAUDE.md.
abstract class HarvestRepository {
  /// Writes the [garden] to its `weeklyGardens/{garden.weekId}` doc.
  /// Returns [Err(HarvestFailure.alreadyArchived)] when the doc already
  /// exists (write-once-on-archive per ADR-0010 §6).
  Future<Result<WeeklyGarden, HarvestFailure>> archive({
    required String userId,
    required WeeklyGarden garden,
  });

  /// Streams the user's archived weeks newest-first (the History feed).
  /// Stream emits an empty list when the user has not yet harvested any
  /// week.
  Stream<List<WeeklyGarden>> watchHistory({required String userId});

  /// One-shot read of a specific archived week. Used by
  /// `ArchivedWeekScreen` when the user taps a History tile.
  Future<Result<WeeklyGarden, HarvestFailure>> getByWeekId({
    required String userId,
    required String weekId,
  });
}
