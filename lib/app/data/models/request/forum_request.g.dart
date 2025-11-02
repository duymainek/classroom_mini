// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTopicRequest _$CreateTopicRequestFromJson(Map<String, dynamic> json) =>
    CreateTopicRequest(
      title: json['title'] as String,
      content: json['content'] as String,
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateTopicRequestToJson(CreateTopicRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'attachment_ids': instance.attachmentIds,
    };

CreateReplyRequest _$CreateReplyRequestFromJson(Map<String, dynamic> json) =>
    CreateReplyRequest(
      content: json['content'] as String,
      parentReplyId: json['parent_reply_id'] as String?,
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateReplyRequestToJson(CreateReplyRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'parent_reply_id': instance.parentReplyId,
      'attachment_ids': instance.attachmentIds,
    };

UpdateTopicRequest _$UpdateTopicRequestFromJson(Map<String, dynamic> json) =>
    UpdateTopicRequest(
      title: json['title'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$UpdateTopicRequestToJson(UpdateTopicRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
    };

UpdateReplyRequest _$UpdateReplyRequestFromJson(Map<String, dynamic> json) =>
    UpdateReplyRequest(
      content: json['content'] as String,
    );

Map<String, dynamic> _$UpdateReplyRequestToJson(UpdateReplyRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
    };
