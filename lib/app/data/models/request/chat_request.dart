import 'package:json_annotation/json_annotation.dart';

part 'chat_request.g.dart';

@JsonSerializable()
class CreateDirectRoomRequest {
  @JsonKey(name: 'otherUserId')
  final String otherUserId;

  CreateDirectRoomRequest({required this.otherUserId});

  factory CreateDirectRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDirectRoomRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateDirectRoomRequestToJson(this);
}

@JsonSerializable()
class SendMessageRequest {
  final String roomId;
  final String? text;
  final String type;
  final String? uri;
  final String? name;
  final int? size;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  final double? width;
  final double? height;
  @JsonKey(name: 'replied_message_id')
  final String? repliedMessageId;
  @JsonKey(name: 'tempId')
  final String? tempId;

  SendMessageRequest({
    required this.roomId,
    this.text,
    required this.type,
    this.uri,
    this.name,
    this.size,
    this.mimeType,
    this.width,
    this.height,
    this.repliedMessageId,
    this.tempId,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

