import 'package:json_annotation/json_annotation.dart';

part 'course_request.g.dart';

@JsonSerializable()
class CourseCreateRequest {
  final String code;
  final String name;
  final int sessionCount;
  final String semesterId;

  const CourseCreateRequest({
    required this.code,
    required this.name,
    required this.sessionCount,
    required this.semesterId,
  });

  factory CourseCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$CourseCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CourseCreateRequestToJson(this);
}

@JsonSerializable()
class CourseUpdateRequest {
  final String? code;
  final String? name;
  final int? sessionCount;
  final String? semesterId;
  final bool? isActive;

  const CourseUpdateRequest({
    this.code,
    this.name,
    this.sessionCount,
    this.semesterId,
    this.isActive,
  });

  factory CourseUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$CourseUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CourseUpdateRequestToJson(this);
}
