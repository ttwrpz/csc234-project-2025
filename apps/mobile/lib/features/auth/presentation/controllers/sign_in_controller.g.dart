// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for [SignInScreen]. Holds form state, drives the use cases,
/// and surfaces a friendly error message on failure.
///
/// Navigation on success is handled by the router's `refreshListenable` —
/// the controller does NOT call `context.go`. When auth state flips to
/// non-null, the router redirects from `/sign-in` to `/home` automatically.

@ProviderFor(SignInController)
final signInControllerProvider = SignInControllerProvider._();

/// Controller for [SignInScreen]. Holds form state, drives the use cases,
/// and surfaces a friendly error message on failure.
///
/// Navigation on success is handled by the router's `refreshListenable` —
/// the controller does NOT call `context.go`. When auth state flips to
/// non-null, the router redirects from `/sign-in` to `/home` automatically.
final class SignInControllerProvider
    extends $NotifierProvider<SignInController, SignInState> {
  /// Controller for [SignInScreen]. Holds form state, drives the use cases,
  /// and surfaces a friendly error message on failure.
  ///
  /// Navigation on success is handled by the router's `refreshListenable` —
  /// the controller does NOT call `context.go`. When auth state flips to
  /// non-null, the router redirects from `/sign-in` to `/home` automatically.
  SignInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInControllerHash();

  @$internal
  @override
  SignInController create() => SignInController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInState>(value),
    );
  }
}

String _$signInControllerHash() => r'e75ef93896d23ba3a2bfeef541418717a7bb183f';

/// Controller for [SignInScreen]. Holds form state, drives the use cases,
/// and surfaces a friendly error message on failure.
///
/// Navigation on success is handled by the router's `refreshListenable` —
/// the controller does NOT call `context.go`. When auth state flips to
/// non-null, the router redirects from `/sign-in` to `/home` automatically.

abstract class _$SignInController extends $Notifier<SignInState> {
  SignInState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SignInState, SignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignInState, SignInState>,
              SignInState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
