import 'package:core/core.dart';

import '../entities/pattern_result.dart';
import '../pattern_failure.dart';

/// Contract for any backing store that persists per-day [PatternResult]
/// documents.
///
/// Implementations live in `data/` and may use Firestore, Drift, or a fake.
/// The concrete implementation writes to
/// `users/{userId}/patterns/{result.dateId}` via `set(merge: false)` so that
/// same-day re-evaluations replace the doc cleanly (the dateId is the
/// document id - one doc per local-midnight day).
///
/// Pure-Dart contract - imports only `package:core/core.dart` and sibling
/// domain entities. Domain-purity rule per CLAUDE.md.
abstract class PatternRepository {
  /// Upserts the engine's per-day result. Best-effort: callers should log
  /// the failure but not block the user's mood-save success on it.
  Future<Result<void, PatternFailure>> save({
    required String userId,
    required PatternResult result,
  });

  /// Streams a single per-day pattern document for the dispatcher read
  /// path. Emits `null` when the document does not yet exist.
  Stream<PatternResult?> watch({
    required String userId,
    required String dateId,
  });

  /// Streams every pattern document with a `dateId` between [startDateId]
  /// and [endDateId] inclusive - used by the Insights screen to render
  /// historical Tier markers and the `H_t` overlay without recomputing the
  /// algorithms. The dateId format matches the storage convention
  /// (`yyyy-MM-dd`); the data layer orders the snapshot by document id
  /// which is the natural date order.
  ///
  /// Emits an empty list when the user has no patterns yet. Errors flow
  /// through the stream's error channel - the consumer (the Insights
  /// repository impl) maps them to its own failure type.
  Stream<List<PatternResult>> watchRange({
    required String userId,
    required String startDateId,
    required String endDateId,
  });
}
