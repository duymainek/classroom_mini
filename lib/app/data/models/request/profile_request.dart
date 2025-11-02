import 'package:json_annotation/json_annotation.dart';

part 'profile_request.g.dart';

@JsonSerializable()
class UpdateProfileRequest {
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? email;

  UpdateProfileRequest({this.fullName, this.email});

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}
