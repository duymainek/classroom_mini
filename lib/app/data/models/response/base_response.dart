import 'package:json_annotation/json_annotation.dart';

part 'base_response.g.dart';

@JsonSerializable()
class BaseResponse {
  final bool success;
  final String? message;
  final String? code;
  final List<String>? errors;

  BaseResponse({
    required this.success,
    this.message,
    this.code,
    this.errors,
  });

  factory BaseResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BaseResponseToJson(this);
}
