import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final String? role;
  final String? avatarUrl;
  final String? groupId;
  final String? courseId;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    this.role,
    this.avatarUrl,
    this.groupId,
    this.courseId,
  });

  bool get isInstructor => role == 'instructor';
  bool get isStudent =>
      role == 'student' ||
      role == null; // Default to student if no role specified

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? role,
    String? avatarUrl,
    String? groupId,
    String? courseId,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      groupId: groupId ?? this.groupId,
      courseId: courseId ?? this.courseId,
    );
  }
}

@JsonSerializable()
class UserData {
  final UserModel user;

  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class UserSingleResponse {
  final bool success;
  final String? message;
  final UserData data;

  UserSingleResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory UserSingleResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSingleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserSingleResponseToJson(this);
}
