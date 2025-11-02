import 'package:json_annotation/json_annotation.dart';

part 'announcement_request.g.dart';

@JsonSerializable()
class CreateAnnouncementRequest {
  final String title;
  final String content;
  @JsonKey(name: 'courseId')
  final String courseId;
  @JsonKey(name: 'scopeType')
  final String scopeType;
  @JsonKey(name: 'groupIds')
  final List<String>? groupIds;
  @JsonKey(name: 'attachmentIds')
  final List<String>? attachmentIds;

  const CreateAnnouncementRequest({
    required this.title,
    required this.content,
    required this.courseId,
    required this.scopeType,
    this.groupIds,
    this.attachmentIds,
  });

  factory CreateAnnouncementRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAnnouncementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAnnouncementRequestToJson(this);
}

@JsonSerializable()
class UpdateAnnouncementRequest {
  final String? title;
  final String? content;
  @JsonKey(name: 'attachmentIds')
  final List<String>? attachmentIds;

  const UpdateAnnouncementRequest({
    this.title,
    this.content,
    this.attachmentIds,
  });

  factory UpdateAnnouncementRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAnnouncementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAnnouncementRequestToJson(this);
}

@JsonSerializable()
class AddCommentRequest {
  @JsonKey(name: 'commentText')
  final String commentText;
  @JsonKey(name: 'parentCommentId')
  final String? parentCommentId;

  const AddCommentRequest({
    required this.commentText,
    this.parentCommentId,
  });

  factory AddCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$AddCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddCommentRequestToJson(this);
}
