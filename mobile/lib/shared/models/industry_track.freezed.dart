// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'industry_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IndustryTrack _$IndustryTrackFromJson(Map<String, dynamic> json) {
  return _IndustryTrack.fromJson(json);
}

/// @nodoc
mixin _$IndustryTrack {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Icon key the client maps to a glyph (e.g. `finance`, `legal`).
  /// Server-provided so new tracks need no client release; null falls back
  /// to a neutral icon.
  @JsonKey(name: 'icon_key')
  String? get iconKey => throw _privateConstructorUsedError;

  /// One-line selling point shown under the track name.
  @JsonKey(name: 'perk')
  String? get perk => throw _privateConstructorUsedError;

  /// Serializes this IndustryTrack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IndustryTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IndustryTrackCopyWith<IndustryTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndustryTrackCopyWith<$Res> {
  factory $IndustryTrackCopyWith(
          IndustryTrack value, $Res Function(IndustryTrack) then) =
      _$IndustryTrackCopyWithImpl<$Res, IndustryTrack>;
  @useResult
  $Res call(
      {int id,
      String name,
      String? description,
      @JsonKey(name: 'icon_key') String? iconKey,
      @JsonKey(name: 'perk') String? perk});
}

/// @nodoc
class _$IndustryTrackCopyWithImpl<$Res, $Val extends IndustryTrack>
    implements $IndustryTrackCopyWith<$Res> {
  _$IndustryTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IndustryTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? iconKey = freezed,
    Object? perk = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: freezed == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String?,
      perk: freezed == perk
          ? _value.perk
          : perk // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IndustryTrackImplCopyWith<$Res>
    implements $IndustryTrackCopyWith<$Res> {
  factory _$$IndustryTrackImplCopyWith(
          _$IndustryTrackImpl value, $Res Function(_$IndustryTrackImpl) then) =
      __$$IndustryTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String? description,
      @JsonKey(name: 'icon_key') String? iconKey,
      @JsonKey(name: 'perk') String? perk});
}

/// @nodoc
class __$$IndustryTrackImplCopyWithImpl<$Res>
    extends _$IndustryTrackCopyWithImpl<$Res, _$IndustryTrackImpl>
    implements _$$IndustryTrackImplCopyWith<$Res> {
  __$$IndustryTrackImplCopyWithImpl(
      _$IndustryTrackImpl _value, $Res Function(_$IndustryTrackImpl) _then)
      : super(_value, _then);

  /// Create a copy of IndustryTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? iconKey = freezed,
    Object? perk = freezed,
  }) {
    return _then(_$IndustryTrackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: freezed == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String?,
      perk: freezed == perk
          ? _value.perk
          : perk // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IndustryTrackImpl implements _IndustryTrack {
  const _$IndustryTrackImpl(
      {required this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'icon_key') this.iconKey,
      @JsonKey(name: 'perk') this.perk});

  factory _$IndustryTrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$IndustryTrackImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String? description;

  /// Icon key the client maps to a glyph (e.g. `finance`, `legal`).
  /// Server-provided so new tracks need no client release; null falls back
  /// to a neutral icon.
  @override
  @JsonKey(name: 'icon_key')
  final String? iconKey;

  /// One-line selling point shown under the track name.
  @override
  @JsonKey(name: 'perk')
  final String? perk;

  @override
  String toString() {
    return 'IndustryTrack(id: $id, name: $name, description: $description, iconKey: $iconKey, perk: $perk)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IndustryTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.perk, perk) || other.perk == perk));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, description, iconKey, perk);

  /// Create a copy of IndustryTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IndustryTrackImplCopyWith<_$IndustryTrackImpl> get copyWith =>
      __$$IndustryTrackImplCopyWithImpl<_$IndustryTrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IndustryTrackImplToJson(
      this,
    );
  }
}

abstract class _IndustryTrack implements IndustryTrack {
  const factory _IndustryTrack(
      {required final int id,
      required final String name,
      final String? description,
      @JsonKey(name: 'icon_key') final String? iconKey,
      @JsonKey(name: 'perk') final String? perk}) = _$IndustryTrackImpl;

  factory _IndustryTrack.fromJson(Map<String, dynamic> json) =
      _$IndustryTrackImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String? get description;

  /// Icon key the client maps to a glyph (e.g. `finance`, `legal`).
  /// Server-provided so new tracks need no client release; null falls back
  /// to a neutral icon.
  @override
  @JsonKey(name: 'icon_key')
  String? get iconKey;

  /// One-line selling point shown under the track name.
  @override
  @JsonKey(name: 'perk')
  String? get perk;

  /// Create a copy of IndustryTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IndustryTrackImplCopyWith<_$IndustryTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
