import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/services/announcement_api_service.dart';
import 'package:classroom_mini/app/modules/announcements/controllers/announcement_controller.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    // Sử dụng DioClient.dio thay vì tự init Dio
    // Đăng ký ApiService (retrofit)
    Get.lazyPut<ApiService>(
      () => ApiService(DioClient.dio),
    );

    // Đăng ký AnnouncementApiService
    Get.lazyPut<AnnouncementApiService>(
      () => AnnouncementApiService(DioClient.dio),
    );

    // Đăng ký AnnouncementController
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
  }
}
