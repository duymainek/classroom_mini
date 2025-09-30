import 'package:json_annotation/json_annotation.dart';

part 'auth_request.g.dart';

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class CreateStudentRequest {
  final String username;
  final String password;
  final String email;
  final String fullName;
  final String? groupId;
  final String? courseId;

  CreateStudentRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    this.groupId,
    this.courseId,
  });

  factory CreateStudentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStudentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateStudentRequestToJson(this);
}

@JsonSerializable()
class UpdateStudentRequest {
  final String? email;
  final String? fullName;
  final bool? isActive;

  UpdateStudentRequest({
    this.email,
    this.fullName,
    this.isActive,
  });

  factory UpdateStudentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStudentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateStudentRequestToJson(this);
}

@JsonSerializable()
class BulkOperationRequest {
  final List<String> studentIds;
  final String action;
  final Map<String, dynamic>? data;

  BulkOperationRequest({
    required this.studentIds,
    required this.action,
    this.data,
  });

  factory BulkOperationRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkOperationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BulkOperationRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String newPassword;

  ResetPasswordRequest({
    required this.newPassword,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class ImportStudentsRequest {
  final List<Map<String, dynamic>> records;
  final String? idempotencyKey;

  ImportStudentsRequest({
    required this.records,
    this.idempotencyKey,
  });

  factory ImportStudentsRequest.fromJson(Map<String, dynamic> json) =>
      _$ImportStudentsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ImportStudentsRequestToJson(this);
}
