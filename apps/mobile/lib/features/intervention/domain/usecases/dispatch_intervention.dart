import 'package:core/core.dart';

import '../../../garden/domain/intervention_state_repository.dart';
import '../../../pattern_engine/domain/entities/tier.dart';
import '../entities/cooldown_decision.dart';
import '../entities/intervention_dispatch.dart';
import '../entities/intervention_failure.dart';
import '../entities/intervention_record.dart';
import '../entities/quote_context.dart';
import '../repositories/intervention_repository.dart';
import '../services/cooldown_guard.dart';
import '../services/tiered_intervention_dispatcher.dart';

/// Orchestrates one tier triggering:
///   1. Run [CooldownGuard.check] — if blocked, return early.
///   2. Build the [InterventionDispatch] via [TieredInterventionDispatcher].
///   3. Persist the audit record + advance the cooldown anchor (best-effort
///      — a write failure is logged but does not invalidate the in-memory
///      dispatch the controller renders).
///
/// The order is intentional: render-then-persist is more robust than
/// persist-then-render because a Firestore-write failure should not block
/// the user from seeing their banner. The next successful dispatch read
/// from the anchor will reconcile; if the anchor write also failed, the
/// 48h gate may surface a duplicate dispatch tomorrow — acceptable
/// degradation, much better than a missing intervention at the user's
/// hardest moment.
///
/// Pure-Dart use case — no Flutter, no Firebase. Composition is wired by
/// the Riverpod provider in `data/providers.dart`.
class DispatchInterventionUseCase {
  const DispatchInterventionUseCase({
    required this.dispatcher,
    required this.cooldownGuard,
    required this.interventionRepository,
    required this.stateRepository,
    required this.cooldownWindow,
  });

  final TieredInterventionDispatcher dispatcher;
  final CooldownGuard cooldownGuard;
  final InterventionRepository interventionRepository;
  final InterventionStateRepository stateRepository;

  /// Persisted on the audit record so admin tooling does not re-derive it
  /// from the anchor doc. Should match `CooldownGuard.cooldownWindow` at
  /// wire-up time. Injected so a future tier-specific window can flow
  /// through without surgery here.
  final Duration cooldownWindow;

  Future<Result<InterventionDispatch, InterventionFailure>> call({
    required Tier tier,
    required QuoteContext context,
  }) async {
    final gate = await cooldownGuard.check();
    if (gate is Blocked) {
      return Err(InterventionFailure.cooldown(gate.reason));
    }

    final dispatched = await dispatcher.dispatch(tier: tier, context: context);
    final payload = dispatched.getOrNull();
    if (payload == null) {
      // dispatcher already logged the underlying cause.
      return Err(
        dispatched.errOrNull() ?? const InterventionFailure.unknown(null),
      );
    }

    // Best-effort persistence — the user-visible banner is the in-memory
    // payload; the audit row and anchor write are background bookkeeping.
    final record = InterventionRecord(
      dispatchId: payload.dispatchId,
      tier: payload.tier,
      dispatchedAt: payload.dispatchedAt,
      quoteId: payload.quoteId,
      cooldownUntil: payload.dispatchedAt.add(cooldownWindow),
    );
    await interventionRepository.writeRecord(record);
    await stateRepository.writeLastTriggeredAt(payload.dispatchedAt);

    return Ok(payload);
  }
}
