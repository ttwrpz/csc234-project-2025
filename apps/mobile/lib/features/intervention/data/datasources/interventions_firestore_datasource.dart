import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../pattern_engine/domain/entities/tier.dart';
import '../../domain/entities/intervention_record.dart';

/// Thin Firestore wrapper for the `users/{uid}/interventions/{dispatchId}`
/// audit-log collection.
///
/// Pulled out of the repository impl so tests can fake the cloud surface
/// without instantiating a real `FirebaseFirestore` (mirrors the
/// [InterventionStateFirestoreDatasource] and
/// [CheerUpEventsFirestoreDatasource] patterns).
///
/// **Server-time invariant.** The Firestore rule on this collection requires
/// `dispatchedAt == request.time`, so the create write must use
/// `FieldValue.serverTimestamp()` rather than a client-side `DateTime`. The
/// in-memory [InterventionRecord] carries the client clock value for use by
/// the controller / banner, but the on-the-wire value is always the server
/// stamp the rule pins.
///
/// Throws on Firestore errors (the repo translates them to
/// [InterventionFailure]); the idempotent `already-exists` case is also
/// propagated up so the repo can swallow it as success (same pattern as
/// [CheerUpEventsRepositoryImpl]).
class InterventionsFirestoreDatasource {
  const InterventionsFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Schema version stamped on every write. Bump (and add a migration)
  /// only when the document shape itself changes.
  static const int schemaV = 1;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('interventions');

  /// Creates the audit doc at the canonical path with the server-time
  /// stamp on `dispatchedAt`. `cooldownUntil` is a plain Firestore
  /// `Timestamp` (the rule asserts `> request.time`, which the dispatcher
  /// guarantees by construction - it's the dispatch instant + 48h).
  Future<void> createRecord({
    required String uid,
    required InterventionRecord record,
  }) async {
    await _collection(uid).doc(record.dispatchId).set(<String, Object?>{
      'dispatchId': record.dispatchId,
      'tier': _tierWire(record.tier),
      'dispatchedAt': FieldValue.serverTimestamp(),
      'quoteId': record.quoteId,
      'cooldownUntil': Timestamp.fromDate(record.cooldownUntil.toUtc()),
      'optedOut': record.optedOut,
      'schemaV': schemaV,
    });
  }

  /// Partial update: flips `optedOut` from `false` to `true`. The rule
  /// enforces this is the only allowed update (one-way transition,
  /// affectedKeys hasOnly `['optedOut']`).
  Future<void> markOptedOut({
    required String uid,
    required String dispatchId,
  }) async {
    await _collection(
      uid,
    ).doc(dispatchId).update(<String, Object?>{'optedOut': true});
  }

  /// Streams the most-recent [limit] records for [uid], newest first.
  /// Each snapshot delivers the full window (Firestore streams are
  /// snapshot-based; consumers cope by `distinct()`-ing if they care).
  Stream<List<InterventionRecord>> watchHistory({
    required String uid,
    int limit = 20,
  }) {
    return _collection(uid)
        .orderBy('dispatchedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_recordFromDoc).toList());
  }

  /// Decodes a Firestore doc back into the domain [InterventionRecord].
  /// Tolerates both `Timestamp` (production) and `null` (transient
  /// pending-server-stamp) on `dispatchedAt`; in the null case we use
  /// `DateTime.now()` as a placeholder - the next snapshot delivers the
  /// real value.
  static InterventionRecord _recordFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final dispatchedAtRaw = data['dispatchedAt'];
    final cooldownUntilRaw = data['cooldownUntil'];
    return InterventionRecord(
      dispatchId: (data['dispatchId'] as String?) ?? doc.id,
      tier: _tierFromWire(data['tier'] as String?),
      dispatchedAt: dispatchedAtRaw is Timestamp
          ? dispatchedAtRaw.toDate().toLocal()
          : DateTime.now(),
      quoteId: (data['quoteId'] as String?) ?? '',
      cooldownUntil: cooldownUntilRaw is Timestamp
          ? cooldownUntilRaw.toDate().toLocal()
          : DateTime.now(),
      optedOut: (data['optedOut'] as bool?) ?? false,
      schemaV: (data['schemaV'] as num?)?.toInt() ?? schemaV,
    );
  }

  /// Wire-format tier string. Must match the values the rule accepts
  /// (`['one','two','three']`) and the `Tier.fromJson` enum names.
  static String _tierWire(Tier tier) => switch (tier) {
    Tier.one => 'one',
    Tier.two => 'two',
    Tier.three => 'three',
  };

  static Tier _tierFromWire(String? wire) => switch (wire) {
    'one' => Tier.one,
    'two' => Tier.two,
    'three' => Tier.three,
    // Defense-in-depth: an unrecognised tier on the wire collapses to
    // `Tier.three` (the safest read - surface professional resources
    // rather than swallow). The rule rejects unknown values on create,
    // so this branch should be unreachable in production.
    _ => Tier.three,
  };
}
