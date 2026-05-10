import 'package:core/core.dart';

/// All failure modes for the Pattern Engine data layer.
///
/// Sealed so consumers that switch on the variants get exhaustive-switch help
/// from the analyzer. Extends [Failure] directly (NOT `MoodFailure`) — pattern
/// engine failures are conceptually distinct from mood-entity failures.
///
/// Narrow on purpose: v1.0 only needs surface for "the write failed and the
/// next render should not assume it succeeded." Match the shape of
/// `apps/mobile/lib/features/mood/domain/ai_analysis_failure.dart`.
///
/// Imports only `package:core/core.dart` — domain-purity rule per CLAUDE.md.
sealed class PatternFailure extends Failure {
  const PatternFailure({required super.message});

  const factory PatternFailure.unknown(String message) = _Unknown;
  const factory PatternFailure.network() = _Network;
  const factory PatternFailure.permissionDenied() = _PermissionDenied;
}

class _Unknown extends PatternFailure {
  const _Unknown(String message) : super(message: message);
}

class _Network extends PatternFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _PermissionDenied extends PatternFailure {
  const _PermissionDenied()
    : super(message: 'Pattern document is not readable for this user.');
}
