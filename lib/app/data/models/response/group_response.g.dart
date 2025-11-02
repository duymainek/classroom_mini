// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: GroupListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupListResponseToJson(GroupListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

GroupResponse _$GroupResponseFromJson(Map<String, dynamic> json) =>
    GroupResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: json['data'] == null
          ? null
          : GroupData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupResponseToJson(GroupResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
      'data': instance.data,
    };

GroupData _$GroupDataFromJson(Map<String, dynamic> json) => GroupData(
      group: Group.fromJson(json['group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupDataToJson(GroupData instance) => <String, dynamic>{
      'group': instance.group,
    };
