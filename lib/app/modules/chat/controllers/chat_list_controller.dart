import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/chat_response.dart';
import 'package:classroom_mini/app/data/services/chat_api_service.dart';
import 'package:classroom_mini/app/data/services/chat_socket_service.dart';

class ChatListController extends GetxController {
  final ChatApiService _chatApi;
  final ChatSocketService _socketService;
  
  ChatListController(this._chatApi, this._socketService);

  final conversations = <ConversationResponse>[].obs;
  final isLoading = false.obs;
  final totalUnreadCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadConversations();
    setupSocketListeners();
    loadUnreadCount();
  }

  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      conversations.clear();
    }
    
    isLoading.value = true;
    
    try {
      final response = await _chatApi.getConversations(limit: 50, offset: 0);
      
      if (response.success && response.data != null) {
        conversations.value = response.data!.conversations;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setupSocketListeners() {
    _socketService.onNewMessageNotification = (roomId, message) {
      final index = conversations.indexWhere((c) => c.roomId == roomId);
      
      if (index != -1) {
        final conv = conversations[index];
        final updated = ConversationResponse(
          roomId: conv.roomId,
          type: conv.type,
          name: conv.name,
          imageUrl: conv.imageUrl,
          otherUser: conv.otherUser,
          lastMessage: message,
          unreadCount: conv.unreadCount + 1,
          isMuted: conv.isMuted,
          updatedAt: message.createdAt,
        );
        
        conversations.removeAt(index);
        conversations.insert(0, updated);
        
        totalUnreadCount.value++;
      } else {
        loadConversations(refresh: true);
      }
    };
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _chatApi.getUnreadCount();
      if (response.success && response.data != null) {
        totalUnreadCount.value = response.data!.unreadCount;
      }
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  Future<void> hideConversation(String roomId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hide Conversation'),
        content: const Text('This will hide the conversation from your list. Messages will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _chatApi.hideConversation(roomId, {'isHidden': true});
      conversations.removeWhere((c) => c.roomId == roomId);
      Get.snackbar('Success', 'Conversation hidden');
    } catch (e) {
      Get.snackbar('Error', 'Failed to hide conversation: $e');
    }
  }

  void openChatRoom(ConversationResponse conversation) {
    Get.toNamed('/chat/room', arguments: {
      'roomId': conversation.roomId,
      'conversation': conversation,
    })?.then((_) {
      loadConversations(refresh: true);
      loadUnreadCount();
    });
  }

  void openNewChat() {
    Get.toNamed('/chat/new')?.then((_) {
      loadConversations(refresh: true);
    });
  }

  @override
  void onClose() {
    super.onClose();
  }
}

