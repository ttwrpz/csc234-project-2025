// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
/// The chart re-renders whenever new mood entries arrive on
/// `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
/// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
/// pure use case, mirroring the `gardenStateStreamProvider` shape.

@ProviderFor(analyticsController)
final analyticsControllerProvider = AnalyticsControllerFamily._();

/// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
/// The chart re-renders whenever new mood entries arrive on
/// `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
/// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
/// pure use case, mirroring the `gardenStateStreamProvider` shape.

final class AnalyticsControllerProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalyticsState>,
          AsyncValue<AnalyticsState>,
          AsyncValue<AnalyticsState>
        >
    with $Provider<AsyncValue<AnalyticsState>> {
  /// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
  /// The chart re-renders whenever new mood entries arrive on
  /// `myMoodsStreamProvider`.
  ///
  /// Parameterised by `window` (riverpod_generator family) so each window
  /// selection has its own provider instance — no manual cache invalidation
  /// needed when the user toggles between 7d / 30d / 90d.
  ///
  /// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
  /// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
  /// pure use case, mirroring the `gardenStateStreamProvider` shape.
  AnalyticsControllerProvider._({
    required AnalyticsControllerFamily super.from,
    required MoodWindow super.argument,
  }) : super(
         retry: null,
         name: r'analyticsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analyticsControllerHash();

  @override
  String toString() {
    return r'analyticsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AnalyticsState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AnalyticsState> create(Ref ref) {
    final argument = this.argument as MoodWindow;
    return analyticsController(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AnalyticsState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AnalyticsState>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analyticsControllerHash() =>
    r'17d8f529a7b68b7a70fb8e99ae30674c299b32c2';

/// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
/// The chart re-renders whenever new mood entries arrive on
/// `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
/// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
/// pure use case, mirroring the `gardenStateStreamProvider` shape.

final class AnalyticsControllerFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<AnalyticsState>, MoodWindow> {
  AnalyticsControllerFamily._()
    : super(
        retry: null,
        name: r'analyticsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns an `AsyncValue<AnalyticsState>` for the requested [MoodWindow].
  /// The chart re-renders whenever new mood entries arrive on
  /// `myMoodsStreamProvider`.
  ///
  /// Parameterised by `window` (riverpod_generator family) so each window
  /// selection has its own provider instance — no manual cache invalidation
  /// needed when the user toggles between 7d / 30d / 90d.
  ///
  /// Riverpod 3: `StreamProvider.stream` was removed. We watch the upstream
  /// `AsyncValue<List<MoodEntry>>` directly and `whenData` it through the
  /// pure use case, mirroring the `gardenStateStreamProvider` shape.

  AnalyticsControllerProvider call(MoodWindow window) =>
      AnalyticsControllerProvider._(argument: window, from: this);

  @override
  String toString() => r'analyticsControllerProvider';
}
