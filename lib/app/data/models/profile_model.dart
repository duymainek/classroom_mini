import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileResponse {
  final bool success;
  final UserData data;

  ProfileResponse({required this.success, required this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => _$ProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}

@JsonSerializable()
class UserData {
  final UserModel user;

  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class UpdateProfileRequest {
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? email;

  UpdateProfileRequest({this.fullName, this.email});

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class AvatarUploadResponse {
  final bool success;
  final String message;
  final AvatarData data;

  AvatarUploadResponse({required this.success, required this.message, required this.data});

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) => _$AvatarUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarUploadResponseToJson(this);
}

@JsonSerializable()
class AvatarData {
  @JsonKey(name: 'avatar_url')
  final String avatarUrl;

  AvatarData({required this.avatarUrl});

  factory AvatarData.fromJson(Map<String, dynamic> json) => _$AvatarDataFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarDataToJson(this);
}
