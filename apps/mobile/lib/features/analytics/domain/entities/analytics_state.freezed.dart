// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DailyMoodAggregate {
  DateTime get day => throw _privateConstructorUsedError;
  int get totalEntries => throw _privateConstructorUsedError;
  Map<MoodCategory, double> get meanIntensityByCategory =>
      throw _privateConstructorUsedError;

  /// Create a copy of DailyMoodAggregate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyMoodAggregateCopyWith<DailyMoodAggregate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyMoodAggregateCopyWith<$Res> {
  factory $DailyMoodAggregateCopyWith(
    DailyMoodAggregate value,
    $Res Function(DailyMoodAggregate) then,
  ) = _$DailyMoodAggregateCopyWithImpl<$Res, DailyMoodAggregate>;
  @useResult
  $Res call({
    DateTime day,
    int totalEntries,
    Map<MoodCategory, double> meanIntensityByCategory,
  });
}

/// @nodoc
class _$DailyMoodAggregateCopyWithImpl<$Res, $Val extends DailyMoodAggregate>
    implements $DailyMoodAggregateCopyWith<$Res> {
  _$DailyMoodAggregateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyMoodAggregate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? totalEntries = null,
    Object? meanIntensityByCategory = null,
  }) {
    return _then(
      _value.copyWith(
            day: null == day
                ? _value.day
                : day // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            totalEntries: null == totalEntries
                ? _value.totalEntries
                : totalEntries // ignore: cast_nullable_to_non_nullable
                      as int,
            meanIntensityByCategory: null == meanIntensityByCategory
                ? _value.meanIntensityByCategory
                : meanIntensityByCategory // ignore: cast_nullable_to_non_nullable
                      as Map<MoodCategory, double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyMoodAggregateImplCopyWith<$Res>
    implements $DailyMoodAggregateCopyWith<$Res> {
  factory _$$DailyMoodAggregateImplCopyWith(
    _$DailyMoodAggregateImpl value,
    $Res Function(_$DailyMoodAggregateImpl) then,
  ) = __$$DailyMoodAggregateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime day,
    int totalEntries,
    Map<MoodCategory, double> meanIntensityByCategory,
  });
}

/// @nodoc
class __$$DailyMoodAggregateImplCopyWithImpl<$Res>
    extends _$DailyMoodAggregateCopyWithImpl<$Res, _$DailyMoodAggregateImpl>
    implements _$$DailyMoodAggregateImplCopyWith<$Res> {
  __$$DailyMoodAggregateImplCopyWithImpl(
    _$DailyMoodAggregateImpl _value,
    $Res Function(_$DailyMoodAggregateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyMoodAggregate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? totalEntries = null,
    Object? meanIntensityByCategory = null,
  }) {
    return _then(
      _$DailyMoodAggregateImpl(
        day: null == day
            ? _value.day
            : day // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        totalEntries: null == totalEntries
            ? _value.totalEntries
            : totalEntries // ignore: cast_nullable_to_non_nullable
                  as int,
        meanIntensityByCategory: null == meanIntensityByCategory
            ? _value._meanIntensityByCategory
            : meanIntensityByCategory // ignore: cast_nullable_to_non_nullable
                  as Map<MoodCategory, double>,
      ),
    );
  }
}

/// @nodoc

class _$DailyMoodAggregateImpl implements _DailyMoodAggregate {
  const _$DailyMoodAggregateImpl({
    required this.day,
    required this.totalEntries,
    required final Map<MoodCategory, double> meanIntensityByCategory,
  }) : _meanIntensityByCategory = meanIntensityByCategory;

  @override
  final DateTime day;
  @override
  final int totalEntries;
  final Map<MoodCategory, double> _meanIntensityByCategory;
  @override
  Map<MoodCategory, double> get meanIntensityByCategory {
    if (_meanIntensityByCategory is EqualUnmodifiableMapView)
      return _meanIntensityByCategory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_meanIntensityByCategory);
  }

  @override
  String toString() {
    return 'DailyMoodAggregate(day: $day, totalEntries: $totalEntries, meanIntensityByCategory: $meanIntensityByCategory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyMoodAggregateImpl &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.totalEntries, totalEntries) ||
                other.totalEntries == totalEntries) &&
            const DeepCollectionEquality().equals(
              other._meanIntensityByCategory,
              _meanIntensityByCategory,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    day,
    totalEntries,
    const DeepCollectionEquality().hash(_meanIntensityByCategory),
  );

  /// Create a copy of DailyMoodAggregate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyMoodAggregateImplCopyWith<_$DailyMoodAggregateImpl> get copyWith =>
      __$$DailyMoodAggregateImplCopyWithImpl<_$DailyMoodAggregateImpl>(
        this,
        _$identity,
      );
}

abstract class _DailyMoodAggregate implements DailyMoodAggregate {
  const factory _DailyMoodAggregate({
    required final DateTime day,
    required final int totalEntries,
    required final Map<MoodCategory, double> meanIntensityByCategory,
  }) = _$DailyMoodAggregateImpl;

  @override
  DateTime get day;
  @override
  int get totalEntries;
  @override
  Map<MoodCategory, double> get meanIntensityByCategory;

  /// Create a copy of DailyMoodAggregate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyMoodAggregateImplCopyWith<_$DailyMoodAggregateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AnalyticsState {
  MoodWindow get window => throw _privateConstructorUsedError;
  List<DailyMoodAggregate> get days => throw _privateConstructorUsedError;

  /// Create a copy of AnalyticsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalyticsStateCopyWith<AnalyticsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsStateCopyWith<$Res> {
  factory $AnalyticsStateCopyWith(
    AnalyticsState value,
    $Res Function(AnalyticsState) then,
  ) = _$AnalyticsStateCopyWithImpl<$Res, AnalyticsState>;
  @useResult
  $Res call({MoodWindow window, List<DailyMoodAggregate> days});
}

/// @nodoc
class _$AnalyticsStateCopyWithImpl<$Res, $Val extends AnalyticsState>
    implements $AnalyticsStateCopyWith<$Res> {
  _$AnalyticsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalyticsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? window = null, Object? days = null}) {
    return _then(
      _value.copyWith(
            window: null == window
                ? _value.window
                : window // ignore: cast_nullable_to_non_nullable
                      as MoodWindow,
            days: null == days
                ? _value.days
                : days // ignore: cast_nullable_to_non_nullable
                      as List<DailyMoodAggregate>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnalyticsStateImplCopyWith<$Res>
    implements $AnalyticsStateCopyWith<$Res> {
  factory _$$AnalyticsStateImplCopyWith(
    _$AnalyticsStateImpl value,
    $Res Function(_$AnalyticsStateImpl) then,
  ) = __$$AnalyticsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MoodWindow window, List<DailyMoodAggregate> days});
}

/// @nodoc
class __$$AnalyticsStateImplCopyWithImpl<$Res>
    extends _$AnalyticsStateCopyWithImpl<$Res, _$AnalyticsStateImpl>
    implements _$$AnalyticsStateImplCopyWith<$Res> {
  __$$AnalyticsStateImplCopyWithImpl(
    _$AnalyticsStateImpl _value,
    $Res Function(_$AnalyticsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnalyticsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? window = null, Object? days = null}) {
    return _then(
      _$AnalyticsStateImpl(
        window: null == window
            ? _value.window
            : window // ignore: cast_nullable_to_non_nullable
                  as MoodWindow,
        days: null == days
            ? _value._days
            : days // ignore: cast_nullable_to_non_nullable
                  as List<DailyMoodAggregate>,
      ),
    );
  }
}

/// @nodoc

class _$AnalyticsStateImpl extends _AnalyticsState {
  const _$AnalyticsStateImpl({
    required this.window,
    required final List<DailyMoodAggregate> days,
  }) : _days = days,
       super._();

  @override
  final MoodWindow window;
  final List<DailyMoodAggregate> _days;
  @override
  List<DailyMoodAggregate> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'AnalyticsState(window: $window, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsStateImpl &&
            (identical(other.window, window) || other.window == window) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    window,
    const DeepCollectionEquality().hash(_days),
  );

  /// Create a copy of AnalyticsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsStateImplCopyWith<_$AnalyticsStateImpl> get copyWith =>
      __$$AnalyticsStateImplCopyWithImpl<_$AnalyticsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AnalyticsState extends AnalyticsState {
  const factory _AnalyticsState({
    required final MoodWindow window,
    required final List<DailyMoodAggregate> days,
  }) = _$AnalyticsStateImpl;
  const _AnalyticsState._() : super._();

  @override
  MoodWindow get window;
  @override
  List<DailyMoodAggregate> get days;

  /// Create a copy of AnalyticsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalyticsStateImplCopyWith<_$AnalyticsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
