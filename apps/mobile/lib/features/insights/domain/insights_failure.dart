import 'package:core/core.dart';

/// All failure modes the Insights read path can surface.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch
/// help from the analyzer. Extends [Failure] directly — Insights failures
/// are conceptually distinct from mood / pattern / disclaimer failures
/// even when the underlying cause is the same Firestore exception.
///
/// Imports only `package:core/core.dart` — domain-purity rule per
/// CLAUDE.md.
sealed class InsightsFailure extends Failure {
  const InsightsFailure({required super.message});

  const factory InsightsFailure.noData() = _NoData;
  const factory InsightsFailure.network() = _Network;
  const factory InsightsFailure.unknown(String message) = _Unknown;
}

class _NoData extends InsightsFailure {
  const _NoData() : super(message: 'No insights available for this window.');
}

class _Network extends InsightsFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Unknown extends InsightsFailure {
  const _Unknown(String message) : super(message: message);
}
