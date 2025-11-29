// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseCreateRequest _$CourseCreateRequestFromJson(Map<String, dynamic> json) =>
    CourseCreateRequest(
      code: json['code'] as String,
      name: json['name'] as String,
      sessionCount: json['sessionCount'] as int,
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
      sessionCount: json['sessionCount'] as int?,
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
