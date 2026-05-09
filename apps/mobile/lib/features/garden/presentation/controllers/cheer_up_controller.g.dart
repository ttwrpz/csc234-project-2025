// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheer_up_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(CheerUpController)
final cheerUpControllerProvider = CheerUpControllerProvider._();

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
final class CheerUpControllerProvider
    extends $NotifierProvider<CheerUpController, CheerUpUiState> {
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
  CheerUpControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cheerUpControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cheerUpControllerHash();

  @$internal
  @override
  CheerUpController create() => CheerUpController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheerUpUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheerUpUiState>(value),
    );
  }
}

String _$cheerUpControllerHash() => r'c68e6b7dbe1abd0ca1b194188da615a1084a050a';

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

abstract class _$CheerUpController extends $Notifier<CheerUpUiState> {
  CheerUpUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CheerUpUiState, CheerUpUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheerUpUiState, CheerUpUiState>,
              CheerUpUiState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
