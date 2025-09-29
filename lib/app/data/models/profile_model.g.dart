// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

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

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'user': instance.user,
    };

UpdateProfileRequest _$UpdateProfileRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateProfileRequest(
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$UpdateProfileRequestToJson(
        UpdateProfileRequest instance) =>
    <String, dynamic>{
      'full_name': instance.fullName,
      'email': instance.email,
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
      avatarUrl: json['avatar_url'] as String,
    );

Map<String, dynamic> _$AvatarDataToJson(AvatarData instance) =>
    <String, dynamic>{
      'avatar_url': instance.avatarUrl,
    };
