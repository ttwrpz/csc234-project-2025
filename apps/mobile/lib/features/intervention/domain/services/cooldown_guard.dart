import 'package:core/core.dart';

import '../../../garden/domain/intervention_state_repository.dart';
import '../entities/cooldown_decision.dart';
import '../entities/intervention_failure.dart';

/// Stateless cooldown gate. Reads the anchor doc via
/// [InterventionStateRepository] (ADR-0008) and returns a [CooldownDecision].
///
/// Two windows, in priority order (TC-31 then TC-32):
///   * `dailyLimit` — `now - lastTriggeredAt < 24h`. Spec §2.5 "max 1
///     notification per 24h".
///   * `cooldown48h` — `now - lastTriggeredAt < 48h` (but `≥ 24h`). Spec
///     §2.5 "48h between alerts".
///
/// The guard is global across tiers per HB-007 OQ-B default — a Tier 1
/// today blocks a Tier 3 tomorrow if inside 48h. The architect should
/// confirm; flagged in the engineer's handback report.
///
/// Reads only — never writes. The dispatcher writes the new anchor via
/// `InterventionStateRepository.writeLastTriggeredAt` AFTER a successful
/// dispatch, not before — a write-before-dispatch race would block the
/// next legitimate dispatch on a network failure.
///
/// Pure-Dart class — no Flutter / Firebase imports. The repository
/// abstract it depends on lives in the garden feature's `domain/` and is
/// itself pure-Dart per ADR-0008.
class CooldownGuard {
  CooldownGuard({
    required InterventionStateRepository stateRepo,
    required DateTime Function() now,
  }) : _stateRepo = stateRepo,
       _now = now;

  final InterventionStateRepository _stateRepo;
  final DateTime Function() _now;

  /// 24h window — TC-31.
  static const Duration dailyWindow = Duration(hours: 24);

  /// 48h window — TC-32.
  static const Duration cooldownWindow = Duration(hours: 48);

  /// Checks the gate. Returns:
  ///   * `Proceed` when no anchor exists OR the anchor is older than 48h.
  ///   * `Blocked(dailyLimit)` when `now - lastTriggeredAt < 24h`.
  ///   * `Blocked(cooldown48h)` when `24h ≤ now - lastTriggeredAt < 48h`.
  ///
  /// On anchor-read failure (Firestore AND mirror both unavailable) the
  /// guard is FAIL-CLOSED: returns `Blocked(cooldown48h)` so the user is
  /// never re-nagged during a flapping-network state. The dispatcher
  /// distinguishes the failure case via [checkOrError] when it needs to
  /// surface "anchor unavailable" separately.
  Future<CooldownDecision> check() async {
    final read = await _stateRepo.read();
    final anchors = read.getOrNull();
    if (anchors == null) {
      // Both Firestore and the mirror failed. Fail-closed.
      return const Blocked(CooldownBlock.cooldown48h);
    }
    return _decide(anchors.lastTriggeredAt);
  }

  /// Variant that surfaces a distinct `Err(InterventionFailure
  /// .anchorReadFailed())` when the anchor read fails, letting the caller
  /// choose to surface a debug log vs. silently suppress. Same gate logic
  /// otherwise.
  Future<({CooldownDecision? decision, InterventionFailure? failure})>
  checkOrError() async {
    final read = await _stateRepo.read();
    final anchors = read.getOrNull();
    if (anchors == null) {
      return (
        decision: null,
        failure: const InterventionFailure.anchorReadFailed(),
      );
    }
    return (decision: _decide(anchors.lastTriggeredAt), failure: null);
  }

  CooldownDecision _decide(DateTime? lastTriggeredAt) {
    if (lastTriggeredAt == null) {
      return const Proceed();
    }
    final elapsed = _now().difference(lastTriggeredAt);
    if (elapsed.isNegative) {
      // Clock skew — the anchor is in the future. Treat as inside the
      // 48h window (fail-closed). This is the safest read; the next
      // successful sync will normalise.
      return const Blocked(CooldownBlock.cooldown48h);
    }
    if (elapsed < dailyWindow) {
      return const Blocked(CooldownBlock.dailyLimit);
    }
    if (elapsed < cooldownWindow) {
      return const Blocked(CooldownBlock.cooldown48h);
    }
    return const Proceed();
  }
}
