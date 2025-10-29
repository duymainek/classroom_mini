import 'package:json_annotation/json_annotation.dart';
import 'base_response.dart';

part 'data_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class DataResponse<T> extends BaseResponse {
  final T? data;

  DataResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory DataResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$DataResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonWithConverter(Object? Function(T value) toJsonT) =>
      _$DataResponseToJson(this, toJsonT);

  // Override base toJson for compatibility
  @override
  Map<String, dynamic> toJson() =>
      _$DataResponseToJson(this, (value) => value as Object?);
}
