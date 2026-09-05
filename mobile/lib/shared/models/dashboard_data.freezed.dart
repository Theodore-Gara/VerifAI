// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DashboardData _$DashboardDataFromJson(Map<String, dynamic> json) {
  return _DashboardData.fromJson(json);
}

/// @nodoc
mixin _$DashboardData {
  int get overallScore => throw _privateConstructorUsedError;
  Map<String, int> get dimensionScores => throw _privateConstructorUsedError;
  int get streakDays => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  DailyTask? get dailyTask => throw _privateConstructorUsedError;

  /// Serializes this DashboardData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardDataCopyWith<DashboardData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardDataCopyWith<$Res> {
  factory $DashboardDataCopyWith(
          DashboardData value, $Res Function(DashboardData) then) =
      _$DashboardDataCopyWithImpl<$Res, DashboardData>;
  @useResult
  $Res call(
      {int overallScore,
      Map<String, int> dimensionScores,
      int streakDays,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      DailyTask? dailyTask});

  $DailyTaskCopyWith<$Res>? get dailyTask;
}

/// @nodoc
class _$DashboardDataCopyWithImpl<$Res, $Val extends DashboardData>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overallScore = null,
    Object? dimensionScores = null,
    Object? streakDays = null,
    Object? dailyTask = freezed,
  }) {
    return _then(_value.copyWith(
      overallScore: null == overallScore
          ? _value.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as int,
      dimensionScores: null == dimensionScores
          ? _value.dimensionScores
          : dimensionScores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      streakDays: null == streakDays
          ? _value.streakDays
          : streakDays // ignore: cast_nullable_to_non_nullable
              as int,
      dailyTask: freezed == dailyTask
          ? _value.dailyTask
          : dailyTask // ignore: cast_nullable_to_non_nullable
              as DailyTask?,
    ) as $Val);
  }

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DailyTaskCopyWith<$Res>? get dailyTask {
    if (_value.dailyTask == null) {
      return null;
    }

    return $DailyTaskCopyWith<$Res>(_value.dailyTask!, (value) {
      return _then(_value.copyWith(dailyTask: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DashboardDataImplCopyWith<$Res>
    implements $DashboardDataCopyWith<$Res> {
  factory _$$DashboardDataImplCopyWith(
          _$DashboardDataImpl value, $Res Function(_$DashboardDataImpl) then) =
      __$$DashboardDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int overallScore,
      Map<String, int> dimensionScores,
      int streakDays,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      DailyTask? dailyTask});

  @override
  $DailyTaskCopyWith<$Res>? get dailyTask;
}

/// @nodoc
class __$$DashboardDataImplCopyWithImpl<$Res>
    extends _$DashboardDataCopyWithImpl<$Res, _$DashboardDataImpl>
    implements _$$DashboardDataImplCopyWith<$Res> {
  __$$DashboardDataImplCopyWithImpl(
      _$DashboardDataImpl _value, $Res Function(_$DashboardDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overallScore = null,
    Object? dimensionScores = null,
    Object? streakDays = null,
    Object? dailyTask = freezed,
  }) {
    return _then(_$DashboardDataImpl(
      overallScore: null == overallScore
          ? _value.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as int,
      dimensionScores: null == dimensionScores
          ? _value._dimensionScores
          : dimensionScores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      streakDays: null == streakDays
          ? _value.streakDays
          : streakDays // ignore: cast_nullable_to_non_nullable
              as int,
      dailyTask: freezed == dailyTask
          ? _value.dailyTask
          : dailyTask // ignore: cast_nullable_to_non_nullable
              as DailyTask?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardDataImpl implements _DashboardData {
  const _$DashboardDataImpl(
      {required this.overallScore,
      required final Map<String, int> dimensionScores,
      required this.streakDays,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      this.dailyTask})
      : _dimensionScores = dimensionScores;

  factory _$DashboardDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardDataImplFromJson(json);

  @override
  final int overallScore;
  final Map<String, int> _dimensionScores;
  @override
  Map<String, int> get dimensionScores {
    if (_dimensionScores is EqualUnmodifiableMapView) return _dimensionScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_dimensionScores);
  }

  @override
  final int streakDays;
  @override
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  final DailyTask? dailyTask;

  @override
  String toString() {
    return 'DashboardData(overallScore: $overallScore, dimensionScores: $dimensionScores, streakDays: $streakDays, dailyTask: $dailyTask)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardDataImpl &&
            (identical(other.overallScore, overallScore) ||
                other.overallScore == overallScore) &&
            const DeepCollectionEquality()
                .equals(other._dimensionScores, _dimensionScores) &&
            (identical(other.streakDays, streakDays) ||
                other.streakDays == streakDays) &&
            (identical(other.dailyTask, dailyTask) ||
                other.dailyTask == dailyTask));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      overallScore,
      const DeepCollectionEquality().hash(_dimensionScores),
      streakDays,
      dailyTask);

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      __$$DashboardDataImplCopyWithImpl<_$DashboardDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardDataImplToJson(
      this,
    );
  }
}

abstract class _DashboardData implements DashboardData {
  const factory _DashboardData(
      {required final int overallScore,
      required final Map<String, int> dimensionScores,
      required final int streakDays,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      final DailyTask? dailyTask}) = _$DashboardDataImpl;

  factory _DashboardData.fromJson(Map<String, dynamic> json) =
      _$DashboardDataImpl.fromJson;

  @override
  int get overallScore;
  @override
  Map<String, int> get dimensionScores;
  @override
  int get streakDays;
  @override
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  DailyTask? get dailyTask;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
