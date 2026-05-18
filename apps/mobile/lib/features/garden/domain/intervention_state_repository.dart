import 'package:core/core.dart';

/// Abstract contract for the cheer-up cooldown / escalation anchor store.
///
/// Two anchors are persisted per user:
///  * `lastTriggeredAt` — the most recent moment the detector reported
///    `triggered: true`. Drives the 48h cooldown gate.
///  * `firstTriggeredAt` — the start of the current escalation window.
///    Drives the 10-day in-app hotline-footer escalation. Cleared by the
///    detector lifecycle when 48h pass without a re-trigger.
///
/// The implementation is Firestore-primary with a SharedPreferences mirror
/// that backs the offline-read path. Reads prefer Firestore (synced cache);
/// writes hit Firestore first then mirror locally. The Cloud Function sees
/// the Firestore copy.
abstract class InterventionStateRepository {
  /// Reads the persisted anchors. Result is `Ok(InterventionAnchors())`
  /// (both fields null) when no anchor has ever been written. Never
  /// returns the SharedPreferences mirror as a separate value when the
  /// Firestore read fails — instead the mirror is consulted as fallback
  /// inside the implementation, and the caller sees a single `Ok(value)`
  /// regardless. If both Firestore and the mirror fail, an `Err` is
  /// returned.
  Future<Result<InterventionAnchors, InterventionStateFailure>> read();

  /// Idempotent write of `lastTriggeredAt`. Always overwrites.
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  );

  /// Writes `firstTriggeredAt` only if the persisted value is `null`.
  /// Idempotent across re-renders within the same trigger cycle.
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  );

  /// Clears `firstTriggeredAt`. Called by the detector lifecycle when
  /// the cooldown window (48h) elapses without a re-trigger.
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt();
}

/// Pure-Dart anchor pair. No Flutter / Firebase imports.
class InterventionAnchors {
  const InterventionAnchors({this.lastTriggeredAt, this.firstTriggeredAt});

  final DateTime? lastTriggeredAt;
  final DateTime? firstTriggeredAt;

  /// Returns a copy with the supplied fields replaced. `null` arguments
  /// MEAN "no change" — to clear a field, use [clearFirstTriggeredAt] /
  /// dedicated factories. Two-flag pattern (an explicit `clearXxx`
  /// boolean) is overkill for two fields; callers that need to clear use
  /// the named constructor below.
  InterventionAnchors copyWith({
    DateTime? lastTriggeredAt,
    DateTime? firstTriggeredAt,
  }) => InterventionAnchors(
    lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    firstTriggeredAt: firstTriggeredAt ?? this.firstTriggeredAt,
  );

  /// Returns a copy with `firstTriggeredAt` set to `null` and
  /// `lastTriggeredAt` preserved. Used by the lifecycle clear path.
  InterventionAnchors withClearedFirst() =>
      InterventionAnchors(lastTriggeredAt: lastTriggeredAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionAnchors &&
          lastTriggeredAt == other.lastTriggeredAt &&
          firstTriggeredAt == other.firstTriggeredAt;

  @override
  int get hashCode => Object.hash(lastTriggeredAt, firstTriggeredAt);

  @override
  String toString() =>
      'InterventionAnchors(last=$lastTriggeredAt, first=$firstTriggeredAt)';
}

/// Failure modes for the anchor store. Sealed for exhaustive switch.
sealed class InterventionStateFailure extends Failure {
  const InterventionStateFailure({required super.message});

  const factory InterventionStateFailure.network() = _Network;
  const factory InterventionStateFailure.permission() = _Permission;
  const factory InterventionStateFailure.unknown(Object? cause) = _Unknown;
}

class _Network extends InterventionStateFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Permission extends InterventionStateFailure {
  const _Permission() : super(message: 'Permission denied.');
}

class _Unknown extends InterventionStateFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
