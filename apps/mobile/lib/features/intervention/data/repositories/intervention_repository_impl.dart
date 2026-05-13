import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../../domain/entities/intervention_failure.dart';
import '../../domain/entities/intervention_record.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../datasources/interventions_firestore_datasource.dart';

/// Firestore-backed [InterventionRepository].
///
/// Audit-trail rows live at `users/{uid}/interventions/{dispatchId}` with
/// append-only semantics enforced at the rules layer: every field but
/// `optedOut` is immutable post-create, and `optedOut` is a one-way
/// `false → true` toggle. See `firestore.rules` `/interventions/{id}` block.
///
/// **Idempotency.** Same-millisecond duplicate dispatches collide on the
/// deterministic `dispatchId` (`${tier.name}-${epochMs}` per
/// [TieredInterventionDispatcher]). The second `set` fails with
/// `already-exists`, which we treat as success — that IS the idempotent
/// path. Mirrors the [CheerUpEventsRepositoryImpl] approach.
///
/// **No PII logging.** `record.quoteId` is a stable curated-pool index or
/// an AI-hash, never the body. The body itself never enters the repo's
/// observability surface.
class InterventionRepositoryImpl implements InterventionRepository {
  InterventionRepositoryImpl({
    required InterventionsFirestoreDatasource datasource,
    required String? Function() uidGetter,
    Logger logger = const Logger('intervention.repo'),
  }) : _datasource = datasource,
       _uidGetter = uidGetter,
       _logger = logger;

  final InterventionsFirestoreDatasource _datasource;
  final String? Function() _uidGetter;
  final Logger _logger;

  @override
  Future<Result<void, InterventionFailure>> writeRecord(
    InterventionRecord record,
  ) async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      // No signed-in user → there's no canonical path to write to. The
      // controller already surfaced the banner in-memory; this failure
      // is the bookkeeping cost the dispatcher accepts (HB-007 §"order
      // is intentional: render-then-persist").
      _logger.warn('writeRecord skipped — no uid');
      return const Err(InterventionFailure.anchorReadFailed());
    }

    try {
      await _datasource.createRecord(uid: uid, record: record);
      return const Ok(null);
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        // Idempotent path — the same (uid, dispatchId) tuple has already
        // been written. Success from the caller's perspective.
        return const Ok(null);
      }
      _logger.warn(
        'writeRecord failed',
        data: <String, Object?>{'code': e.code},
      );
      return Err(InterventionFailure.unknown(e));
    } catch (e) {
      _logger.warn('writeRecord failed', data: e.runtimeType.toString());
      return Err(InterventionFailure.unknown(e));
    }
  }

  @override
  Future<Result<void, InterventionFailure>> markOptedOut(
    String dispatchId,
  ) async {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      _logger.warn('markOptedOut skipped — no uid');
      return const Err(InterventionFailure.anchorReadFailed());
    }

    try {
      await _datasource.markOptedOut(uid: uid, dispatchId: dispatchId);
      return const Ok(null);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        // The doc was never written (likely the audit write failed on
        // the previous render-then-persist hop). Mark this as success
        // anyway — the controller has already cleared its pending state
        // and the user's intent is honoured locally. Defense-in-depth
        // against a race the rule cannot prevent.
        return const Ok(null);
      }
      _logger.warn(
        'markOptedOut failed',
        data: <String, Object?>{'code': e.code},
      );
      return Err(InterventionFailure.unknown(e));
    } catch (e) {
      _logger.warn('markOptedOut failed', data: e.runtimeType.toString());
      return Err(InterventionFailure.unknown(e));
    }
  }

  @override
  Stream<List<InterventionRecord>> watchHistory({int limit = 20}) {
    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      // No user → empty history. Avoids a Firestore listener attaching
      // on the wrong path; the next sign-in will rebuild the provider
      // and reattach.
      return const Stream.empty();
    }
    return _datasource.watchHistory(uid: uid, limit: limit);
  }
}
