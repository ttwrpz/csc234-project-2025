import 'package:freezed_annotation/freezed_annotation.dart';

part 'intervention_state.freezed.dart';

/// Result of [detectPattern]. Consumed by the cheer-up banner; the garden
/// screen itself does NOT show any UI for this state — the detector reports
/// it via Riverpod for downstream consumers only.
///
/// `reason` is one of:
///  * `'5_of_7_negative'` — five distinct days in the last seven contained
///    at least one non-positive entry.
///  * `'3_consecutive_high_intensity'` — last three distinct days each
///    contained at least one negative entry with intensity ≥ 4.
///  * `'cooldown'` — a previous trigger fired within the past 48h; suppress.
///  * `'none'` — no qualifying pattern.
@freezed
abstract class InterventionState with _$InterventionState {
  const factory InterventionState({
    required bool triggered,
    required bool escalated,
    required String reason,
  }) = _InterventionState;

  /// Convenience constructor for the no-trigger case.
  factory InterventionState.none() => const InterventionState(
    triggered: false,
    escalated: false,
    reason: 'none',
  );
}
