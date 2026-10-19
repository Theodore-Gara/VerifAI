// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminIdentityImpl _$$AdminIdentityImplFromJson(Map<String, dynamic> json) =>
    _$AdminIdentityImpl(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      isAdmin: json['isAdmin'] as bool? ?? false,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$$AdminIdentityImplToJson(_$AdminIdentityImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'isAdmin': instance.isAdmin,
      'role': instance.role,
    };
