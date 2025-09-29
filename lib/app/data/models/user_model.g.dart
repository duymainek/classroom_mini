// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      role: json['role'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'full_name': instance.fullName,
      'is_active': instance.isActive,
      'last_login_at': instance.lastLoginAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'role': instance.role,
      'avatar_url': instance.avatarUrl,
    };
