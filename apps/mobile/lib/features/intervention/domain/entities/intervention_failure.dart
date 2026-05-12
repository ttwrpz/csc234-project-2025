import 'package:core/core.dart';

/// All failure modes the dispatcher / cooldown guard / record writer can
/// surface to a caller. Sealed so callers pattern-match exhaustively.
///
/// `cooldown` is informational, not an error — it appears here because the
/// `DispatchInterventionUseCase` returns `Result<InterventionDispatch,
/// InterventionFailure>` and a cooldown-blocked dispatch is a non-emission
/// path the controller needs to render as "no banner this time" rather than
/// surfacing a banner with a dispatch payload.
sealed class InterventionFailure extends Failure {
  const InterventionFailure({required super.message});

  /// 24h or 48h gate blocked the dispatch. The `reason` flags which.
  const factory InterventionFailure.cooldown(CooldownBlock reason) = _Cooldown;

  /// The user disabled this tier in Settings (or all tiers).
  const factory InterventionFailure.tierDisabled() = _TierDisabled;

  /// Anchor read failed AND the mirror was also empty. Caller should treat
  /// the gate as closed (do not dispatch) to avoid a re-nag loop on a flapping
  /// network — Tier 3 is the floor, never a fallback for an unknown state.
  const factory InterventionFailure.anchorReadFailed() = _AnchorReadFailed;

  /// Catch-all wrapped exception. The dispatcher never lets a raw exception
  /// cross the domain boundary.
  const factory InterventionFailure.unknown(Object? cause) = _Unknown;
}

/// Why the cooldown gate blocked. Mirrors `BlockReason` on the guard's
/// internal sealed result — repeated here so the use-case caller does not
/// need to import the guard's private types.
enum CooldownBlock { dailyLimit, cooldown48h, optedOut }

class _Cooldown extends InterventionFailure {
  const _Cooldown(this.reason) : super(message: 'Cooldown gate blocked.');
  final CooldownBlock reason;
}

class _TierDisabled extends InterventionFailure {
  const _TierDisabled() : super(message: 'User disabled this tier.');
}

class _AnchorReadFailed extends InterventionFailure {
  const _AnchorReadFailed()
    : super(message: 'Cooldown anchor unavailable; suppressing dispatch.');
}

class _Unknown extends InterventionFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
