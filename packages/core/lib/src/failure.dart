/// Base type for all domain failures.
///
/// Feature-specific failures (e.g. `MoodFailure`) live in their feature's
/// `domain/` folder and may extend [Failure] directly. The concrete classes
/// below are generic enough to be useful from anywhere.
abstract class Failure {
  const Failure({required this.message});

  /// Human-readable message safe to surface in logs. Never include PII.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// Network is unreachable or timed out.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network unavailable.'});
}

/// Remote service responded with an error.
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Catch-all for unexpected exceptions. Wraps the original [cause] so callers
/// can decide whether to log it.
class UnknownFailure extends Failure {
  const UnknownFailure({this.cause, super.message = 'Something went wrong.'});
  final Object? cause;
}
