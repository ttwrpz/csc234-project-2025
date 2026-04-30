// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CalendarState {
  DateTime get month => throw _privateConstructorUsedError;
  Map<DateTime, DayDot> get dotsByDay => throw _privateConstructorUsedError;

  /// Create a copy of CalendarState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarStateCopyWith<CalendarState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarStateCopyWith<$Res> {
  factory $CalendarStateCopyWith(
    CalendarState value,
    $Res Function(CalendarState) then,
  ) = _$CalendarStateCopyWithImpl<$Res, CalendarState>;
  @useResult
  $Res call({DateTime month, Map<DateTime, DayDot> dotsByDay});
}

/// @nodoc
class _$CalendarStateCopyWithImpl<$Res, $Val extends CalendarState>
    implements $CalendarStateCopyWith<$Res> {
  _$CalendarStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? month = null, Object? dotsByDay = null}) {
    return _then(
      _value.copyWith(
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dotsByDay: null == dotsByDay
                ? _value.dotsByDay
                : dotsByDay // ignore: cast_nullable_to_non_nullable
                      as Map<DateTime, DayDot>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CalendarStateImplCopyWith<$Res>
    implements $CalendarStateCopyWith<$Res> {
  factory _$$CalendarStateImplCopyWith(
    _$CalendarStateImpl value,
    $Res Function(_$CalendarStateImpl) then,
  ) = __$$CalendarStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime month, Map<DateTime, DayDot> dotsByDay});
}

/// @nodoc
class __$$CalendarStateImplCopyWithImpl<$Res>
    extends _$CalendarStateCopyWithImpl<$Res, _$CalendarStateImpl>
    implements _$$CalendarStateImplCopyWith<$Res> {
  __$$CalendarStateImplCopyWithImpl(
    _$CalendarStateImpl _value,
    $Res Function(_$CalendarStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? month = null, Object? dotsByDay = null}) {
    return _then(
      _$CalendarStateImpl(
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dotsByDay: null == dotsByDay
            ? _value._dotsByDay
            : dotsByDay // ignore: cast_nullable_to_non_nullable
                  as Map<DateTime, DayDot>,
      ),
    );
  }
}

/// @nodoc

class _$CalendarStateImpl extends _CalendarState {
  const _$CalendarStateImpl({
    required this.month,
    required final Map<DateTime, DayDot> dotsByDay,
  }) : _dotsByDay = dotsByDay,
       super._();

  @override
  final DateTime month;
  final Map<DateTime, DayDot> _dotsByDay;
  @override
  Map<DateTime, DayDot> get dotsByDay {
    if (_dotsByDay is EqualUnmodifiableMapView) return _dotsByDay;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_dotsByDay);
  }

  @override
  String toString() {
    return 'CalendarState(month: $month, dotsByDay: $dotsByDay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarStateImpl &&
            (identical(other.month, month) || other.month == month) &&
            const DeepCollectionEquality().equals(
              other._dotsByDay,
              _dotsByDay,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    month,
    const DeepCollectionEquality().hash(_dotsByDay),
  );

  /// Create a copy of CalendarState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarStateImplCopyWith<_$CalendarStateImpl> get copyWith =>
      __$$CalendarStateImplCopyWithImpl<_$CalendarStateImpl>(this, _$identity);
}

abstract class _CalendarState extends CalendarState {
  const factory _CalendarState({
    required final DateTime month,
    required final Map<DateTime, DayDot> dotsByDay,
  }) = _$CalendarStateImpl;
  const _CalendarState._() : super._();

  @override
  DateTime get month;
  @override
  Map<DateTime, DayDot> get dotsByDay;

  /// Create a copy of CalendarState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarStateImplCopyWith<_$CalendarStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DayDot {
  DateTime get day => throw _privateConstructorUsedError;
  MoodCategory get dominantCategory => throw _privateConstructorUsedError;
  int get totalEntries => throw _privateConstructorUsedError;
  String get mostRecentEntryId => throw _privateConstructorUsedError;

  /// Create a copy of DayDot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DayDotCopyWith<DayDot> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayDotCopyWith<$Res> {
  factory $DayDotCopyWith(DayDot value, $Res Function(DayDot) then) =
      _$DayDotCopyWithImpl<$Res, DayDot>;
  @useResult
  $Res call({
    DateTime day,
    MoodCategory dominantCategory,
    int totalEntries,
    String mostRecentEntryId,
  });
}

/// @nodoc
class _$DayDotCopyWithImpl<$Res, $Val extends DayDot>
    implements $DayDotCopyWith<$Res> {
  _$DayDotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DayDot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? dominantCategory = null,
    Object? totalEntries = null,
    Object? mostRecentEntryId = null,
  }) {
    return _then(
      _value.copyWith(
            day: null == day
                ? _value.day
                : day // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dominantCategory: null == dominantCategory
                ? _value.dominantCategory
                : dominantCategory // ignore: cast_nullable_to_non_nullable
                      as MoodCategory,
            totalEntries: null == totalEntries
                ? _value.totalEntries
                : totalEntries // ignore: cast_nullable_to_non_nullable
                      as int,
            mostRecentEntryId: null == mostRecentEntryId
                ? _value.mostRecentEntryId
                : mostRecentEntryId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DayDotImplCopyWith<$Res> implements $DayDotCopyWith<$Res> {
  factory _$$DayDotImplCopyWith(
    _$DayDotImpl value,
    $Res Function(_$DayDotImpl) then,
  ) = __$$DayDotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime day,
    MoodCategory dominantCategory,
    int totalEntries,
    String mostRecentEntryId,
  });
}

/// @nodoc
class __$$DayDotImplCopyWithImpl<$Res>
    extends _$DayDotCopyWithImpl<$Res, _$DayDotImpl>
    implements _$$DayDotImplCopyWith<$Res> {
  __$$DayDotImplCopyWithImpl(
    _$DayDotImpl _value,
    $Res Function(_$DayDotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DayDot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? dominantCategory = null,
    Object? totalEntries = null,
    Object? mostRecentEntryId = null,
  }) {
    return _then(
      _$DayDotImpl(
        day: null == day
            ? _value.day
            : day // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dominantCategory: null == dominantCategory
            ? _value.dominantCategory
            : dominantCategory // ignore: cast_nullable_to_non_nullable
                  as MoodCategory,
        totalEntries: null == totalEntries
            ? _value.totalEntries
            : totalEntries // ignore: cast_nullable_to_non_nullable
                  as int,
        mostRecentEntryId: null == mostRecentEntryId
            ? _value.mostRecentEntryId
            : mostRecentEntryId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DayDotImpl implements _DayDot {
  const _$DayDotImpl({
    required this.day,
    required this.dominantCategory,
    required this.totalEntries,
    required this.mostRecentEntryId,
  });

  @override
  final DateTime day;
  @override
  final MoodCategory dominantCategory;
  @override
  final int totalEntries;
  @override
  final String mostRecentEntryId;

  @override
  String toString() {
    return 'DayDot(day: $day, dominantCategory: $dominantCategory, totalEntries: $totalEntries, mostRecentEntryId: $mostRecentEntryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayDotImpl &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.dominantCategory, dominantCategory) ||
                other.dominantCategory == dominantCategory) &&
            (identical(other.totalEntries, totalEntries) ||
                other.totalEntries == totalEntries) &&
            (identical(other.mostRecentEntryId, mostRecentEntryId) ||
                other.mostRecentEntryId == mostRecentEntryId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    day,
    dominantCategory,
    totalEntries,
    mostRecentEntryId,
  );

  /// Create a copy of DayDot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DayDotImplCopyWith<_$DayDotImpl> get copyWith =>
      __$$DayDotImplCopyWithImpl<_$DayDotImpl>(this, _$identity);
}

abstract class _DayDot implements DayDot {
  const factory _DayDot({
    required final DateTime day,
    required final MoodCategory dominantCategory,
    required final int totalEntries,
    required final String mostRecentEntryId,
  }) = _$DayDotImpl;

  @override
  DateTime get day;
  @override
  MoodCategory get dominantCategory;
  @override
  int get totalEntries;
  @override
  String get mostRecentEntryId;

  /// Create a copy of DayDot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DayDotImplCopyWith<_$DayDotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
