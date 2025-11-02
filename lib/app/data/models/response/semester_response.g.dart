// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Semester _$SemesterFromJson(Map<String, dynamic> json) => Semester(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SemesterToJson(Semester instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) =>
    PaginationInfo(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationInfoToJson(PaginationInfo instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };

SemesterListData _$SemesterListDataFromJson(Map<String, dynamic> json) =>
    SemesterListData(
      semesters: (json['semesters'] as List<dynamic>)
          .map((e) => Semester.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SemesterListDataToJson(SemesterListData instance) =>
    <String, dynamic>{
      'semesters': instance.semesters,
      'pagination': instance.pagination,
    };

SemesterListResponse _$SemesterListResponseFromJson(
        Map<String, dynamic> json) =>
    SemesterListResponse(
      success: json['success'] as bool,
      data: SemesterListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SemesterListResponseToJson(
        SemesterListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

SemesterResponse _$SemesterResponseFromJson(Map<String, dynamic> json) =>
    SemesterResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: SemesterData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SemesterResponseToJson(SemesterResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SemesterData _$SemesterDataFromJson(Map<String, dynamic> json) => SemesterData(
      semester: Semester.fromJson(json['semester'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SemesterDataToJson(SemesterData instance) =>
    <String, dynamic>{
      'semester': instance.semester,
    };
