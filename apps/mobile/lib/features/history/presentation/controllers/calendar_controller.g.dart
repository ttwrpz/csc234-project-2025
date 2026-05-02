// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.

@ProviderFor(CalendarController)
final calendarControllerProvider = CalendarControllerFamily._();

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.
final class CalendarControllerProvider
    extends $AsyncNotifierProvider<CalendarController, CalendarState> {
  /// Future-derived [CalendarState] for the requested `month`. The `family`
  /// parameter caches one state per month so prev/next navigation stays
  /// snappy.
  ///
  /// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
  /// underlying mood stream emits, so the calendar stays live without us
  /// touching the deprecated `.stream` accessor.
  CalendarControllerProvider._({
    required CalendarControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calendarControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarControllerHash();

  @override
  String toString() {
    return r'calendarControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarController create() => CalendarController();

  @override
  bool operator ==(Object other) {
    return other is CalendarControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarControllerHash() =>
    r'2b826f6a34f0b09c306022c24ba411ffb63f1989';

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.

final class CalendarControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarController,
          AsyncValue<CalendarState>,
          CalendarState,
          FutureOr<CalendarState>,
          DateTime
        > {
  CalendarControllerFamily._()
    : super(
        retry: null,
        name: r'calendarControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Future-derived [CalendarState] for the requested `month`. The `family`
  /// parameter caches one state per month so prev/next navigation stays
  /// snappy.
  ///
  /// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
  /// underlying mood stream emits, so the calendar stays live without us
  /// touching the deprecated `.stream` accessor.

  CalendarControllerProvider call(DateTime month) =>
      CalendarControllerProvider._(argument: month, from: this);

  @override
  String toString() => r'calendarControllerProvider';
}

/// Future-derived [CalendarState] for the requested `month`. The `family`
/// parameter caches one state per month so prev/next navigation stays
/// snappy.
///
/// `ref.watch(myMoodsStreamProvider.future)` re-runs `build` whenever the
/// underlying mood stream emits, so the calendar stays live without us
/// touching the deprecated `.stream` accessor.

abstract class _$CalendarController extends $AsyncNotifier<CalendarState> {
  late final _$args = ref.$arg as DateTime;
  DateTime get month => _$args;

  FutureOr<CalendarState> build(DateTime month);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CalendarState>, CalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CalendarState>, CalendarState>,
              AsyncValue<CalendarState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
