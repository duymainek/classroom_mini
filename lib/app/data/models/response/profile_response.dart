import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';

part 'profile_response.g.dart';

@JsonSerializable()
class ProfileResponse {
  final bool success;
  final UserData data;

  ProfileResponse({required this.success, required this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}

@JsonSerializable()
class AvatarUploadResponse {
  final bool success;
  final String message;
  final AvatarData data;

  AvatarUploadResponse(
      {required this.success, required this.message, required this.data});

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarUploadResponseToJson(this);
}

@JsonSerializable()
class AvatarData {
  final String avatarUrl;

  AvatarData({required this.avatarUrl});

  factory AvatarData.fromJson(Map<String, dynamic> json) =>
      _$AvatarDataFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarDataToJson(this);
}
