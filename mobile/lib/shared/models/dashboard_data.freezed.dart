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
  int get currentXp => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get xpIntoLevel => throw _privateConstructorUsedError;
  int get xpForNextLevel => throw _privateConstructorUsedError;
  int get completedTasks => throw _privateConstructorUsedError;
  String? get tier => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  DailyTask? get dailyTask => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
  List<DailyTask> get tasks => throw _privateConstructorUsedError;

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
      int currentXp,
      int level,
      int xpIntoLevel,
      int xpForNextLevel,
      int completedTasks,
      String? tier,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      DailyTask? dailyTask,
      @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
      List<DailyTask> tasks});

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
    Object? currentXp = null,
    Object? level = null,
    Object? xpIntoLevel = null,
    Object? xpForNextLevel = null,
    Object? completedTasks = null,
    Object? tier = freezed,
    Object? dailyTask = freezed,
    Object? tasks = null,
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
      currentXp: null == currentXp
          ? _value.currentXp
          : currentXp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      xpIntoLevel: null == xpIntoLevel
          ? _value.xpIntoLevel
          : xpIntoLevel // ignore: cast_nullable_to_non_nullable
              as int,
      xpForNextLevel: null == xpForNextLevel
          ? _value.xpForNextLevel
          : xpForNextLevel // ignore: cast_nullable_to_non_nullable
              as int,
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      tier: freezed == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      dailyTask: freezed == dailyTask
          ? _value.dailyTask
          : dailyTask // ignore: cast_nullable_to_non_nullable
              as DailyTask?,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<DailyTask>,
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
      int currentXp,
      int level,
      int xpIntoLevel,
      int xpForNextLevel,
      int completedTasks,
      String? tier,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      DailyTask? dailyTask,
      @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
      List<DailyTask> tasks});

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
    Object? currentXp = null,
    Object? level = null,
    Object? xpIntoLevel = null,
    Object? xpForNextLevel = null,
    Object? completedTasks = null,
    Object? tier = freezed,
    Object? dailyTask = freezed,
    Object? tasks = null,
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
      currentXp: null == currentXp
          ? _value.currentXp
          : currentXp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      xpIntoLevel: null == xpIntoLevel
          ? _value.xpIntoLevel
          : xpIntoLevel // ignore: cast_nullable_to_non_nullable
              as int,
      xpForNextLevel: null == xpForNextLevel
          ? _value.xpForNextLevel
          : xpForNextLevel // ignore: cast_nullable_to_non_nullable
              as int,
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      tier: freezed == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      dailyTask: freezed == dailyTask
          ? _value.dailyTask
          : dailyTask // ignore: cast_nullable_to_non_nullable
              as DailyTask?,
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<DailyTask>,
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
      this.currentXp = 0,
      this.level = 1,
      this.xpIntoLevel = 0,
      this.xpForNextLevel = 0,
      this.completedTasks = 0,
      this.tier,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      this.dailyTask,
      @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
      final List<DailyTask> tasks = const []})
      : _dimensionScores = dimensionScores,
        _tasks = tasks;

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
  @JsonKey()
  final int currentXp;
  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final int xpIntoLevel;
  @override
  @JsonKey()
  final int xpForNextLevel;
  @override
  @JsonKey()
  final int completedTasks;
  @override
  final String? tier;
  @override
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  final DailyTask? dailyTask;
  final List<DailyTask> _tasks;
  @override
  @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
  List<DailyTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  String toString() {
    return 'DashboardData(overallScore: $overallScore, dimensionScores: $dimensionScores, streakDays: $streakDays, currentXp: $currentXp, level: $level, xpIntoLevel: $xpIntoLevel, xpForNextLevel: $xpForNextLevel, completedTasks: $completedTasks, tier: $tier, dailyTask: $dailyTask, tasks: $tasks)';
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
            (identical(other.currentXp, currentXp) ||
                other.currentXp == currentXp) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.xpIntoLevel, xpIntoLevel) ||
                other.xpIntoLevel == xpIntoLevel) &&
            (identical(other.xpForNextLevel, xpForNextLevel) ||
                other.xpForNextLevel == xpForNextLevel) &&
            (identical(other.completedTasks, completedTasks) ||
                other.completedTasks == completedTasks) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.dailyTask, dailyTask) ||
                other.dailyTask == dailyTask) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      overallScore,
      const DeepCollectionEquality().hash(_dimensionScores),
      streakDays,
      currentXp,
      level,
      xpIntoLevel,
      xpForNextLevel,
      completedTasks,
      tier,
      dailyTask,
      const DeepCollectionEquality().hash(_tasks));

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
      final int currentXp,
      final int level,
      final int xpIntoLevel,
      final int xpForNextLevel,
      final int completedTasks,
      final String? tier,
      @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
      final DailyTask? dailyTask,
      @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
      final List<DailyTask> tasks}) = _$DashboardDataImpl;

  factory _DashboardData.fromJson(Map<String, dynamic> json) =
      _$DashboardDataImpl.fromJson;

  @override
  int get overallScore;
  @override
  Map<String, int> get dimensionScores;
  @override
  int get streakDays;
  @override
  int get currentXp;
  @override
  int get level;
  @override
  int get xpIntoLevel;
  @override
  int get xpForNextLevel;
  @override
  int get completedTasks;
  @override
  String? get tier;
  @override
  @JsonKey(fromJson: _dailyTaskFromJson, toJson: _dailyTaskToJson)
  DailyTask? get dailyTask;
  @override
  @JsonKey(fromJson: _dailyTaskListFromJson, toJson: _dailyTaskListToJson)
  List<DailyTask> get tasks;

  /// Create a copy of DashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardDataImplCopyWith<_$DashboardDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
