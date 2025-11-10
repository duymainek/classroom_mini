import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/chat_response.dart';
import 'package:classroom_mini/app/data/models/request/chat_request.dart';
import 'package:classroom_mini/app/data/services/chat_api_service.dart';
import 'package:classroom_mini/app/data/services/chat_socket_service.dart';
import 'package:classroom_mini/app/core/services/auth_service.dart';

class ChatRoomController extends GetxController {
  final ChatApiService _chatApi;
  final ChatSocketService _socketService;

  ChatRoomController(this._chatApi, this._socketService);

  final messages = <ChatMessageResponse>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final typingUsers = <String>[].obs;

  late String roomId;
  late ConversationResponse conversation;
  final messageText = ''.obs;

  @override
  void onInit() {
    super.onInit();

    roomId = Get.arguments['roomId'];
    conversation = Get.arguments['conversation'];

    _socketService.joinRoom(roomId);

    loadMessages();

    setupSocketListeners();
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (refresh) {
      messages.clear();
      hasMore.value = true;
    }

    isLoading.value = true;

    try {
      final response = await _chatApi.getRoomMessages(
        roomId,
        limit: 50,
      );

      if (response.success && response.data != null) {
        // Backend returns messages ordered by created_at DESC (newest first)
        // ListView with reverse: true needs newest first, so we keep order as is
        messages.value = response.data!.messages;
        hasMore.value = response.data!.hasMore;

        if (messages.isNotEmpty) {
          // With reverse: true, newest is at index 0, so we use first
          await markAsRead(messages.first.id);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMore.value || messages.isEmpty) return;

    isLoadingMore.value = true;

    try {
      // With reverse: true ListView, oldest is at the end
      final oldestMessageId = messages.last.id;

      final response = await _chatApi.getRoomMessages(
        roomId,
        limit: 30,
        before: oldestMessageId,
      );

      if (response.success && response.data != null) {
        // Older messages are returned in DESC order (newer older messages first)
        // With reverse: true ListView, we add at the end (older messages go after current oldest)
        messages.addAll(response.data!.messages);
        hasMore.value = response.data!.hasMore;
      }
    } catch (e) {
      debugPrint('Failed to load more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setupSocketListeners() {
    final authService = Get.find<AuthService>();

    _socketService.onNewMessage = (message) {
      final currentUserId = authService.user.value?.id;

      // If this is our own message, skip it - will be handled by onMessageSent
      if (currentUserId != null && message.authorId == currentUserId) {
        // Check if we have a temp message waiting to be updated
        final hasTempMessage = messages.any((m) =>
            (m.id.startsWith('temp_') || m.status == 'sending') &&
            m.text == message.text &&
            m.authorId == currentUserId);
        if (hasTempMessage) {
          // Skip, will be handled by onMessageSent
          return;
        }
      }

      // For messages from others, add them normally
      // With reverse: true ListView, newest messages should be at index 0
      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex != -1) {
        messages[existingIndex] = message;
      } else {
        // Add new message at the beginning (newest first for reverse ListView)
        messages.insert(0, message);
      }

      if (currentUserId != null && message.authorId != currentUserId) {
        markAsRead(message.id);
      }
    };

    _socketService.onMessageSent = (tempId, realMessage) {
      // Find and replace temp message
      final index = messages.indexWhere((m) =>
          m.id == tempId ||
          (m.status == 'sending' &&
              m.text == realMessage.text &&
              m.authorId == realMessage.authorId));

      if (index != -1) {
        // Replace temp message with real one
        messages[index] = realMessage;

        // Remove any duplicates with same ID
        final duplicates = <int>[];
        for (int i = 0; i < messages.length; i++) {
          if (i != index && messages[i].id == realMessage.id) {
            duplicates.add(i);
          }
        }
        // Remove duplicates in reverse order to maintain indices
        for (int i = duplicates.length - 1; i >= 0; i--) {
          messages.removeAt(duplicates[i]);
        }
      } else {
        // No temp message found, check if real message already exists
        final existingIndex =
            messages.indexWhere((m) => m.id == realMessage.id);
        if (existingIndex == -1) {
          // Add at beginning for reverse ListView (newest first)
          messages.insert(0, realMessage);
        }
      }
    };

    _socketService.onUserTyping = (userId, isTyping) {
      if (isTyping) {
        if (!typingUsers.contains(userId)) {
          typingUsers.add(userId);
        }
      } else {
        typingUsers.remove(userId);
      }
    };

    _socketService.onMessagesRead = (lastMessageId) {
      for (var msg in messages) {
        if (msg.id == lastMessageId) break;
      }
    };
  }

  Future<void> sendMessage() async {
    if (messageText.value.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final text = messageText.value.trim();

    final authService = Get.find<AuthService>();
    final currentUserId = authService.user.value?.id ?? '';

    final tempMessage = ChatMessageResponse(
      id: tempId,
      roomId: roomId,
      authorId: currentUserId,
      text: text,
      type: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'sending',
    );

    // Add temp message at beginning for reverse ListView (newest first)
    messages.insert(0, tempMessage);

    messageText.value = '';

    _socketService.sendMessage(SendMessageRequest(
      roomId: roomId,
      text: text,
      type: 'text',
      tempId: tempId,
    ));

    onTyping(false);
  }

  void onTyping(bool isTyping) {
    _socketService.sendTypingIndicator(roomId, isTyping);
  }

  Future<void> markAsRead(String lastMessageId) async {
    try {
      await _chatApi.markAsRead(roomId);
      _socketService.markAsRead(roomId, lastMessageId);
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  Future<void> sendImage(String imagePath) async {
    Get.snackbar('TODO', 'Image upload not yet implemented');
  }

  Future<void> sendFile(String filePath) async {
    Get.snackbar('TODO', 'File upload not yet implemented');
  }

  @override
  void onClose() {
    _socketService.leaveRoom();
    super.onClose();
  }
}
