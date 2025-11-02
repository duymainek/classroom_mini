// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: CourseListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseListResponseToJson(CourseListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

CourseResponse _$CourseResponseFromJson(Map<String, dynamic> json) =>
    CourseResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: json['data'] == null
          ? null
          : CourseData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseResponseToJson(CourseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

CourseData _$CourseDataFromJson(Map<String, dynamic> json) => CourseData(
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseDataToJson(CourseData instance) =>
    <String, dynamic>{
      'course': instance.course,
    };
