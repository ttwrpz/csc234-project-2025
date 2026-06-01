import 'package:core/core.dart';

/// Abstract contract for the per-user `cheerUpEvents` audit log.
///
/// One doc per `(uid, dayUtc, reason)` triple. The doc id is
/// `${dayUtc}-${reason}` so two same-day re-evaluations collide and the
/// second `create` short-circuits with the canonical `already-exists`
/// error - caught by the impl and surfaced as success because that IS
/// the idempotent path.
///
/// The Firestore-side trigger `sendCheerUpPush`
/// (functions/src/sendCheerUpPush.ts) fires on the create and is the ONLY
/// consumer of this collection. Append-only at the rules layer - update
/// + delete denied.
///
/// Domain-pure: no Firestore / Flutter / Firebase imports anywhere in
/// this file. The impl in `data/` does the wire-format work.
abstract class CheerUpEventsRepository {
  /// Idempotently writes the `cheerUpEvents/{dayUtc}-{reason}` doc.
  ///
  /// On a duplicate same-day write the impl swallows the
  /// `already-exists` error and returns `Ok(null)` - the CF only needs
  /// the FIRST write to fire its trigger; subsequent writes are no-ops.
  ///
  /// `now` is the moment the controller's `onShown` ran. The impl
  /// converts to UTC inside the doc id and uses
  /// `FieldValue.serverTimestamp` for the `createdAt` field, so the
  /// rule's `request.resource.data.createdAt == request.time` clause
  /// holds without trusting the client clock.
  Future<Result<void, CheerUpEventsFailure>> createEvent({
    required String reason,
    required DateTime now,
  });
}

/// Failure modes for the cheer-up events store. Sealed for exhaustive
/// switch and to mirror [InterventionStateFailure].
sealed class CheerUpEventsFailure extends Failure {
  const CheerUpEventsFailure({required super.message});

  const factory CheerUpEventsFailure.network() = _Network;
  const factory CheerUpEventsFailure.permission() = _Permission;
  const factory CheerUpEventsFailure.unknown(Object? cause) = _Unknown;
}

class _Network extends CheerUpEventsFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Permission extends CheerUpEventsFailure {
  const _Permission() : super(message: 'Permission denied.');
}

class _Unknown extends CheerUpEventsFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}

/// Allowed `reason` values - mirrors the regex in `firebase/firestore.rules`
/// and the Cloud Function's runtime check. Exposed as a const set so the
/// repository impl AND the controller can validate before round-tripping.
///
/// IF a future detector reason is added, the regex in `firestore.rules`
/// AND this set MUST be updated together.
const Set<String> kCheerUpEventReasons = <String>{
  '5_of_7_negative',
  '3_consecutive_high_intensity',
};

/// Formats `now` as `YYYY-MM-DD` in UTC. Pulled out as a top-level so
/// the controller, the impl, and tests all derive the doc id the same
/// way without rounding drift.
String formatDayUtc(DateTime now) {
  final utc = now.toUtc();
  final yyyy = utc.year.toString().padLeft(4, '0');
  final mm = utc.month.toString().padLeft(2, '0');
  final dd = utc.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}

/// Builds the canonical event-doc id from a (dayUtc, reason) pair.
/// Public-ish (no `_` prefix) so test code can assert the exact string
/// without re-deriving it.
String buildCheerUpEventId({required String dayUtc, required String reason}) =>
    '$dayUtc-$reason';
