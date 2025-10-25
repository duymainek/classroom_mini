import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:classroom_mini/app/shared/controllers/shared_file_attachment_controller.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class AssignmentBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký Dio instance (singleton)
    Get.lazyPut<Dio>(() => Dio());
    // Đăng ký AttachmentApiService (retrofit)
    Get.lazyPut<ApiService>(
      () => ApiService(Get.find<Dio>()),
    );
    // Đăng ký AttachmentUploadController
    Get.lazyPut<AssignmentController>(() => AssignmentController());
    Get.lazyPut<SharedFileAttachmentController>(
        () => SharedFileAttachmentController());
  }
}
