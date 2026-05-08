// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheer_up_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(CheerUpController)
final cheerUpControllerProvider = CheerUpControllerProvider._();

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
final class CheerUpControllerProvider
    extends $NotifierProvider<CheerUpController, CheerUpUiState> {
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

String _$cheerUpControllerHash() => r'e58afccd4aa5f35592879f79ec9ba86be827b5f9';

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
