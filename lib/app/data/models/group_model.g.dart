// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      id: json['id'] as String,
      name: json['name'] as String,
      courseId: json['course_id'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      courseBrief: json['courses'] == null
          ? null
          : GroupCourseBrief.fromJson(json['courses'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'course_id': instance.courseId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'courses': instance.courseBrief,
    };

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
      isActive: json['is_active'] as bool?,
    );

Map<String, dynamic> _$GroupUpdateRequestToJson(GroupUpdateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'courseId': instance.courseId,
      'is_active': instance.isActive,
    };

GroupListData _$GroupListDataFromJson(Map<String, dynamic> json) =>
    GroupListData(
      groups: (json['groups'] as List<dynamic>)
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupListDataToJson(GroupListData instance) =>
    <String, dynamic>{
      'groups': instance.groups,
      'pagination': instance.pagination,
    };

GroupListResponse _$GroupListResponseFromJson(Map<String, dynamic> json) =>
    GroupListResponse(
      success: json['success'] as bool,
      data: GroupListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupListResponseToJson(GroupListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

GroupResponse _$GroupResponseFromJson(Map<String, dynamic> json) =>
    GroupResponse(
      group: Group.fromJson(json['group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupResponseToJson(GroupResponse instance) =>
    <String, dynamic>{
      'group': instance.group,
    };

GroupCourseBrief _$GroupCourseBriefFromJson(Map<String, dynamic> json) =>
    GroupCourseBrief(
      code: json['code'] as String,
      name: json['name'] as String,
      semesterBrief: json['semesters'] == null
          ? null
          : CourseSemesterBrief.fromJson(
              json['semesters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupCourseBriefToJson(GroupCourseBrief instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'semesters': instance.semesterBrief,
    };
