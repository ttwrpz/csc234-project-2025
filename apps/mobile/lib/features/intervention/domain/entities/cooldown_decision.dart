import 'intervention_failure.dart';

/// Result of [CooldownGuard.check]. Sealed so the dispatcher pattern-matches
/// exhaustively and the analyzer flags an unhandled new variant.
sealed class CooldownDecision {
  const CooldownDecision();
}

/// Gate is open — dispatcher proceeds.
final class Proceed extends CooldownDecision {
  const Proceed();
}

/// Gate is closed — dispatcher returns early. `reason` is surfaced for logs
/// and the controller's "no banner this time" UX path.
final class Blocked extends CooldownDecision {
  const Blocked(this.reason);
  final CooldownBlock reason;
}
