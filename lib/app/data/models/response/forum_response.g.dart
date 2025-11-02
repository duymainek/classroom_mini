// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForumAuthor _$ForumAuthorFromJson(Map<String, dynamic> json) => ForumAuthor(
      id: json['id'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$ForumAuthorToJson(ForumAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
    };

ForumCourse _$ForumCourseFromJson(Map<String, dynamic> json) => ForumCourse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$ForumCourseToJson(ForumCourse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

ForumAttachment _$ForumAttachmentFromJson(Map<String, dynamic> json) =>
    ForumAttachment(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      fileType: json['file_type'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ForumAttachmentToJson(ForumAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_name': instance.fileName,
      'file_url': instance.fileUrl,
      'file_size': instance.fileSize,
      'file_type': instance.fileType,
      'created_at': instance.createdAt?.toIso8601String(),
    };

ForumReply _$ForumReplyFromJson(Map<String, dynamic> json) => ForumReply(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      parentReplyId: json['parentReplyId'] as String?,
      content: json['content'] as String,
      author: ForumAuthor.fromJson(json['author'] as Map<String, dynamic>),
      likeCount: (json['likeCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ForumAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => ForumReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForumReplyToJson(ForumReply instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'parentReplyId': instance.parentReplyId,
      'content': instance.content,
      'author': instance.author,
      'likeCount': instance.likeCount,
      'isLiked': instance.isLiked,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'attachments': instance.attachments,
      'replies': instance.replies,
    };

ForumTopic _$ForumTopicFromJson(Map<String, dynamic> json) => ForumTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: ForumAuthor.fromJson(json['author'] as Map<String, dynamic>),
      replyCount: (json['replyCount'] as num).toInt(),
      viewCount: (json['viewCount'] as num).toInt(),
      isPinned: json['isPinned'] as bool,
      isLocked: json['isLocked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ForumAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForumTopicToJson(ForumTopic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'author': instance.author,
      'replyCount': instance.replyCount,
      'viewCount': instance.viewCount,
      'isPinned': instance.isPinned,
      'isLocked': instance.isLocked,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'attachments': instance.attachments,
    };

TopicDetailResponse _$TopicDetailResponseFromJson(Map<String, dynamic> json) =>
    TopicDetailResponse(
      topic: ForumTopic.fromJson(json['topic'] as Map<String, dynamic>),
      replies: (json['replies'] as List<dynamic>)
          .map((e) => ForumReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TopicDetailResponseToJson(
        TopicDetailResponse instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'replies': instance.replies,
    };

LikeResponse _$LikeResponseFromJson(Map<String, dynamic> json) => LikeResponse(
      isLiked: json['is_liked'] as bool,
    );

Map<String, dynamic> _$LikeResponseToJson(LikeResponse instance) =>
    <String, dynamic>{
      'is_liked': instance.isLiked,
    };
