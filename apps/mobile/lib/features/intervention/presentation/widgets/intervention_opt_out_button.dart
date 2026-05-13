import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/intervention_controller.dart';

/// Reusable "I'm okay" opt-out button.
///
/// Tapping advances the cooldown anchor + marks the audit row opted-out
/// via [InterventionController.optOut] — so a swipe-out or this tap both
/// route through the controller, which is the only path that may write
/// `lastTriggeredAt` (HB-007 §"Cooldown guard rules").
///
/// [onTapped] runs AFTER the controller's opt-out future resolves so the
/// host screen can `context.pop()` (or otherwise dismiss) only once the
/// audit-doc write has been kicked off. The future is awaited inside the
/// gesture handler to keep the callback ordering deterministic; visual
/// feedback during the brief await is the default Material ripple — no
/// dedicated spinner because the opt-out path is fire-and-forget at the
/// data layer (`InterventionRepository.markOptedOut` is best-effort and
/// any write failure is logged, not surfaced to the user).
class InterventionOptOutButton extends ConsumerWidget {
  const InterventionOptOutButton({
    this.label = "I'm okay",
    this.onTapped,
    super.key,
  });

  /// Visible button text. Defaults to the spec-canonical "I'm okay";
  /// the Tier 3 crisis screen passes "I'm okay for now" because a curt
  /// "I'm okay" can read dismissive at the acute tier.
  final String label;

  /// Optional follow-up callback. Invoked AFTER `controller.optOut()`
  /// resolves so the caller can safely `context.pop()`.
  final VoidCallback? onTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: '$label, dismiss this reminder',
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(interventionControllerProvider.notifier).optOut();
          onTapped?.call();
        },
        child: Text(label),
      ),
    );
  }
}
