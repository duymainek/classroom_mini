// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

CreateStudentRequest _$CreateStudentRequestFromJson(
        Map<String, dynamic> json) =>
    CreateStudentRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      groupId: json['groupId'] as String?,
      courseId: json['courseId'] as String?,
    );

Map<String, dynamic> _$CreateStudentRequestToJson(
        CreateStudentRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'email': instance.email,
      'fullName': instance.fullName,
      'groupId': instance.groupId,
      'courseId': instance.courseId,
    };

UpdateStudentRequest _$UpdateStudentRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateStudentRequest(
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateStudentRequestToJson(
        UpdateStudentRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
    };

BulkOperationRequest _$BulkOperationRequestFromJson(
        Map<String, dynamic> json) =>
    BulkOperationRequest(
      studentIds: (json['studentIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      action: json['action'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BulkOperationRequestToJson(
        BulkOperationRequest instance) =>
    <String, dynamic>{
      'studentIds': instance.studentIds,
      'action': instance.action,
      'data': instance.data,
    };

ResetPasswordRequest _$ResetPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordRequest(
      newPassword: json['newPassword'] as String,
    );

Map<String, dynamic> _$ResetPasswordRequestToJson(
        ResetPasswordRequest instance) =>
    <String, dynamic>{
      'newPassword': instance.newPassword,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
    };

ImportStudentsRequest _$ImportStudentsRequestFromJson(
        Map<String, dynamic> json) =>
    ImportStudentsRequest(
      records: (json['records'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      idempotencyKey: json['idempotencyKey'] as String?,
    );

Map<String, dynamic> _$ImportStudentsRequestToJson(
        ImportStudentsRequest instance) =>
    <String, dynamic>{
      'records': instance.records,
      'idempotencyKey': instance.idempotencyKey,
    };
