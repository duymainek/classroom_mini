import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_controller.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_detail_controller.dart';
import 'package:classroom_mini/app/data/services/forum_service.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';

/**
 * Forum Binding
 * Dependency injection for forum module
 */
class ForumBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ApiServiceWrapper is available
    if (!Get.isRegistered<ApiServiceWrapper>()) {
      Get.lazyPut<ApiServiceWrapper>(() => ApiServiceWrapper(DioClient.dio));
    }

    Get.lazyPut<ForumService>(() => ForumService());
    Get.lazyPut<ForumController>(() => ForumController());
    Get.lazyPut<ForumDetailController>(() => ForumDetailController());
  }
}
