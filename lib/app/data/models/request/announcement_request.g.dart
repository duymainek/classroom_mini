// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAnnouncementRequest _$CreateAnnouncementRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAnnouncementRequest(
      title: json['title'] as String,
      content: json['content'] as String,
      courseId: json['courseId'] as String,
      scopeType: json['scopeType'] as String,
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateAnnouncementRequestToJson(
        CreateAnnouncementRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'courseId': instance.courseId,
      'scopeType': instance.scopeType,
      'groupIds': instance.groupIds,
      'attachmentIds': instance.attachmentIds,
    };

UpdateAnnouncementRequest _$UpdateAnnouncementRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAnnouncementRequest(
      title: json['title'] as String?,
      content: json['content'] as String?,
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateAnnouncementRequestToJson(
        UpdateAnnouncementRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'attachmentIds': instance.attachmentIds,
    };

AddCommentRequest _$AddCommentRequestFromJson(Map<String, dynamic> json) =>
    AddCommentRequest(
      commentText: json['commentText'] as String,
      parentCommentId: json['parentCommentId'] as String?,
    );

Map<String, dynamic> _$AddCommentRequestToJson(AddCommentRequest instance) =>
    <String, dynamic>{
      'commentText': instance.commentText,
      'parentCommentId': instance.parentCommentId,
    };
