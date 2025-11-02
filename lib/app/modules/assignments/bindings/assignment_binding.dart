import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:classroom_mini/app/shared/controllers/shared_file_attachment_controller.dart';
import 'package:get/get.dart';

class AssignmentBinding extends Bindings {
  @override
  void dependencies() {
    // Sử dụng DioClient.dio thay vì tự init Dio
    // Đăng ký AttachmentApiService (retrofit)
    Get.lazyPut<ApiService>(
      () => ApiService(DioClient.dio),
    );
    // Đăng ký AttachmentUploadController
    Get.lazyPut<AssignmentController>(() => AssignmentController());
    Get.lazyPut<SharedFileAttachmentController>(
        () => SharedFileAttachmentController());
  }
}
