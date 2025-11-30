import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/chat_api_service.dart';
import 'package:classroom_mini/app/data/services/chat_socket_service.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import '../controllers/chat_list_controller.dart';
import '../controllers/chat_room_controller.dart';
import '../controllers/new_chat_controller.dart';
import '../controllers/ai_chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final dio = DioClient.dio;
    
    // Register ChatApiService if not already registered
    if (!Get.isRegistered<ChatApiService>()) {
      Get.lazyPut<ChatApiService>(
        () => ChatApiService(dio),
        fenix: true,
      );
    }
    
    // ChatSocketService should already be registered in CoreBinding
    // Just ensure it exists, if not register it
    if (!Get.isRegistered<ChatSocketService>()) {
      Get.put<ChatSocketService>(
        ChatSocketService(),
        permanent: true,
      );
    }
    
    // Register ChatListController - ensure it's available immediately for HomeView
    if (!Get.isRegistered<ChatListController>()) {
      Get.put<ChatListController>(
        ChatListController(
          Get.find<ChatApiService>(),
          Get.find<ChatSocketService>(),
        ),
        permanent: false,
      );
    }
    
    Get.lazyPut<ChatRoomController>(
      () => ChatRoomController(
        Get.find<ChatApiService>(),
        Get.find<ChatSocketService>(),
      ),
    );
    
    Get.lazyPut<NewChatController>(
      () => NewChatController(Get.find<ChatApiService>()),
    );
    
    Get.lazyPut<AiChatController>(
      () => AiChatController(),
    );
  }
}

