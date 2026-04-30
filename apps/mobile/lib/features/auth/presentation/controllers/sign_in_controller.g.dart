// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$signInControllerHash() => r'e75ef93896d23ba3a2bfeef541418717a7bb183f';

/// Controller for [SignInScreen]. Holds form state, drives the use cases,
/// and surfaces a friendly error message on failure.
///
/// Navigation on success is handled by the router's `refreshListenable` —
/// the controller does NOT call `context.go`. When auth state flips to
/// non-null, the router redirects from `/sign-in` to `/home` automatically.
///
/// Copied from [SignInController].
@ProviderFor(SignInController)
final signInControllerProvider =
    AutoDisposeNotifierProvider<SignInController, SignInState>.internal(
      SignInController.new,
      name: r'signInControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$signInControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SignInController = AutoDisposeNotifier<SignInState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
