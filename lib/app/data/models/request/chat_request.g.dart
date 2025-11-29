// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateDirectRoomRequest _$CreateDirectRoomRequestFromJson(
        Map<String, dynamic> json) =>
    CreateDirectRoomRequest(
      otherUserId: json['otherUserId'] as String,
    );

Map<String, dynamic> _$CreateDirectRoomRequestToJson(
        CreateDirectRoomRequest instance) =>
    <String, dynamic>{
      'otherUserId': instance.otherUserId,
    };

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      roomId: json['roomId'] as String,
      text: json['text'] as String?,
      type: json['type'] as String,
      uri: json['uri'] as String?,
      name: json['name'] as String?,
      size: json['size'] as int?,
      mimeType: json['mime_type'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      repliedMessageId: json['replied_message_id'] as String?,
      tempId: json['tempId'] as String?,
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'text': instance.text,
      'type': instance.type,
      'uri': instance.uri,
      'name': instance.name,
      'size': instance.size,
      'mime_type': instance.mimeType,
      'width': instance.width,
      'height': instance.height,
      'replied_message_id': instance.repliedMessageId,
      'tempId': instance.tempId,
    };
