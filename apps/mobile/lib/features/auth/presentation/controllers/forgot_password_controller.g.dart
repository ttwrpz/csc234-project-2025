// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for the forgot-password screen. Holds the email input
/// state, dispatches the use case, and surfaces a single inline error
/// message on failure. Success flips `isSent` so the view swaps the
/// form for a confirmation panel.

@ProviderFor(ForgotPasswordController)
final forgotPasswordControllerProvider = ForgotPasswordControllerProvider._();

/// Controller for the forgot-password screen. Holds the email input
/// state, dispatches the use case, and surfaces a single inline error
/// message on failure. Success flips `isSent` so the view swaps the
/// form for a confirmation panel.
final class ForgotPasswordControllerProvider
    extends $NotifierProvider<ForgotPasswordController, ForgotPasswordState> {
  /// Controller for the forgot-password screen. Holds the email input
  /// state, dispatches the use case, and surfaces a single inline error
  /// message on failure. Success flips `isSent` so the view swaps the
  /// form for a confirmation panel.
  ForgotPasswordControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordControllerHash();

  @$internal
  @override
  ForgotPasswordController create() => ForgotPasswordController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForgotPasswordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForgotPasswordState>(value),
    );
  }
}

String _$forgotPasswordControllerHash() =>
    r'd2a29f9a724a4985eea78f8be345077e6bf32298';

/// Controller for the forgot-password screen. Holds the email input
/// state, dispatches the use case, and surfaces a single inline error
/// message on failure. Success flips `isSent` so the view swaps the
/// form for a confirmation panel.

abstract class _$ForgotPasswordController
    extends $Notifier<ForgotPasswordState> {
  ForgotPasswordState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ForgotPasswordState, ForgotPasswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForgotPasswordState, ForgotPasswordState>,
              ForgotPasswordState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
