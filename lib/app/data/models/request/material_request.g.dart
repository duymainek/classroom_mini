// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMaterialRequest _$CreateMaterialRequestFromJson(
        Map<String, dynamic> json) =>
    CreateMaterialRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String,
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateMaterialRequestToJson(
        CreateMaterialRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'attachmentIds': instance.attachmentIds,
    };

UpdateMaterialRequest _$UpdateMaterialRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateMaterialRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateMaterialRequestToJson(
        UpdateMaterialRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'attachmentIds': instance.attachmentIds,
    };
