import 'package:core/core.dart';

import '../entities/intervention_failure.dart';
import '../entities/intervention_record.dart';

/// Audit-trail repository for dispatched interventions.
///
/// Implementations live in `data/` (Day-2 work). Writes are append-only at
/// the Firestore-rules level — once a record is created, every field except
/// `optedOut` is immutable. The opt-out toggle is one-way (`false → true`,
/// see `firestore.rules` `/users/{uid}/interventions/{id}` block).
///
/// Pure-Dart contract — imports only `package:core/core.dart` and sibling
/// domain entities. Domain-purity rule per CLAUDE.md.
abstract class InterventionRepository {
  /// Persists one dispatch row. Best-effort: callers should log the failure
  /// but not block the user-visible banner on it (the in-app dispatch is
  /// already correct in-memory; the audit doc is for later analysis).
  Future<Result<void, InterventionFailure>> writeRecord(
    InterventionRecord record,
  );

  /// Marks `optedOut = true` on an existing dispatch. Idempotent: a second
  /// call returns `Ok(null)` even if the doc is already opted out. The
  /// rules enforce one-way at the wire level so a future bug that flips
  /// the bit the wrong way is rejected by Firestore.
  Future<Result<void, InterventionFailure>> markOptedOut(String dispatchId);

  /// Streams the most-recent `limit` records for the current user, newest
  /// first. Used by the Settings → "Recent check-ins" history list (Day-2
  /// presentation work).
  Stream<List<InterventionRecord>> watchHistory({int limit = 20});
}
