import 'package:get/get.dart';
import '../controllers/submit_assignment_controller.dart';
import '../../../../data/repositories/student_submission_repository.dart';
import '../../../../data/services/api_service.dart';

class SubmitAssignmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentSubmissionRepository>(
      () => StudentSubmissionRepository(ApiService(DioClient.dio)),
    );
    Get.lazyPut<SubmitAssignmentController>(
      () => SubmitAssignmentController(Get.find()),
    );
  }
}
