import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/services/announcement_api_service.dart';
import 'package:classroom_mini/app/modules/announcements/controllers/announcement_controller.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký Dio instance (singleton)
    Get.lazyPut<Dio>(() => Dio());

    // Đăng ký ApiService (retrofit)
    Get.lazyPut<ApiService>(
      () => ApiService(Get.find<Dio>()),
    );

    // Đăng ký AnnouncementApiService
    Get.lazyPut<AnnouncementApiService>(
      () => AnnouncementApiService(Get.find<Dio>()),
    );

    // Đăng ký AnnouncementController
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
  }
}
