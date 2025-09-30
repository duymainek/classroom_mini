import 'package:json_annotation/json_annotation.dart';

part 'semester_request.g.dart';

@JsonSerializable()
class SemesterCreateRequest {
  final String code;
  final String name;

  const SemesterCreateRequest({
    required this.code,
    required this.name,
  });

  factory SemesterCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SemesterCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SemesterCreateRequestToJson(this);
}

@JsonSerializable()
class SemesterUpdateRequest {
  final String? code;
  final String? name;
  final bool? isActive;

  const SemesterUpdateRequest({
    this.code,
    this.name,
    this.isActive,
  });

  factory SemesterUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$SemesterUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SemesterUpdateRequestToJson(this);
}
