// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AdminIdentity _$AdminIdentityFromJson(Map<String, dynamic> json) {
  return _AdminIdentity.fromJson(json);
}

/// @nodoc
mixin _$AdminIdentity {
  User get user => throw _privateConstructorUsedError;
  bool get isAdmin => throw _privateConstructorUsedError;
  String? get role => throw _privateConstructorUsedError;

  /// Serializes this AdminIdentity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminIdentityCopyWith<AdminIdentity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminIdentityCopyWith<$Res> {
  factory $AdminIdentityCopyWith(
          AdminIdentity value, $Res Function(AdminIdentity) then) =
      _$AdminIdentityCopyWithImpl<$Res, AdminIdentity>;
  @useResult
  $Res call({User user, bool isAdmin, String? role});

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$AdminIdentityCopyWithImpl<$Res, $Val extends AdminIdentity>
    implements $AdminIdentityCopyWith<$Res> {
  _$AdminIdentityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? isAdmin = null,
    Object? role = freezed,
  }) {
    return _then(_value.copyWith(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AdminIdentityImplCopyWith<$Res>
    implements $AdminIdentityCopyWith<$Res> {
  factory _$$AdminIdentityImplCopyWith(
          _$AdminIdentityImpl value, $Res Function(_$AdminIdentityImpl) then) =
      __$$AdminIdentityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({User user, bool isAdmin, String? role});

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$AdminIdentityImplCopyWithImpl<$Res>
    extends _$AdminIdentityCopyWithImpl<$Res, _$AdminIdentityImpl>
    implements _$$AdminIdentityImplCopyWith<$Res> {
  __$$AdminIdentityImplCopyWithImpl(
      _$AdminIdentityImpl _value, $Res Function(_$AdminIdentityImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? isAdmin = null,
    Object? role = freezed,
  }) {
    return _then(_$AdminIdentityImpl(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminIdentityImpl implements _AdminIdentity {
  const _$AdminIdentityImpl(
      {required this.user, this.isAdmin = false, this.role});

  factory _$AdminIdentityImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminIdentityImplFromJson(json);

  @override
  final User user;
  @override
  @JsonKey()
  final bool isAdmin;
  @override
  final String? role;

  @override
  String toString() {
    return 'AdminIdentity(user: $user, isAdmin: $isAdmin, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminIdentityImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, user, isAdmin, role);

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminIdentityImplCopyWith<_$AdminIdentityImpl> get copyWith =>
      __$$AdminIdentityImplCopyWithImpl<_$AdminIdentityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminIdentityImplToJson(
      this,
    );
  }
}

abstract class _AdminIdentity implements AdminIdentity {
  const factory _AdminIdentity(
      {required final User user,
      final bool isAdmin,
      final String? role}) = _$AdminIdentityImpl;

  factory _AdminIdentity.fromJson(Map<String, dynamic> json) =
      _$AdminIdentityImpl.fromJson;

  @override
  User get user;
  @override
  bool get isAdmin;
  @override
  String? get role;

  /// Create a copy of AdminIdentity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminIdentityImplCopyWith<_$AdminIdentityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
