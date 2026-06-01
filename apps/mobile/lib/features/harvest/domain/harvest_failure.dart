import 'package:core/core.dart';

/// All failure modes for the Weekly Harvest data layer.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch help
/// from the analyzer. Extends [Failure] directly - harvest failures are
/// conceptually distinct from mood-entity or pattern-engine failures.
///
/// Imports only `package:core/core.dart` - domain-purity rule per CLAUDE.md.
sealed class HarvestFailure extends Failure {
  const HarvestFailure({required super.message});

  const factory HarvestFailure.unknown(String message) = _Unknown;
  const factory HarvestFailure.network() = _Network;
  const factory HarvestFailure.permissionDenied() = _PermissionDenied;
  const factory HarvestFailure.alreadyArchived(String weekId) =
      _AlreadyArchived;
  const factory HarvestFailure.noEntries() = _NoEntries;

  /// True when Firestore reported the week's archive already exists.
  /// This is a benign cross-device race: another device wrote the
  /// canonical archive while this device still had the week marked as
  /// pending in its local cache. Presentation treats it as a success
  /// path (close the popup) rather than a recoverable error.
  bool get isAlreadyArchived => this is _AlreadyArchived;
}

class _Unknown extends HarvestFailure {
  const _Unknown(String message) : super(message: message);
}

class _Network extends HarvestFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _PermissionDenied extends HarvestFailure {
  const _PermissionDenied()
    : super(message: 'Weekly garden archive is not readable for this user.');
}

class _AlreadyArchived extends HarvestFailure {
  const _AlreadyArchived(this.weekId)
    : super(message: 'Week has already been harvested.');

  final String weekId;
}

class _NoEntries extends HarvestFailure {
  const _NoEntries()
    : super(message: 'No entries this week - nothing to summarise yet.');
}
