import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pattern_result.dart';

/// Thin Firestore wrapper for the `users/{userId}/patterns/{dateId}`
/// collection (HB-006 sub-track A; spec §4.2 data model).
///
/// One doc per local-midnight day; `dateId` IS the doc id, formatted
/// `yyyy-MM-dd`. Same-day re-evaluations overwrite the doc cleanly via
/// `set(merge: false)` — we don't merge because the orchestrator always
/// computes the full [PatternResult] from history (never a partial
/// patch), so a merge would only mask bugs where a field went missing
/// from a re-eval.
///
/// Uses `PatternResult.toJson()` / `fromJson()` directly — the entity is
/// already JSON-serialisable from Day 2, no separate DTO needed. The
/// Firestore document shape matches the entity's JSON shape 1:1, which
/// is exactly the shape the firestore.rules `affectedKeys()` allowlist
/// pins (HB-006 sub-track D).
class PatternsFirestoreDatasource {
  const PatternsFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Upserts the per-day pattern document. Throws on Firestore errors;
  /// the repository impl translates them to `PatternFailure`.
  Future<void> upsertPatternResult({
    required String userId,
    required PatternResult result,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('patterns')
        .doc(result.dateId);
    // `merge: false` — see class doc. Always a complete overwrite.
    await ref.set(result.toJson(), SetOptions(merge: false));
  }

  /// Streams the per-day pattern document for the dispatcher (S5 read
  /// path). Emits `null` when the document does not yet exist.
  Stream<PatternResult?> watchPatternResult({
    required String userId,
    required String dateId,
  }) {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('patterns')
        .doc(dateId);
    return ref.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return PatternResult.fromJson(data);
    });
  }

  /// Streams every pattern document with id in `[startDateId, endDateId]`
  /// inclusive — used by the (S5) Insights screen for historical reads.
  ///
  /// Firestore document ids are strings, so the inclusive range filter is
  /// `FieldPath.documentId() >= startDateId && <= endDateId`. The dateId
  /// format is `yyyy-MM-dd` which sorts lexicographically the same as
  /// chronologically, so document-id ordering is calendar-correct.
  Stream<List<PatternResult>> watchPatternResults({
    required String userId,
    required String startDateId,
    required String endDateId,
  }) {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('patterns');
    return col
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endDateId)
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => PatternResult.fromJson(d.data())).toList(),
        );
  }
}
