import 'package:json_annotation/json_annotation.dart';

part 'chat_response.g.dart';

@JsonSerializable()
class ChatUserResponse {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(name: 'fullName', defaultValue: 'Unknown User')
  final String fullName;
  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;
  @JsonKey(defaultValue: 'student')
  final String role;
  @JsonKey(name: 'lastSeen')
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  ChatUserResponse({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.lastSeen,
    this.metadata,
  });

  factory ChatUserResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserResponseToJson(this);
  
  bool get isOnline => metadata?['online'] == true;
  bool get isInstructor => role == 'instructor';
  
  String get displayName => fullName;
  String get roleLabel => isInstructor ? 'Instructor' : 'Student';
}

@JsonSerializable()
class ChatMessageResponse {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(name: 'roomId', defaultValue: '')
  final String roomId;
  @JsonKey(name: 'authorId', defaultValue: '')
  final String authorId;
  final String? text;
  @JsonKey(defaultValue: 'text')
  final String type;
  final String? status;
  final String? uri;
  final String? name;
  final int? size;
  @JsonKey(name: 'mimeType')
  final String? mimeType;
  final double? width;
  final double? height;
  @JsonKey(name: 'repliedMessageId')
  final String? repliedMessageId;
  @JsonKey(name: 'repliedMessage')
  final ChatMessageResponse? repliedMessage;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'createdAt', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;
  final ChatUserResponse? author;
  @JsonKey(name: 'readBy')
  final List<String>? readBy;

  ChatMessageResponse({
    required this.id,
    required this.roomId,
    required this.authorId,
    this.text,
    required this.type,
    this.status,
    this.uri,
    this.name,
    this.size,
    this.mimeType,
    this.width,
    this.height,
    this.repliedMessageId,
    this.repliedMessage,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.readBy,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageResponseToJson(this);
  
  bool get isTextMessage => type == 'text';
  bool get isImageMessage => type == 'image';
  bool get isFileMessage => type == 'file';
  bool get hasReply => repliedMessageId != null;
  
  String get displayTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

@JsonSerializable()
class ConversationResponse {
  @JsonKey(name: 'roomId', defaultValue: '')
  final String roomId;
  @JsonKey(defaultValue: 'direct')
  final String type;
  final String? name;
  @JsonKey(name: 'imageUrl')
  final String? imageUrl;
  @JsonKey(name: 'otherUser')
  final ChatUserResponse? otherUser;
  @JsonKey(name: 'lastMessage')
  final ChatMessageResponse? lastMessage;
  @JsonKey(name: 'unreadCount', defaultValue: 0)
  final int unreadCount;
  @JsonKey(name: 'isMuted', defaultValue: false)
  final bool isMuted;
  @JsonKey(name: 'updatedAt', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;

  ConversationResponse({
    required this.roomId,
    required this.type,
    this.name,
    this.imageUrl,
    this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.isMuted,
    required this.updatedAt,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationResponseToJson(this);
  
  bool get isDirect => type == 'direct';
  bool get hasUnread => unreadCount > 0;
  
  String get displayName {
    if (isDirect && otherUser != null) {
      return otherUser!.displayName;
    }
    return name ?? 'Chat';
  }
  
  String? get displayAvatar {
    if (isDirect && otherUser != null) {
      return otherUser!.avatarUrl;
    }
    return imageUrl;
  }
  
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    if (lastMessage!.isTextMessage) return lastMessage!.text ?? '';
    if (lastMessage!.isImageMessage) return '📷 Image';
    if (lastMessage!.isFileMessage) return '📎 ${lastMessage!.name}';
    return 'Message';
  }
}

@JsonSerializable()
class ChatRoomResponse {
  final String id;
  final String type;
  final String? name;
  @JsonKey(name: 'imageUrl')
  final String? imageUrl;
  @JsonKey(name: 'otherUser')
  final ChatUserResponse? otherUser;
  @JsonKey(name: 'isMuted')
  final bool isMuted;
  @JsonKey(name: 'isArchived')
  final bool isArchived;
  @JsonKey(name: 'unreadCount')
  final int unreadCount;
  @JsonKey(name: 'updatedAt', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;

  ChatRoomResponse({
    required this.id,
    required this.type,
    this.name,
    this.imageUrl,
    this.otherUser,
    required this.isMuted,
    required this.isArchived,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomResponseToJson(this);
}

@JsonSerializable()
class SearchUserResponse {
  final String id;
  @JsonKey(name: 'fullName')
  final String fullName;
  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;
  final String role;
  @JsonKey(name: 'existingRoomId')
  final String? existingRoomId;

  SearchUserResponse({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.existingRoomId,
  });

  factory SearchUserResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SearchUserResponseToJson(this);
}

@JsonSerializable()
class ConversationsListResponse {
  final List<ConversationResponse> conversations;
  final int total;
  final int limit;
  final int offset;

  ConversationsListResponse({
    required this.conversations,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ConversationsListResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationsListResponseFromJson(json);
}

@JsonSerializable()
class MessagesListResponse {
  final List<ChatMessageResponse> messages;
  @JsonKey(name: 'hasMore')
  final bool hasMore;

  MessagesListResponse({required this.messages, required this.hasMore});

  factory MessagesListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesListResponseFromJson(json);
}

@JsonSerializable()
class UnreadCountResponse {
  @JsonKey(name: 'unreadCount')
  final int unreadCount;

  UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);
}

DateTime _dateTimeFromJson(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  if (value is DateTime) return value;
  return DateTime.now();
}

