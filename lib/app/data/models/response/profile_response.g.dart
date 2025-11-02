// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      success: json['success'] as bool,
      data: UserData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

AvatarUploadResponse _$AvatarUploadResponseFromJson(
        Map<String, dynamic> json) =>
    AvatarUploadResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: AvatarData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AvatarUploadResponseToJson(
        AvatarUploadResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AvatarData _$AvatarDataFromJson(Map<String, dynamic> json) => AvatarData(
      avatarUrl: json['avatarUrl'] as String,
    );

Map<String, dynamic> _$AvatarDataToJson(AvatarData instance) =>
    <String, dynamic>{
      'avatarUrl': instance.avatarUrl,
    };
