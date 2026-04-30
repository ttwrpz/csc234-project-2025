// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarControllerHash() =>
    r'2b826f6a34f0b09c306022c24ba411ffb63f1989';

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

abstract class _$CalendarController
    extends BuildlessAutoDisposeAsyncNotifier<CalendarState> {
  late final DateTime month;

  FutureOr<CalendarState> build(DateTime month);
}

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.
///
/// Copied from [CalendarController].
@ProviderFor(CalendarController)
const calendarControllerProvider = CalendarControllerFamily();

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.
///
/// Copied from [CalendarController].
class CalendarControllerFamily extends Family<AsyncValue<CalendarState>> {
  /// Future-derived [CalendarState] for the requested `month`. The `family`
  /// parameter caches one state per month so prev/next navigation stays
  /// snappy.
  ///
  /// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
  /// underlying mood stream emits, so the calendar stays live without us
  /// touching the deprecated `.stream` accessor.
  ///
  /// Copied from [CalendarController].
  const CalendarControllerFamily();

  /// Future-derived [CalendarState] for the requested `month`. The `family`
  /// parameter caches one state per month so prev/next navigation stays
  /// snappy.
  ///
  /// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
  /// underlying mood stream emits, so the calendar stays live without us
  /// touching the deprecated `.stream` accessor.
  ///
  /// Copied from [CalendarController].
  CalendarControllerProvider call(DateTime month) {
    return CalendarControllerProvider(month);
  }

  @override
  CalendarControllerProvider getProviderOverride(
    covariant CalendarControllerProvider provider,
  ) {
    return call(provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'calendarControllerProvider';
}

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.
///
/// Copied from [CalendarController].
class CalendarControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          CalendarController,
          CalendarState
        > {
  /// Future-derived [CalendarState] for the requested `month`. The `family`
  /// parameter caches one state per month so prev/next navigation stays
  /// snappy.
  ///
  /// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
  /// underlying mood stream emits, so the calendar stays live without us
  /// touching the deprecated `.stream` accessor.
  ///
  /// Copied from [CalendarController].
  CalendarControllerProvider(DateTime month)
    : this._internal(
        () => CalendarController()..month = month,
        from: calendarControllerProvider,
        name: r'calendarControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$calendarControllerHash,
        dependencies: CalendarControllerFamily._dependencies,
        allTransitiveDependencies:
            CalendarControllerFamily._allTransitiveDependencies,
        month: month,
      );

  CalendarControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  FutureOr<CalendarState> runNotifierBuild(
    covariant CalendarController notifier,
  ) {
    return notifier.build(month);
  }

  @override
  Override overrideWith(CalendarController Function() create) {
    return ProviderOverride(
      origin: this,
      override: CalendarControllerProvider._internal(
        () => create()..month = month,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CalendarController, CalendarState>
  createElement() {
    return _CalendarControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarControllerProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CalendarControllerRef
    on AutoDisposeAsyncNotifierProviderRef<CalendarState> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _CalendarControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          CalendarController,
          CalendarState
        >
    with CalendarControllerRef {
  _CalendarControllerProviderElement(super.provider);

  @override
  DateTime get month => (origin as CalendarControllerProvider).month;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
