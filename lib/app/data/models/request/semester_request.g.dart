// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$SemesterUpdateRequestToJson(
        SemesterUpdateRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isActive': instance.isActive,
    };
