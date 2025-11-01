// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatUserResponse _$ChatUserResponseFromJson(Map<String, dynamic> json) =>
    ChatUserResponse(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown User',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'student',
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChatUserResponseToJson(ChatUserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
      'lastSeen': instance.lastSeen?.toIso8601String(),
      'metadata': instance.metadata,
    };

ChatMessageResponse _$ChatMessageResponseFromJson(Map<String, dynamic> json) =>
    ChatMessageResponse(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      text: json['text'] as String?,
      type: json['type'] as String? ?? 'text',
      status: json['status'] as String?,
      uri: json['uri'] as String?,
      name: json['name'] as String?,
      size: (json['size'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      repliedMessageId: json['repliedMessageId'] as String?,
      repliedMessage: json['repliedMessage'] == null
          ? null
          : ChatMessageResponse.fromJson(
              json['repliedMessage'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
      author: json['author'] == null
          ? null
          : ChatUserResponse.fromJson(json['author'] as Map<String, dynamic>),
      readBy:
          (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ChatMessageResponseToJson(
        ChatMessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'authorId': instance.authorId,
      'text': instance.text,
      'type': instance.type,
      'status': instance.status,
      'uri': instance.uri,
      'name': instance.name,
      'size': instance.size,
      'mimeType': instance.mimeType,
      'width': instance.width,
      'height': instance.height,
      'repliedMessageId': instance.repliedMessageId,
      'repliedMessage': instance.repliedMessage,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'author': instance.author,
      'readBy': instance.readBy,
    };

ConversationResponse _$ConversationResponseFromJson(
        Map<String, dynamic> json) =>
    ConversationResponse(
      roomId: json['roomId'] as String? ?? '',
      type: json['type'] as String? ?? 'direct',
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      otherUser: json['otherUser'] == null
          ? null
          : ChatUserResponse.fromJson(
              json['otherUser'] as Map<String, dynamic>),
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessageResponse.fromJson(
              json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ConversationResponseToJson(
        ConversationResponse instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'type': instance.type,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'otherUser': instance.otherUser,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'isMuted': instance.isMuted,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

ChatRoomResponse _$ChatRoomResponseFromJson(Map<String, dynamic> json) =>
    ChatRoomResponse(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      otherUser: json['otherUser'] == null
          ? null
          : ChatUserResponse.fromJson(
              json['otherUser'] as Map<String, dynamic>),
      isMuted: json['isMuted'] as bool,
      isArchived: json['isArchived'] as bool,
      unreadCount: (json['unreadCount'] as num).toInt(),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ChatRoomResponseToJson(ChatRoomResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'otherUser': instance.otherUser,
      'isMuted': instance.isMuted,
      'isArchived': instance.isArchived,
      'unreadCount': instance.unreadCount,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

SearchUserResponse _$SearchUserResponseFromJson(Map<String, dynamic> json) =>
    SearchUserResponse(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      existingRoomId: json['existingRoomId'] as String?,
    );

Map<String, dynamic> _$SearchUserResponseToJson(SearchUserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
      'existingRoomId': instance.existingRoomId,
    };

ConversationsListResponse _$ConversationsListResponseFromJson(
        Map<String, dynamic> json) =>
    ConversationsListResponse(
      conversations: (json['conversations'] as List<dynamic>)
          .map((e) => ConversationResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$ConversationsListResponseToJson(
        ConversationsListResponse instance) =>
    <String, dynamic>{
      'conversations': instance.conversations,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };

MessagesListResponse _$MessagesListResponseFromJson(
        Map<String, dynamic> json) =>
    MessagesListResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool,
    );

Map<String, dynamic> _$MessagesListResponseToJson(
        MessagesListResponse instance) =>
    <String, dynamic>{
      'messages': instance.messages,
      'hasMore': instance.hasMore,
    };

UnreadCountResponse _$UnreadCountResponseFromJson(Map<String, dynamic> json) =>
    UnreadCountResponse(
      unreadCount: (json['unreadCount'] as num).toInt(),
    );

Map<String, dynamic> _$UnreadCountResponseToJson(
        UnreadCountResponse instance) =>
    <String, dynamic>{
      'unreadCount': instance.unreadCount,
    };
