import 'package:json_annotation/json_annotation.dart';

part 'group_request.g.dart';

@JsonSerializable()
class GroupCreateRequest {
  final String name;
  final String courseId;

  const GroupCreateRequest({
    required this.name,
    required this.courseId,
  });

  factory GroupCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GroupCreateRequestToJson(this);
}

@JsonSerializable()
class GroupUpdateRequest {
  final String? name;
  final String? courseId;
  final bool? isActive;

  const GroupUpdateRequest({
    this.name,
    this.courseId,
    this.isActive,
  });

  factory GroupUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GroupUpdateRequestToJson(this);
}
