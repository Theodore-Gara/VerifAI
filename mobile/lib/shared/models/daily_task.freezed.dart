// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DailyTask _$DailyTaskFromJson(Map<String, dynamic> json) {
  return _DailyTask.fromJson(json);
}

/// @nodoc
mixin _$DailyTask {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get scenario => throw _privateConstructorUsedError;
  String get dimension => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'embedded_flaw')
  String? get embeddedFlaw => throw _privateConstructorUsedError;
  List<TaskOption> get options => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_output_lines')
  List<String> get aiOutputLines => throw _privateConstructorUsedError;
  String? get trackName => throw _privateConstructorUsedError;
  String? get difficulty => throw _privateConstructorUsedError;
  String? get feature => throw _privateConstructorUsedError;
  int? get trackId => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_repeat')
  bool get isRepeat => throw _privateConstructorUsedError;

  /// Serializes this DailyTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyTaskCopyWith<DailyTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyTaskCopyWith<$Res> {
  factory $DailyTaskCopyWith(DailyTask value, $Res Function(DailyTask) then) =
      _$DailyTaskCopyWithImpl<$Res, DailyTask>;
  @useResult
  $Res call(
      {int id,
      String title,
      String? scenario,
      String dimension,
      String format,
      @JsonKey(name: 'embedded_flaw') String? embeddedFlaw,
      List<TaskOption> options,
      @JsonKey(name: 'ai_output_lines') List<String> aiOutputLines,
      String? trackName,
      String? difficulty,
      String? feature,
      int? trackId,
      @JsonKey(name: 'is_repeat') bool isRepeat});
}

/// @nodoc
class _$DailyTaskCopyWithImpl<$Res, $Val extends DailyTask>
    implements $DailyTaskCopyWith<$Res> {
  _$DailyTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? scenario = freezed,
    Object? dimension = null,
    Object? format = null,
    Object? embeddedFlaw = freezed,
    Object? options = null,
    Object? aiOutputLines = null,
    Object? trackName = freezed,
    Object? difficulty = freezed,
    Object? feature = freezed,
    Object? trackId = freezed,
    Object? isRepeat = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      scenario: freezed == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as String?,
      dimension: null == dimension
          ? _value.dimension
          : dimension // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      embeddedFlaw: freezed == embeddedFlaw
          ? _value.embeddedFlaw
          : embeddedFlaw // ignore: cast_nullable_to_non_nullable
              as String?,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<TaskOption>,
      aiOutputLines: null == aiOutputLines
          ? _value.aiOutputLines
          : aiOutputLines // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trackName: freezed == trackName
          ? _value.trackName
          : trackName // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      feature: freezed == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as String?,
      trackId: freezed == trackId
          ? _value.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as int?,
      isRepeat: null == isRepeat
          ? _value.isRepeat
          : isRepeat // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyTaskImplCopyWith<$Res>
    implements $DailyTaskCopyWith<$Res> {
  factory _$$DailyTaskImplCopyWith(
          _$DailyTaskImpl value, $Res Function(_$DailyTaskImpl) then) =
      __$$DailyTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String? scenario,
      String dimension,
      String format,
      @JsonKey(name: 'embedded_flaw') String? embeddedFlaw,
      List<TaskOption> options,
      @JsonKey(name: 'ai_output_lines') List<String> aiOutputLines,
      String? trackName,
      String? difficulty,
      String? feature,
      int? trackId,
      @JsonKey(name: 'is_repeat') bool isRepeat});
}

/// @nodoc
class __$$DailyTaskImplCopyWithImpl<$Res>
    extends _$DailyTaskCopyWithImpl<$Res, _$DailyTaskImpl>
    implements _$$DailyTaskImplCopyWith<$Res> {
  __$$DailyTaskImplCopyWithImpl(
      _$DailyTaskImpl _value, $Res Function(_$DailyTaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailyTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? scenario = freezed,
    Object? dimension = null,
    Object? format = null,
    Object? embeddedFlaw = freezed,
    Object? options = null,
    Object? aiOutputLines = null,
    Object? trackName = freezed,
    Object? difficulty = freezed,
    Object? feature = freezed,
    Object? trackId = freezed,
    Object? isRepeat = null,
  }) {
    return _then(_$DailyTaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      scenario: freezed == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as String?,
      dimension: null == dimension
          ? _value.dimension
          : dimension // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      embeddedFlaw: freezed == embeddedFlaw
          ? _value.embeddedFlaw
          : embeddedFlaw // ignore: cast_nullable_to_non_nullable
              as String?,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<TaskOption>,
      aiOutputLines: null == aiOutputLines
          ? _value._aiOutputLines
          : aiOutputLines // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trackName: freezed == trackName
          ? _value.trackName
          : trackName // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      feature: freezed == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as String?,
      trackId: freezed == trackId
          ? _value.trackId
          : trackId // ignore: cast_nullable_to_non_nullable
              as int?,
      isRepeat: null == isRepeat
          ? _value.isRepeat
          : isRepeat // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$DailyTaskImpl implements _DailyTask {
  const _$DailyTaskImpl(
      {required this.id,
      required this.title,
      this.scenario,
      required this.dimension,
      this.format = 'choice',
      @JsonKey(name: 'embedded_flaw') this.embeddedFlaw,
      final List<TaskOption> options = const [],
      @JsonKey(name: 'ai_output_lines')
      final List<String> aiOutputLines = const [],
      this.trackName,
      this.difficulty,
      this.feature,
      this.trackId,
      @JsonKey(name: 'is_repeat') this.isRepeat = false})
      : _options = options,
        _aiOutputLines = aiOutputLines;

  factory _$DailyTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyTaskImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String? scenario;
  @override
  final String dimension;
  @override
  @JsonKey()
  final String format;
  @override
  @JsonKey(name: 'embedded_flaw')
  final String? embeddedFlaw;
  final List<TaskOption> _options;
  @override
  @JsonKey()
  List<TaskOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final List<String> _aiOutputLines;
  @override
  @JsonKey(name: 'ai_output_lines')
  List<String> get aiOutputLines {
    if (_aiOutputLines is EqualUnmodifiableListView) return _aiOutputLines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aiOutputLines);
  }

  @override
  final String? trackName;
  @override
  final String? difficulty;
  @override
  final String? feature;
  @override
  final int? trackId;
  @override
  @JsonKey(name: 'is_repeat')
  final bool isRepeat;

  @override
  String toString() {
    return 'DailyTask(id: $id, title: $title, scenario: $scenario, dimension: $dimension, format: $format, embeddedFlaw: $embeddedFlaw, options: $options, aiOutputLines: $aiOutputLines, trackName: $trackName, difficulty: $difficulty, feature: $feature, trackId: $trackId, isRepeat: $isRepeat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.scenario, scenario) ||
                other.scenario == scenario) &&
            (identical(other.dimension, dimension) ||
                other.dimension == dimension) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.embeddedFlaw, embeddedFlaw) ||
                other.embeddedFlaw == embeddedFlaw) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality()
                .equals(other._aiOutputLines, _aiOutputLines) &&
            (identical(other.trackName, trackName) ||
                other.trackName == trackName) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.feature, feature) || other.feature == feature) &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            (identical(other.isRepeat, isRepeat) ||
                other.isRepeat == isRepeat));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      scenario,
      dimension,
      format,
      embeddedFlaw,
      const DeepCollectionEquality().hash(_options),
      const DeepCollectionEquality().hash(_aiOutputLines),
      trackName,
      difficulty,
      feature,
      trackId,
      isRepeat);

  /// Create a copy of DailyTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyTaskImplCopyWith<_$DailyTaskImpl> get copyWith =>
      __$$DailyTaskImplCopyWithImpl<_$DailyTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyTaskImplToJson(
      this,
    );
  }
}

abstract class _DailyTask implements DailyTask {
  const factory _DailyTask(
      {required final int id,
      required final String title,
      final String? scenario,
      required final String dimension,
      final String format,
      @JsonKey(name: 'embedded_flaw') final String? embeddedFlaw,
      final List<TaskOption> options,
      @JsonKey(name: 'ai_output_lines') final List<String> aiOutputLines,
      final String? trackName,
      final String? difficulty,
      final String? feature,
      final int? trackId,
      @JsonKey(name: 'is_repeat') final bool isRepeat}) = _$DailyTaskImpl;

  factory _DailyTask.fromJson(Map<String, dynamic> json) =
      _$DailyTaskImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String? get scenario;
  @override
  String get dimension;
  @override
  String get format;
  @override
  @JsonKey(name: 'embedded_flaw')
  String? get embeddedFlaw;
  @override
  List<TaskOption> get options;
  @override
  @JsonKey(name: 'ai_output_lines')
  List<String> get aiOutputLines;
  @override
  String? get trackName;
  @override
  String? get difficulty;
  @override
  String? get feature;
  @override
  int? get trackId;
  @override
  @JsonKey(name: 'is_repeat')
  bool get isRepeat;

  /// Create a copy of DailyTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyTaskImplCopyWith<_$DailyTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
