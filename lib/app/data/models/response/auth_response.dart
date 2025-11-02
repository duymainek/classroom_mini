import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';

part 'auth_response.g.dart';

@JsonSerializable()
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

  factory BaseResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BaseResponseToJson(this);
}

@JsonSerializable()
class TokenPair {
  final String accessToken;
  final String refreshToken;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);
  Map<String, dynamic> toJson() => _$TokenPairToJson(this);
}

@JsonSerializable()
class AuthResponse extends BaseResponse {
  final AuthData? data;

  AuthResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthData {
  final UserModel? user;
  final TokenPair? tokens;

  AuthData({
    this.user,
    this.tokens,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}

@JsonSerializable()
class LogoutResponse extends BaseResponse {
  LogoutResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogoutResponseToJson(this);
}

@JsonSerializable()
class StudentsListData {
  final List<UserModel> students;
  final PaginationInfo pagination;

  const StudentsListData({
    required this.students,
    required this.pagination,
  });

  factory StudentsListData.fromJson(Map<String, dynamic> json) =>
      _$StudentsListDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentsListDataToJson(this);
}

@JsonSerializable()
class StudentsListResponse extends BaseResponse {
  final StudentsListData data;

  StudentsListResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    required this.data,
  });

  factory StudentsListResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentsListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentsListResponseToJson(this);
}

@JsonSerializable()
class StudentUpdateData {
  final UserModel? student;
  final String? groupId;
  final String? courseId;

  StudentUpdateData({
    this.student,
    this.groupId,
    this.courseId,
  });

  factory StudentUpdateData.fromJson(Map<String, dynamic> json) =>
      _$StudentUpdateDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentUpdateDataToJson(this);
}

@JsonSerializable()
class StudentUpdateResponse extends BaseResponse {
  final StudentUpdateData? data;

  StudentUpdateResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory StudentUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentUpdateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentUpdateResponseToJson(this);

  UserModel? get student => data?.student;
  String? get groupId => data?.groupId;
  String? get courseId => data?.courseId;
}

@JsonSerializable()
class SimpleResponse extends BaseResponse {
  SimpleResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
  });

  factory SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SimpleResponseToJson(this);
}

@JsonSerializable()
class BulkOperationResponse extends BaseResponse {
  final int? affectedCount;

  BulkOperationResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.affectedCount,
  });

  factory BulkOperationResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkOperationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BulkOperationResponseToJson(this);
}

@JsonSerializable()
class StatisticsResponse extends BaseResponse {
  final Map<String, dynamic>? data;

  StatisticsResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsResponseToJson(this);
}

@JsonSerializable()
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

  factory ImportPreviewResponse.fromJson(Map<String, dynamic> json) =>
      _$ImportPreviewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ImportPreviewResponseToJson(this);
}

@JsonSerializable()
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

  factory ImportResponse.fromJson(Map<String, dynamic> json) =>
      _$ImportResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ImportResponseToJson(this);
}
