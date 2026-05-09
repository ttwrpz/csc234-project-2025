import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers.dart';
import '../../data/providers.dart';
import 'cheer_up_state.dart';

part 'cheer_up_controller.g.dart';

/// Controller for the cheer-up banner (HB-003 §5.5a + §5.5b).
///
/// Owns the banner's transient UI state (session-scoped dismissal +
/// onShown idempotency) and orchestrates two writes when the detector
/// flips to triggered:
///   1. The cooldown / escalation anchors via [InterventionStateRepository]
///      (5.5a — `lastTriggeredAt`, `firstTriggeredAt`).
///   2. The audit-log event via [CheerUpEventsRepository] (5.5b — the
///      `users/{uid}/cheerUpEvents/{dayUtc}-{reason}` doc-create that
///      fires the `sendCheerUpPush` Cloud Function).
///
/// The 48h-cooldown gate that suppresses the next trigger is owned by
/// `lastTriggeredAt` in the anchor repo, NOT by
/// [CheerUpUiState.bannerDismissed]; the dismissed flag only hides the
/// banner for the rest of the current app launch.
///
/// Failure independence: the anchor write and the event-doc create are
/// independent. If the anchor write fails (network), the event-doc
/// create still attempts — the CF only needs the event doc to fire its
/// trigger, the anchors live elsewhere. If the event-doc create fails
/// on `already-exists`, the impl swallows it and we treat as success
/// (idempotent path — the trigger already fired earlier today).
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
  /// Writes happen in this order:
  ///   1. `lastTriggeredAt = now` (always overwrites)
  ///   2. `firstTriggeredAt = now` ONLY IF currently null (transactional
  ///      inside the repo — race-free across multiple devices)
  ///   3. `cheerUpEvents/{dayUtc}-{reason}` create (idempotent;
  ///      already-exists is swallowed as success)
  ///
  /// Step 3 is what the Cloud Function trigger fires on. Steps 1+2
  /// failing does NOT block step 3 — the CF only needs the event doc.
  Future<void> onShown({required String reason}) async {
    if (state.onShownDispatched) return;
    const logger = Logger('garden.cheerup.controller');

    // Remote-Config gate (ADR-0011 §4). When v1.0's
    // `interventionDispatchEnabled` flag is false, the legacy 2-rule
    // dispatcher is dark — no anchor writes, no audit-log event, no
    // FCM push. The new Pattern Engine writes
    // `users/{uid}/patterns/{date}` independently upstream. Sprint 5
    // re-points the dispatcher at that document, attaches the Quote
    // Library safety filter + Bipolar/medical disclaimer footer, and
    // flips the flag to true. Until then, this early-return is the
    // single difference between "engine on, dispatcher off" (v1.0)
    // and "engine on, dispatcher on" (S5).
    final flags = ref.read(featureFlagsProvider);
    if (!flags.interventionDispatchEnabled) {
      logger.info(
        'cheer_up_dispatch_skipped',
        data: const {'reason': 'flag_disabled'},
      );
      // Mark dispatched so a re-entrant call in the same lifecycle
      // does not log the skip event repeatedly. The flag itself is
      // the durable gate; this flip is purely UI-state hygiene.
      state = state.copyWith(onShownDispatched: true);
      return;
    }

    // Flip the flag BEFORE the awaits so a re-entrant rebuild can't
    // race-fire a second dispatch while the first is in flight.
    state = state.copyWith(onShownDispatched: true);

    final repo = await ref.read(interventionStateRepositoryProvider.future);
    final eventsRepo = ref.read(cheerUpEventsRepositoryProvider);
    final now = DateTime.now();

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

    // 5.5b — idempotent event-doc create. Independent of anchor writes
    // above: if the cloud is reachable for ONE of the two it's almost
    // certainly reachable for both, but failure of the anchor writes
    // must not block this — the CF only triggers on the event doc.
    final eventResult = await eventsRepo.createEvent(reason: reason, now: now);
    if (eventResult is Err) {
      logger.warn('cheerUpEvents createEvent failed; CF will not fire');
    }

    // Force the read-side anchor cache to recompute so the next
    // detector evaluation sees the freshly-written cooldown.
    ref.invalidate(interventionAnchorsProvider);
  }

  /// Session-scoped hide of the banner. Does NOT clear cooldown — the
  /// 48h gate is owned by `lastTriggeredAt`, not by this flag.
  void onDismissed() => state = state.copyWith(bannerDismissed: true);
}
