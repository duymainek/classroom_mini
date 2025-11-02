// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      groupId: json['groupId'] as String?,
      courseId: json['courseId'] as String?,
      group: json['group'] as Map<String, dynamic>?,
      course: json['course'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
      'groupId': instance.groupId,
      'courseId': instance.courseId,
      'group': instance.group,
      'course': instance.course,
    };

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'user': instance.user,
    };

UserSingleResponse _$UserSingleResponseFromJson(Map<String, dynamic> json) =>
    UserSingleResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: UserData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserSingleResponseToJson(UserSingleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
