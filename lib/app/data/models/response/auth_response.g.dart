// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseResponse _$BaseResponseFromJson(Map<String, dynamic> json) => BaseResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BaseResponseToJson(BaseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
    };

TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => TokenPair(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$TokenPairToJson(TokenPair instance) => <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: json['data'] == null
          ? null
          : AuthData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

AuthData _$AuthDataFromJson(Map<String, dynamic> json) => AuthData(
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: json['tokens'] == null
          ? null
          : TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthDataToJson(AuthData instance) => <String, dynamic>{
      'user': instance.user,
      'tokens': instance.tokens,
    };

LogoutResponse _$LogoutResponseFromJson(Map<String, dynamic> json) =>
    LogoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$LogoutResponseToJson(LogoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
    };

StudentsListData _$StudentsListDataFromJson(Map<String, dynamic> json) =>
    StudentsListData(
      students: (json['students'] as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentsListDataToJson(StudentsListData instance) =>
    <String, dynamic>{
      'students': instance.students,
      'pagination': instance.pagination,
    };

StudentsListResponse _$StudentsListResponseFromJson(
        Map<String, dynamic> json) =>
    StudentsListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: StudentsListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentsListResponseToJson(
        StudentsListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

StudentUpdateData _$StudentUpdateDataFromJson(Map<String, dynamic> json) =>
    StudentUpdateData(
      student: json['student'] == null
          ? null
          : UserModel.fromJson(json['student'] as Map<String, dynamic>),
      groupId: json['groupId'] as String?,
      courseId: json['courseId'] as String?,
    );

Map<String, dynamic> _$StudentUpdateDataToJson(StudentUpdateData instance) =>
    <String, dynamic>{
      'student': instance.student,
      'groupId': instance.groupId,
      'courseId': instance.courseId,
    };

StudentUpdateResponse _$StudentUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    StudentUpdateResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: json['data'] == null
          ? null
          : StudentUpdateData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentUpdateResponseToJson(
        StudentUpdateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

SimpleResponse _$SimpleResponseFromJson(Map<String, dynamic> json) =>
    SimpleResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SimpleResponseToJson(SimpleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
    };

BulkOperationResponse _$BulkOperationResponseFromJson(
        Map<String, dynamic> json) =>
    BulkOperationResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      affectedCount: json['affectedCount'] as int?,
    );

Map<String, dynamic> _$BulkOperationResponseToJson(
        BulkOperationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'affectedCount': instance.affectedCount,
    };

StatisticsResponse _$StatisticsResponseFromJson(Map<String, dynamic> json) =>
    StatisticsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StatisticsResponseToJson(StatisticsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

ImportPreviewResponse _$ImportPreviewResponseFromJson(
        Map<String, dynamic> json) =>
    ImportPreviewResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      summary: json['summary'] as Map<String, dynamic>?,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$ImportPreviewResponseToJson(
        ImportPreviewResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'summary': instance.summary,
      'results': instance.results,
    };

ImportResponse _$ImportResponseFromJson(Map<String, dynamic> json) =>
    ImportResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      summary: json['summary'] as Map<String, dynamic>?,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$ImportResponseToJson(ImportResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'summary': instance.summary,
      'results': instance.results,
    };
