// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      id: json['id'] as String,
      name: json['name'] as String,
      courseId: json['courseId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      courseBrief: json['courseBrief'] == null
          ? null
          : GroupCourseBrief.fromJson(
              json['courseBrief'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'courseId': instance.courseId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'courseBrief': instance.courseBrief,
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
      semesterBrief: json['semesterBrief'] == null
          ? null
          : CourseSemesterBrief.fromJson(
              json['semesterBrief'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupCourseBriefToJson(GroupCourseBrief instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'semesterBrief': instance.semesterBrief,
    };
