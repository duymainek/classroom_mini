import 'user_model.dart';

/// Base response model for all API responses
class BaseResponse {
  final bool success;
  final String? message;
  final String? code;
  final List<String>? errors;

  BaseResponse({
    required this.success,
    this.message,
    this.code,
    this.errors,
  });

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }
}

/// Token pair model
class TokenPair {
  final String accessToken;
  final String refreshToken;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

/// Authentication response model
class AuthResponse extends BaseResponse {
  final AuthData? data;

  AuthResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      data: json['data'] != null
          ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Authentication data model
class AuthData {
  final UserModel? user;
  final TokenPair? tokens;

  AuthData({
    this.user,
    this.tokens,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      tokens: json['tokens'] != null
          ? TokenPair.fromJson(json['tokens'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Logout response model
class LogoutResponse extends BaseResponse {
  LogoutResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }
}

/// Students list response model
class StudentsListResponse extends BaseResponse {
  final List<UserModel>? students;
  final PaginationInfo? pagination;

  StudentsListResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.students,
    this.pagination,
  });

  factory StudentsListResponse.fromJson(Map<String, dynamic> json) {
    return StudentsListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      students: json['data'] != null && json['data']['students'] != null
          ? List<UserModel>.from((json['data']['students'] as List)
              .map((x) => UserModel.fromJson(x as Map<String, dynamic>)))
          : null,
      pagination: json['data'] != null && json['data']['pagination'] != null
          ? PaginationInfo.fromJson(
              json['data']['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pagination information model
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      pages: json['pages'] as int,
    );
  }
}

/// Student update response model
class StudentUpdateResponse extends BaseResponse {
  final UserModel? student;

  StudentUpdateResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.student,
  });

  factory StudentUpdateResponse.fromJson(Map<String, dynamic> json) {
    return StudentUpdateResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      student: json['data'] != null && json['data']['student'] != null
          ? UserModel.fromJson(json['data']['student'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Simple response model for operations that don't return data
class SimpleResponse extends BaseResponse {
  SimpleResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
  });

  factory SimpleResponse.fromJson(Map<String, dynamic> json) {
    return SimpleResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }
}

/// Bulk operation response model
class BulkOperationResponse extends BaseResponse {
  final int? affectedCount;

  BulkOperationResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.affectedCount,
  });

  factory BulkOperationResponse.fromJson(Map<String, dynamic> json) {
    return BulkOperationResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      affectedCount: json['affectedCount'] as int?,
    );
  }
}

/// Statistics response model
class StatisticsResponse extends BaseResponse {
  final Map<String, dynamic>? data;

  StatisticsResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Import preview response model
class ImportPreviewResponse extends BaseResponse {
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>>? results;

  ImportPreviewResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.summary,
    this.results,
  });

  factory ImportPreviewResponse.fromJson(Map<String, dynamic> json) {
    return ImportPreviewResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      summary: json['summary'] as Map<String, dynamic>?,
      results: json['results'] != null
          ? List<Map<String, dynamic>>.from(json['results'] as List)
          : null,
    );
  }
}

/// Import response model
class ImportResponse extends BaseResponse {
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>>? results;

  ImportResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.summary,
    this.results,
  });

  factory ImportResponse.fromJson(Map<String, dynamic> json) {
    return ImportResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
      summary: json['summary'] as Map<String, dynamic>?,
      results: json['results'] != null
          ? List<Map<String, dynamic>>.from(json['results'] as List)
          : null,
    );
  }
}
