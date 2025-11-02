import 'package:json_annotation/json_annotation.dart';

part 'forum_request.g.dart';

// =====================================================
// REQUEST MODELS
// =====================================================

@JsonSerializable()
class CreateTopicRequest {
  final String title;
  final String content;

  @JsonKey(name: 'attachment_ids')
  final List<String>? attachmentIds;

  CreateTopicRequest({
    required this.title,
    required this.content,
    this.attachmentIds,
  });

  factory CreateTopicRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTopicRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTopicRequestToJson(this);
}

@JsonSerializable()
class CreateReplyRequest {
  final String content;

  @JsonKey(name: 'parent_reply_id')
  final String? parentReplyId;

  @JsonKey(name: 'attachment_ids')
  final List<String>? attachmentIds;

  CreateReplyRequest({
    required this.content,
    this.parentReplyId,
    this.attachmentIds,
  });

  factory CreateReplyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReplyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReplyRequestToJson(this);
}

@JsonSerializable()
class UpdateTopicRequest {
  final String? title;
  final String? content;

  UpdateTopicRequest({
    this.title,
    this.content,
  });

  factory UpdateTopicRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTopicRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTopicRequestToJson(this);
}

@JsonSerializable()
class UpdateReplyRequest {
  final String content;

  UpdateReplyRequest({
    required this.content,
  });

  factory UpdateReplyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateReplyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateReplyRequestToJson(this);
}
