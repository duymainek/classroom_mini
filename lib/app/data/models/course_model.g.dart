// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      sessionCount: (json['session_count'] as num).toInt(),
      semesterId: json['semester_id'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      semesterBrief: json['semesters'] == null
          ? null
          : CourseSemesterBrief.fromJson(
              json['semesters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'session_count': instance.sessionCount,
      'semester_id': instance.semesterId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'semesters': instance.semesterBrief,
    };

CourseSemesterBrief _$CourseSemesterBriefFromJson(Map<String, dynamic> json) =>
    CourseSemesterBrief(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CourseSemesterBriefToJson(
        CourseSemesterBrief instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

CourseCreateRequest _$CourseCreateRequestFromJson(Map<String, dynamic> json) =>
    CourseCreateRequest(
      code: json['code'] as String,
      name: json['name'] as String,
      sessionCount: (json['sessionCount'] as num).toInt(),
      semesterId: json['semesterId'] as String,
    );

Map<String, dynamic> _$CourseCreateRequestToJson(
        CourseCreateRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sessionCount': instance.sessionCount,
      'semesterId': instance.semesterId,
    };

CourseUpdateRequest _$CourseUpdateRequestFromJson(Map<String, dynamic> json) =>
    CourseUpdateRequest(
      code: json['code'] as String?,
      name: json['name'] as String?,
      sessionCount: (json['sessionCount'] as num?)?.toInt(),
      semesterId: json['semesterId'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$CourseUpdateRequestToJson(
        CourseUpdateRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'sessionCount': instance.sessionCount,
      'semesterId': instance.semesterId,
      'isActive': instance.isActive,
    };

CourseListData _$CourseListDataFromJson(Map<String, dynamic> json) =>
    CourseListData(
      courses: (json['courses'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseListDataToJson(CourseListData instance) =>
    <String, dynamic>{
      'courses': instance.courses,
      'pagination': instance.pagination,
    };

CourseListResponse _$CourseListResponseFromJson(Map<String, dynamic> json) =>
    CourseListResponse(
      success: json['success'] as bool,
      data: CourseListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseListResponseToJson(CourseListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

CourseResponse _$CourseResponseFromJson(Map<String, dynamic> json) =>
    CourseResponse(
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseResponseToJson(CourseResponse instance) =>
    <String, dynamic>{
      'course': instance.course,
    };
