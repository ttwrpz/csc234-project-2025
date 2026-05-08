import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import 'cheer_up_state.dart';

part 'cheer_up_controller.g.dart';

/// Controller for the cheer-up banner (HB-003 §5.5a).
///
/// Owns the banner's transient UI state (session-scoped dismissal +
/// onShown idempotency) and dispatches the cooldown writes through the
/// [InterventionStateRepository]. The 48h-cooldown gate that suppresses
/// the next trigger is owned by `lastTriggeredAt` in the repository, NOT
/// by [CheerUpUiState.bannerDismissed]; the dismissed flag only hides
/// the banner for the rest of the current app launch.
///
/// 5.5b adds the `users/{uid}/cheerUpEvents/{dayUtc}-{reason}` doc-create
/// step on top of `onShown`. This controller's `onShown` does ONLY the
/// repository writes today.
@riverpod
class CheerUpController extends _$CheerUpController {
  @override
  CheerUpUiState build() =>
      const CheerUpUiState(bannerDismissed: false, onShownDispatched: false);

  /// Called from the Garden screen via `addPostFrameCallback` exactly
  /// once per app launch when the upstream detector reports
  /// `triggered: true`. Idempotent: subsequent calls in the same
  /// lifecycle no-op via [CheerUpUiState.onShownDispatched].
  ///
  /// Writes:
  ///   1. `lastTriggeredAt = now` (always overwrites)
  ///   2. `firstTriggeredAt = now` ONLY IF currently null (transactional
  ///      inside the repo — race-free across devices)
  ///
  /// `reason` is captured for symmetry with the 5.5b `cheerUpEvents`
  /// doc-create that lands in the next dispatch; today the field is not
  /// used by the repo (the anchors are reason-agnostic).
  Future<void> onShown({required String reason}) async {
    if (state.onShownDispatched) return;
    // Flip the flag BEFORE the awaits so a re-entrant rebuild can't
    // race-fire a second dispatch while the first is in flight.
    state = state.copyWith(onShownDispatched: true);

    final repo = await ref.read(interventionStateRepositoryProvider.future);
    final now = DateTime.now();

    final logger = const Logger('garden.cheerup.controller');

    final lastResult = await repo.writeLastTriggeredAt(now);
    if (lastResult is Err) {
      // Mirror has been updated regardless inside the impl — the local
      // detector still honours the cooldown gate. Log without PII.
      logger.warn('writeLastTriggeredAt failed; mirror updated locally');
    }

    final firstResult = await repo.writeFirstTriggeredAtIfNull(now);
    if (firstResult is Err) {
      logger.warn('writeFirstTriggeredAtIfNull failed; mirror updated locally');
    }

    // Force the read-side anchor cache to recompute so the next
    // detector evaluation sees the freshly-written cooldown.
    ref.invalidate(interventionAnchorsProvider);
  }

  /// Session-scoped hide of the banner. Does NOT clear cooldown — the
  /// 48h gate is owned by `lastTriggeredAt`, not by this flag.
  void onDismissed() => state = state.copyWith(bannerDismissed: true);
}
