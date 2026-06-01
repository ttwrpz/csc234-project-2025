// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_visibility_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SharedPreferences-backed controller for the "Show token balance"
/// Settings toggle. Default `true`.
///
/// Anti-pattern guardrail: visibility is OPTIONAL - the user can hide
/// the chip without forfeiting tokens. Tokens still accumulate in the
/// background; only the chip render is suppressed.
///
/// `build()` returns the synchronous default `true` so the first frame
/// renders without a flicker. The async hydration from prefs runs in
/// the background; if the user previously chose to hide the chip, the
/// state flips to `false` once prefs resolve. Tests can override the
/// `sharedPreferencesProvider` to pre-seed a value.
///
/// Mirrors `theme_mode_storage.dart`'s storage shape (single string-
/// keyed bool) but the controller itself is `@riverpod` for the
/// codegen-friendly notifier surface.

@ProviderFor(TokenVisibility)
final tokenVisibilityProvider = TokenVisibilityProvider._();

/// SharedPreferences-backed controller for the "Show token balance"
/// Settings toggle. Default `true`.
///
/// Anti-pattern guardrail: visibility is OPTIONAL - the user can hide
/// the chip without forfeiting tokens. Tokens still accumulate in the
/// background; only the chip render is suppressed.
///
/// `build()` returns the synchronous default `true` so the first frame
/// renders without a flicker. The async hydration from prefs runs in
/// the background; if the user previously chose to hide the chip, the
/// state flips to `false` once prefs resolve. Tests can override the
/// `sharedPreferencesProvider` to pre-seed a value.
///
/// Mirrors `theme_mode_storage.dart`'s storage shape (single string-
/// keyed bool) but the controller itself is `@riverpod` for the
/// codegen-friendly notifier surface.
final class TokenVisibilityProvider
    extends $NotifierProvider<TokenVisibility, bool> {
  /// SharedPreferences-backed controller for the "Show token balance"
  /// Settings toggle. Default `true`.
  ///
  /// Anti-pattern guardrail: visibility is OPTIONAL - the user can hide
  /// the chip without forfeiting tokens. Tokens still accumulate in the
  /// background; only the chip render is suppressed.
  ///
  /// `build()` returns the synchronous default `true` so the first frame
  /// renders without a flicker. The async hydration from prefs runs in
  /// the background; if the user previously chose to hide the chip, the
  /// state flips to `false` once prefs resolve. Tests can override the
  /// `sharedPreferencesProvider` to pre-seed a value.
  ///
  /// Mirrors `theme_mode_storage.dart`'s storage shape (single string-
  /// keyed bool) but the controller itself is `@riverpod` for the
  /// codegen-friendly notifier surface.
  TokenVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenVisibilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenVisibilityHash();

  @$internal
  @override
  TokenVisibility create() => TokenVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tokenVisibilityHash() => r'ed8c2c8cece9af7c5ade8affd6962b7cb6389df9';

/// SharedPreferences-backed controller for the "Show token balance"
/// Settings toggle. Default `true`.
///
/// Anti-pattern guardrail: visibility is OPTIONAL - the user can hide
/// the chip without forfeiting tokens. Tokens still accumulate in the
/// background; only the chip render is suppressed.
///
/// `build()` returns the synchronous default `true` so the first frame
/// renders without a flicker. The async hydration from prefs runs in
/// the background; if the user previously chose to hide the chip, the
/// state flips to `false` once prefs resolve. Tests can override the
/// `sharedPreferencesProvider` to pre-seed a value.
///
/// Mirrors `theme_mode_storage.dart`'s storage shape (single string-
/// keyed bool) but the controller itself is `@riverpod` for the
/// codegen-friendly notifier surface.

abstract class _$TokenVisibility extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
