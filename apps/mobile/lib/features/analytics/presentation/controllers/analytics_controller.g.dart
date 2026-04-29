// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analyticsControllerHash() =>
    r'0549a2b8f11965d939775f9fee5cf63293aceb4d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
/// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Copied from [analyticsController].
@ProviderFor(analyticsController)
const analyticsControllerProvider = AnalyticsControllerFamily();

/// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
/// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Copied from [analyticsController].
class AnalyticsControllerFamily extends Family<AsyncValue<AnalyticsState>> {
  /// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
  /// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
  ///
  /// Parameterised by `window` (riverpod_generator family) so each window
  /// selection has its own provider instance — no manual cache invalidation
  /// needed when the user toggles between 7d / 30d / 90d.
  ///
  /// Copied from [analyticsController].
  const AnalyticsControllerFamily();

  /// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
  /// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
  ///
  /// Parameterised by `window` (riverpod_generator family) so each window
  /// selection has its own provider instance — no manual cache invalidation
  /// needed when the user toggles between 7d / 30d / 90d.
  ///
  /// Copied from [analyticsController].
  AnalyticsControllerProvider call(MoodWindow window) {
    return AnalyticsControllerProvider(window);
  }

  @override
  AnalyticsControllerProvider getProviderOverride(
    covariant AnalyticsControllerProvider provider,
  ) {
    return call(provider.window);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'analyticsControllerProvider';
}

/// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
/// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
///
/// Parameterised by `window` (riverpod_generator family) so each window
/// selection has its own provider instance — no manual cache invalidation
/// needed when the user toggles between 7d / 30d / 90d.
///
/// Copied from [analyticsController].
class AnalyticsControllerProvider
    extends AutoDisposeStreamProvider<AnalyticsState> {
  /// Streams an [AnalyticsState] for the requested [MoodWindow]. The chart
  /// re-renders whenever new mood entries arrive on `myMoodsStreamProvider`.
  ///
  /// Parameterised by `window` (riverpod_generator family) so each window
  /// selection has its own provider instance — no manual cache invalidation
  /// needed when the user toggles between 7d / 30d / 90d.
  ///
  /// Copied from [analyticsController].
  AnalyticsControllerProvider(MoodWindow window)
    : this._internal(
        (ref) => analyticsController(ref as AnalyticsControllerRef, window),
        from: analyticsControllerProvider,
        name: r'analyticsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$analyticsControllerHash,
        dependencies: AnalyticsControllerFamily._dependencies,
        allTransitiveDependencies:
            AnalyticsControllerFamily._allTransitiveDependencies,
        window: window,
      );

  AnalyticsControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.window,
  }) : super.internal();

  final MoodWindow window;

  @override
  Override overrideWith(
    Stream<AnalyticsState> Function(AnalyticsControllerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnalyticsControllerProvider._internal(
        (ref) => create(ref as AnalyticsControllerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        window: window,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<AnalyticsState> createElement() {
    return _AnalyticsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsControllerProvider && other.window == window;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, window.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnalyticsControllerRef on AutoDisposeStreamProviderRef<AnalyticsState> {
  /// The parameter `window` of this provider.
  MoodWindow get window;
}

class _AnalyticsControllerProviderElement
    extends AutoDisposeStreamProviderElement<AnalyticsState>
    with AnalyticsControllerRef {
  _AnalyticsControllerProviderElement(super.provider);

  @override
  MoodWindow get window => (origin as AnalyticsControllerProvider).window;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
