import 'package:json_annotation/json_annotation.dart';

part 'material_request.g.dart';

@JsonSerializable()
class CreateMaterialRequest {
  final String title;
  final String? description;
  @JsonKey(name: 'courseId')
  final String courseId;
  @JsonKey(name: 'attachmentIds')
  final List<String>? attachmentIds;

  const CreateMaterialRequest({
    required this.title,
    this.description,
    required this.courseId,
    this.attachmentIds,
  });

  factory CreateMaterialRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMaterialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMaterialRequestToJson(this);
}

@JsonSerializable()
class UpdateMaterialRequest {
  final String? title;
  final String? description;
  @JsonKey(name: 'attachmentIds')
  final List<String>? attachmentIds;

  const UpdateMaterialRequest({
    this.title,
    this.description,
    this.attachmentIds,
  });

  factory UpdateMaterialRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMaterialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMaterialRequestToJson(this);
}
