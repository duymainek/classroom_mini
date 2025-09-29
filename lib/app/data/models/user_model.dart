import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'role')
  final String? role;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

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
    );
  }
}
