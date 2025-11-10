import 'package:json_annotation/json_annotation.dart';

part 'forum_response.g.dart';

// =====================================================
// USER RESPONSE MODEL
// =====================================================

@JsonSerializable()
class ForumAuthor {
  final String id;

  @JsonKey(name: 'fullName')
  final String? fullName;

  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;

  final String? role; // 'instructor' or 'student'

  ForumAuthor({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.role,
  });

  factory ForumAuthor.fromJson(Map<String, dynamic> json) =>
      _$ForumAuthorFromJson(json);

@override
  Map<String, dynamic> toJson() => _$ForumAuthorToJson(this);

  bool get isInstructor => role == 'instructor';
}

// =====================================================
// COURSE RESPONSE MODEL
// =====================================================

@JsonSerializable()
class ForumCourse {
  final String id;
  final String code;
  final String name;

  ForumCourse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ForumCourse.fromJson(Map<String, dynamic> json) =>
      _$ForumCourseFromJson(json);

@override
  Map<String, dynamic> toJson() => _$ForumCourseToJson(this);
}

// =====================================================
// ATTACHMENT RESPONSE MODEL
// =====================================================

@JsonSerializable()
class ForumAttachment {
  final String id;

  @JsonKey(name: 'file_name')
  final String fileName;

  @JsonKey(name: 'file_url')
  final String fileUrl;

  @JsonKey(name: 'file_size')
  final int fileSize;

  @JsonKey(name: 'file_type')
  final String fileType;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  ForumAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    this.createdAt,
  });

  factory ForumAttachment.fromJson(Map<String, dynamic> json) =>
      _$ForumAttachmentFromJson(json);

@override
  Map<String, dynamic> toJson() => _$ForumAttachmentToJson(this);

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// =====================================================
// REPLY RESPONSE MODEL
// =====================================================

@JsonSerializable()
class ForumReply {
  final String id;

  @JsonKey(name: 'topicId')
  final String topicId;

  @JsonKey(name: 'parentReplyId')
  final String? parentReplyId;

  final String content;

  final ForumAuthor author;

  @JsonKey(name: 'likeCount')
  final int likeCount;

  @JsonKey(name: 'isLiked')
  final bool isLiked;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  final List<ForumAttachment>? attachments;

  final List<ForumReply>? replies; // Nested replies

  ForumReply({
    required this.id,
    required this.topicId,
    this.parentReplyId,
    required this.content,
    required this.author,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
    this.attachments,
    this.replies,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) =>
      _$ForumReplyFromJson(json);

@override
  Map<String, dynamic> toJson() => _$ForumReplyToJson(this);

  bool get hasReplies => replies != null && replies!.isNotEmpty;
}

// =====================================================
// TOPIC RESPONSE MODEL
// =====================================================

@JsonSerializable()
class ForumTopic {
  final String id;

  final String title;
  final String content;

  final ForumAuthor author;

  @JsonKey(name: 'replyCount')
  final int replyCount;

  @JsonKey(name: 'viewCount')
  final int viewCount;

  @JsonKey(name: 'isPinned')
  final bool isPinned;

  @JsonKey(name: 'isLocked')
  final bool isLocked;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  final List<ForumAttachment>? attachments;

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.replyCount,
    required this.viewCount,
    required this.isPinned,
    required this.isLocked,
    required this.createdAt,
    required this.updatedAt,
    this.attachments,
  });

  factory ForumTopic.fromJson(Map<String, dynamic> json) =>
      _$ForumTopicFromJson(json);

@override
  Map<String, dynamic> toJson() => _$ForumTopicToJson(this);

  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
}

// =====================================================
// TOPIC DETAIL RESPONSE MODEL
// =====================================================

@JsonSerializable()
class TopicDetailResponse {
  final ForumTopic topic;
  final List<ForumReply> replies;

  TopicDetailResponse({
    required this.topic,
    required this.replies,
  });

  factory TopicDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TopicDetailResponseFromJson(json);

@override
  Map<String, dynamic> toJson() => _$TopicDetailResponseToJson(this);
}

// =====================================================
// LIKE RESPONSE MODEL
// =====================================================

@JsonSerializable()
class LikeResponse {
  @JsonKey(name: 'is_liked')
  final bool isLiked;

  LikeResponse({required this.isLiked});

  factory LikeResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeResponseFromJson(json);

@override
  Map<String, dynamic> toJson() => _$LikeResponseToJson(this);
}
