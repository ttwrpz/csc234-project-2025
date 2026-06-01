import 'package:freezed_annotation/freezed_annotation.dart';

part 'cheer_up_state.freezed.dart';

/// UI state for the cheer-up banner. Two flags only - neither is
/// persisted; both reset on app launch.
///
///  * `bannerDismissed` - session-scoped hide flag for the banner. The
///    user tapping "Not now" toggles this; the next app launch shows the
///    banner again iff the detector still reports `triggered: true` AND
///    the 48h cooldown gate (driven by `lastTriggeredAt`) hasn't fired.
///    The cooldown gate is the source of truth for suppression - this
///    flag is purely a session-level UX nicety so the user isn't nagged
///    by the same banner twice in one sitting.
///  * `onShownDispatched` - idempotency guard for `onShown()`. The
///    Garden screen's `addPostFrameCallback` may run multiple times per
///    app launch (e.g. after rebuilds); the controller no-ops on the
///    second call so we don't write the anchors twice.
@freezed
abstract class CheerUpUiState with _$CheerUpUiState {
  const factory CheerUpUiState({
    required bool bannerDismissed,
    required bool onShownDispatched,
  }) = _CheerUpUiState;
}
