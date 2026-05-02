// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garden_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GardenState {
  /// Total number of positive mood entries in the user's history. Drives
  /// the canvas density: more positives → more flowers.
  int get positiveMoodCount => throw _privateConstructorUsedError;

  /// Total number of negative-mood entries at intensity 1–3 (gentler
  /// negatives). Rendered as wilting plants on the garden canvas.
  int get wiltingMoodCount => throw _privateConstructorUsedError;

  /// Total number of negative-mood entries at intensity 4–5 (stormier
  /// negatives). Rendered as rain clouds that drift and fade on their own
  /// — the user is never asked to clean them up.
  int get rainCloudMoodCount => throw _privateConstructorUsedError;

  /// Consecutive days, ending today, on which the user logged at least one
  /// positive mood. Empty days break the streak silently — there is no
  /// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
  /// to the streak**, by design (see ADR-0006).
  int get currentStreakDays => throw _privateConstructorUsedError;

  /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
  /// length 7. Drives the weekly bloom bar.
  List<DayBloom> get last7Days => throw _privateConstructorUsedError;

  /// Create a copy of GardenState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GardenStateCopyWith<GardenState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GardenStateCopyWith<$Res> {
  factory $GardenStateCopyWith(
    GardenState value,
    $Res Function(GardenState) then,
  ) = _$GardenStateCopyWithImpl<$Res, GardenState>;
  @useResult
  $Res call({
    int positiveMoodCount,
    int wiltingMoodCount,
    int rainCloudMoodCount,
    int currentStreakDays,
    List<DayBloom> last7Days,
  });
}

/// @nodoc
class _$GardenStateCopyWithImpl<$Res, $Val extends GardenState>
    implements $GardenStateCopyWith<$Res> {
  _$GardenStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GardenState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? positiveMoodCount = null,
    Object? wiltingMoodCount = null,
    Object? rainCloudMoodCount = null,
    Object? currentStreakDays = null,
    Object? last7Days = null,
  }) {
    return _then(
      _value.copyWith(
            positiveMoodCount: null == positiveMoodCount
                ? _value.positiveMoodCount
                : positiveMoodCount // ignore: cast_nullable_to_non_nullable
                      as int,
            wiltingMoodCount: null == wiltingMoodCount
                ? _value.wiltingMoodCount
                : wiltingMoodCount // ignore: cast_nullable_to_non_nullable
                      as int,
            rainCloudMoodCount: null == rainCloudMoodCount
                ? _value.rainCloudMoodCount
                : rainCloudMoodCount // ignore: cast_nullable_to_non_nullable
                      as int,
            currentStreakDays: null == currentStreakDays
                ? _value.currentStreakDays
                : currentStreakDays // ignore: cast_nullable_to_non_nullable
                      as int,
            last7Days: null == last7Days
                ? _value.last7Days
                : last7Days // ignore: cast_nullable_to_non_nullable
                      as List<DayBloom>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GardenStateImplCopyWith<$Res>
    implements $GardenStateCopyWith<$Res> {
  factory _$$GardenStateImplCopyWith(
    _$GardenStateImpl value,
    $Res Function(_$GardenStateImpl) then,
  ) = __$$GardenStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int positiveMoodCount,
    int wiltingMoodCount,
    int rainCloudMoodCount,
    int currentStreakDays,
    List<DayBloom> last7Days,
  });
}

/// @nodoc
class __$$GardenStateImplCopyWithImpl<$Res>
    extends _$GardenStateCopyWithImpl<$Res, _$GardenStateImpl>
    implements _$$GardenStateImplCopyWith<$Res> {
  __$$GardenStateImplCopyWithImpl(
    _$GardenStateImpl _value,
    $Res Function(_$GardenStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GardenState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? positiveMoodCount = null,
    Object? wiltingMoodCount = null,
    Object? rainCloudMoodCount = null,
    Object? currentStreakDays = null,
    Object? last7Days = null,
  }) {
    return _then(
      _$GardenStateImpl(
        positiveMoodCount: null == positiveMoodCount
            ? _value.positiveMoodCount
            : positiveMoodCount // ignore: cast_nullable_to_non_nullable
                  as int,
        wiltingMoodCount: null == wiltingMoodCount
            ? _value.wiltingMoodCount
            : wiltingMoodCount // ignore: cast_nullable_to_non_nullable
                  as int,
        rainCloudMoodCount: null == rainCloudMoodCount
            ? _value.rainCloudMoodCount
            : rainCloudMoodCount // ignore: cast_nullable_to_non_nullable
                  as int,
        currentStreakDays: null == currentStreakDays
            ? _value.currentStreakDays
            : currentStreakDays // ignore: cast_nullable_to_non_nullable
                  as int,
        last7Days: null == last7Days
            ? _value._last7Days
            : last7Days // ignore: cast_nullable_to_non_nullable
                  as List<DayBloom>,
      ),
    );
  }
}

/// @nodoc

class _$GardenStateImpl extends _GardenState {
  const _$GardenStateImpl({
    required this.positiveMoodCount,
    required this.wiltingMoodCount,
    required this.rainCloudMoodCount,
    required this.currentStreakDays,
    required final List<DayBloom> last7Days,
  }) : _last7Days = last7Days,
       super._();

  /// Total number of positive mood entries in the user's history. Drives
  /// the canvas density: more positives → more flowers.
  @override
  final int positiveMoodCount;

  /// Total number of negative-mood entries at intensity 1–3 (gentler
  /// negatives). Rendered as wilting plants on the garden canvas.
  @override
  final int wiltingMoodCount;

  /// Total number of negative-mood entries at intensity 4–5 (stormier
  /// negatives). Rendered as rain clouds that drift and fade on their own
  /// — the user is never asked to clean them up.
  @override
  final int rainCloudMoodCount;

  /// Consecutive days, ending today, on which the user logged at least one
  /// positive mood. Empty days break the streak silently — there is no
  /// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
  /// to the streak**, by design (see ADR-0006).
  @override
  final int currentStreakDays;

  /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
  /// length 7. Drives the weekly bloom bar.
  final List<DayBloom> _last7Days;

  /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
  /// length 7. Drives the weekly bloom bar.
  @override
  List<DayBloom> get last7Days {
    if (_last7Days is EqualUnmodifiableListView) return _last7Days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_last7Days);
  }

  @override
  String toString() {
    return 'GardenState(positiveMoodCount: $positiveMoodCount, wiltingMoodCount: $wiltingMoodCount, rainCloudMoodCount: $rainCloudMoodCount, currentStreakDays: $currentStreakDays, last7Days: $last7Days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GardenStateImpl &&
            (identical(other.positiveMoodCount, positiveMoodCount) ||
                other.positiveMoodCount == positiveMoodCount) &&
            (identical(other.wiltingMoodCount, wiltingMoodCount) ||
                other.wiltingMoodCount == wiltingMoodCount) &&
            (identical(other.rainCloudMoodCount, rainCloudMoodCount) ||
                other.rainCloudMoodCount == rainCloudMoodCount) &&
            (identical(other.currentStreakDays, currentStreakDays) ||
                other.currentStreakDays == currentStreakDays) &&
            const DeepCollectionEquality().equals(
              other._last7Days,
              _last7Days,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    positiveMoodCount,
    wiltingMoodCount,
    rainCloudMoodCount,
    currentStreakDays,
    const DeepCollectionEquality().hash(_last7Days),
  );

  /// Create a copy of GardenState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GardenStateImplCopyWith<_$GardenStateImpl> get copyWith =>
      __$$GardenStateImplCopyWithImpl<_$GardenStateImpl>(this, _$identity);
}

abstract class _GardenState extends GardenState {
  const factory _GardenState({
    required final int positiveMoodCount,
    required final int wiltingMoodCount,
    required final int rainCloudMoodCount,
    required final int currentStreakDays,
    required final List<DayBloom> last7Days,
  }) = _$GardenStateImpl;
  const _GardenState._() : super._();

  /// Total number of positive mood entries in the user's history. Drives
  /// the canvas density: more positives → more flowers.
  @override
  int get positiveMoodCount;

  /// Total number of negative-mood entries at intensity 1–3 (gentler
  /// negatives). Rendered as wilting plants on the garden canvas.
  @override
  int get wiltingMoodCount;

  /// Total number of negative-mood entries at intensity 4–5 (stormier
  /// negatives). Rendered as rain clouds that drift and fade on their own
  /// — the user is never asked to clean them up.
  @override
  int get rainCloudMoodCount;

  /// Consecutive days, ending today, on which the user logged at least one
  /// positive mood. Empty days break the streak silently — there is no
  /// streak-shaming copy. **Wilting and rain-cloud days do NOT contribute
  /// to the streak**, by design (see ADR-0006).
  @override
  int get currentStreakDays;

  /// Last 7 days, newest first (today, yesterday, …, 6 days ago). Always
  /// length 7. Drives the weekly bloom bar.
  @override
  List<DayBloom> get last7Days;

  /// Create a copy of GardenState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GardenStateImplCopyWith<_$GardenStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DayBloom {
  /// Midnight of the day in the user's local time zone.
  DateTime get day => throw _privateConstructorUsedError;
  DayBloomKind get kind => throw _privateConstructorUsedError;

  /// Create a copy of DayBloom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DayBloomCopyWith<DayBloom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayBloomCopyWith<$Res> {
  factory $DayBloomCopyWith(DayBloom value, $Res Function(DayBloom) then) =
      _$DayBloomCopyWithImpl<$Res, DayBloom>;
  @useResult
  $Res call({DateTime day, DayBloomKind kind});
}

/// @nodoc
class _$DayBloomCopyWithImpl<$Res, $Val extends DayBloom>
    implements $DayBloomCopyWith<$Res> {
  _$DayBloomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DayBloom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? day = null, Object? kind = null}) {
    return _then(
      _value.copyWith(
            day: null == day
                ? _value.day
                : day // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as DayBloomKind,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DayBloomImplCopyWith<$Res>
    implements $DayBloomCopyWith<$Res> {
  factory _$$DayBloomImplCopyWith(
    _$DayBloomImpl value,
    $Res Function(_$DayBloomImpl) then,
  ) = __$$DayBloomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime day, DayBloomKind kind});
}

/// @nodoc
class __$$DayBloomImplCopyWithImpl<$Res>
    extends _$DayBloomCopyWithImpl<$Res, _$DayBloomImpl>
    implements _$$DayBloomImplCopyWith<$Res> {
  __$$DayBloomImplCopyWithImpl(
    _$DayBloomImpl _value,
    $Res Function(_$DayBloomImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DayBloom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? day = null, Object? kind = null}) {
    return _then(
      _$DayBloomImpl(
        day: null == day
            ? _value.day
            : day // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as DayBloomKind,
      ),
    );
  }
}

/// @nodoc

class _$DayBloomImpl implements _DayBloom {
  const _$DayBloomImpl({required this.day, required this.kind});

  /// Midnight of the day in the user's local time zone.
  @override
  final DateTime day;
  @override
  final DayBloomKind kind;

  @override
  String toString() {
    return 'DayBloom(day: $day, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayBloomImpl &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, kind);

  /// Create a copy of DayBloom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DayBloomImplCopyWith<_$DayBloomImpl> get copyWith =>
      __$$DayBloomImplCopyWithImpl<_$DayBloomImpl>(this, _$identity);
}

abstract class _DayBloom implements DayBloom {
  const factory _DayBloom({
    required final DateTime day,
    required final DayBloomKind kind,
  }) = _$DayBloomImpl;

  /// Midnight of the day in the user's local time zone.
  @override
  DateTime get day;
  @override
  DayBloomKind get kind;

  /// Create a copy of DayBloom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DayBloomImplCopyWith<_$DayBloomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
