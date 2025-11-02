// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupCreateRequest _$GroupCreateRequestFromJson(Map<String, dynamic> json) =>
    GroupCreateRequest(
      name: json['name'] as String,
      courseId: json['courseId'] as String,
    );

Map<String, dynamic> _$GroupCreateRequestToJson(GroupCreateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'courseId': instance.courseId,
    };

GroupUpdateRequest _$GroupUpdateRequestFromJson(Map<String, dynamic> json) =>
    GroupUpdateRequest(
      name: json['name'] as String?,
      courseId: json['courseId'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$GroupUpdateRequestToJson(GroupUpdateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'courseId': instance.courseId,
      'isActive': instance.isActive,
    };
