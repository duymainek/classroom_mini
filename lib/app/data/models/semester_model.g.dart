// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Semester _$SemesterFromJson(Map<String, dynamic> json) => Semester(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SemesterToJson(Semester instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

SemesterCreateRequest _$SemesterCreateRequestFromJson(
        Map<String, dynamic> json) =>
    SemesterCreateRequest(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SemesterCreateRequestToJson(
        SemesterCreateRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

SemesterUpdateRequest _$SemesterUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    SemesterUpdateRequest(
      code: json['code'] as String?,
      name: json['name'] as String?,
      isActive: json['is_active'] as bool?,
    );

Map<String, dynamic> _$SemesterUpdateRequestToJson(
        SemesterUpdateRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'is_active': instance.isActive,
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
