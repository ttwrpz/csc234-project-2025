import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore wrapper for the `users/{uid}/cheerUpEvents/{evtId}`
/// audit-log collection (HB-003 §5.5b). Pulled out of the repository
/// impl so tests can fake the cloud surface without instantiating a
/// real `FirebaseFirestore` (mirrors the
/// [InterventionStateFirestoreDatasource] pattern from 5.5a).
///
/// The CF trigger `sendCheerUpPush` listens on document creates here.
/// This datasource is therefore the seam where the client decides to
/// fire a push (or not — duplicate same-day writes short-circuit
/// because the doc id collapses two re-evaluations into one).
class CheerUpEventsFirestoreDatasource {
  const CheerUpEventsFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Schema version stamped on every write. Bump when the doc shape
  /// changes; the rules already pin `schemaV: 1`.
  static const int schemaV = 1;

  /// Creates the event doc at the canonical path. Throws on Firestore
  /// errors (the repo translates them to `CheerUpEventsFailure`); the
  /// idempotent `already-exists` case is also propagated up so the repo
  /// can swallow it as success.
  Future<void> createEvent({
    required String uid,
    required String evtId,
    required String reason,
    required String dayUtc,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('cheerUpEvents')
        .doc(evtId);

    // Use `set` rather than `add` so the deterministic id is preserved.
    // Per the rule, `createdAt` MUST equal `request.time` — so it must
    // be a server timestamp, not a client clock.
    await ref.set(<String, Object?>{
      'reason': reason,
      'dayUtc': dayUtc,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaV': schemaV,
    });
  }
}
