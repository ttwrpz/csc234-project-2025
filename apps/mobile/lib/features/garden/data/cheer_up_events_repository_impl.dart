import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/cheer_up_events_repository.dart';
import 'datasources/cheer_up_events_firestore_datasource.dart';

/// Firestore-backed implementation of [CheerUpEventsRepository].
///
/// The cheer-up audit log lives in `users/{uid}/cheerUpEvents/{evtId}`
/// where `evtId == ${dayUtc}-${reason}`. Two re-evaluations on the same
/// day collide on this id; the `set` write fails with `already-exists`
/// in that case and we treat it as success — that IS the idempotent
/// path the CF relies on (one trigger per (uid, day, reason)).
///
/// On `permission-denied` we surface
/// [CheerUpEventsFailure.permission] so callers can distinguish from a
/// transient network blip and avoid retrying on a logically-illegal
/// write (e.g. a malformed reason that the rule rejects).
class CheerUpEventsRepositoryImpl implements CheerUpEventsRepository {
  CheerUpEventsRepositoryImpl({
    required CheerUpEventsFirestoreDatasource datasource,
    required String? Function() uidGetter,
    Logger logger = const Logger('garden.cheerup.events.repo'),
  }) : _datasource = datasource,
       _uidGetter = uidGetter,
       _logger = logger;

  final CheerUpEventsFirestoreDatasource _datasource;
  final String? Function() _uidGetter;
  final Logger _logger;

  @override
  Future<Result<void, CheerUpEventsFailure>> createEvent({
    required String reason,
    required DateTime now,
  }) async {
    if (!kCheerUpEventReasons.contains(reason)) {
      // Defense-in-depth: the rule's regex would reject this anyway,
      // but a malformed reason should never round-trip even once.
      // Returning `unknown` rather than `permission` because the issue
      // is local (client bug), not the cloud's verdict.
      _logger.warn('createEvent rejected — unknown reason');
      return Err(CheerUpEventsFailure.unknown('reason: $reason'));
    }

    final uid = _uidGetter();
    if (uid == null || uid.isEmpty) {
      // No signed-in user → the CF trigger has no path to read settings
      // anyway. Surface as network so the controller doesn't blame the
      // user; it'll retry on the next trigger after auth resolves.
      return const Err(CheerUpEventsFailure.network());
    }

    final dayUtc = formatDayUtc(now);
    final evtId = buildCheerUpEventId(dayUtc: dayUtc, reason: reason);

    try {
      await _datasource.createEvent(
        uid: uid,
        evtId: evtId,
        reason: reason,
        dayUtc: dayUtc,
      );
      return const Ok(null);
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        // Idempotent path — the same (uid, day, reason) combo was
        // already written, the CF already fired (or rate-limited
        // legitimately). Success from the controller's perspective.
        return const Ok(null);
      }
      return Err(_failureFor(e));
    } catch (e) {
      return Err(CheerUpEventsFailure.unknown(e));
    }
  }

  CheerUpEventsFailure _failureFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const CheerUpEventsFailure.permission();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return const CheerUpEventsFailure.network();
      default:
        return CheerUpEventsFailure.unknown(e);
    }
  }
}
