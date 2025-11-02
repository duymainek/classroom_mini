import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/profile_api_service.dart';
import '../controllers/profile_controller.dart';
import '../controllers/sync_queue_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Sử dụng DioClient.dio thay vì Get.find<ApiService>().dio
    final dio = DioClient.dio;
    Get.lazyPut<ProfileApiService>(() => ProfileApiService(dio));
    Get.lazyPut<ProfileController>(
        () => ProfileController(Get.find<ProfileApiService>()));
    Get.lazyPut<SyncQueueController>(() => SyncQueueController());
  }
}
