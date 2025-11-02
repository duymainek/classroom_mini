import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/chat_response.dart';
import 'package:classroom_mini/app/data/models/request/chat_request.dart';
import 'package:classroom_mini/app/data/services/chat_api_service.dart';

class NewChatController extends GetxController {
  final ChatApiService _chatApi;
  
  NewChatController(this._chatApi);

  final users = <SearchUserResponse>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers({String? query}) async {
    isLoading.value = true;
    
    try {
      final response = await _chatApi.searchUsers(
        query: query,
        limit: 50,
      );
      
      if (response.success && response.data != null) {
        users.value = response.data!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      loadUsers();
    } else {
      loadUsers(query: query);
    }
  }

  Future<void> startChat(SearchUserResponse user) async {
    try {
      final response = await _chatApi.getOrCreateDirectRoom(
        CreateDirectRoomRequest(otherUserId: user.id),
      );
      
      if (response.success && response.data != null) {
        final room = response.data!;
        final conversation = ConversationResponse(
          roomId: room.id,
          type: room.type,
          name: room.name,
          imageUrl: room.imageUrl,
          otherUser: room.otherUser != null ? room.otherUser! : ChatUserResponse(
            id: user.id,
            fullName: user.fullName,
            avatarUrl: user.avatarUrl,
            role: user.role,
            lastSeen: null,
            metadata: null,
          ),
          unreadCount: 0,
          isMuted: false,
          updatedAt: room.updatedAt,
        );
        
        Get.back();
        Get.toNamed('/chat/room', arguments: {
          'roomId': room.id,
          'conversation': conversation,
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to start chat: $e');
    }
  }
}

