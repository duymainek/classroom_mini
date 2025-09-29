import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/quiz_api_service.dart';
import '../../../data/services/metadata_service.dart';
import '../controllers/quiz_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    final dio = DioClient.dio;
    final apiService = Get.find<ApiService>();

    Get.lazyPut<QuizApiService>(() => QuizApiService(dio));
    Get.lazyPut<MetadataService>(() => MetadataService(apiService));
    Get.lazyPut<QuizController>(
      () => QuizController(Get.find<QuizApiService>()),
    );
    Get.lazyPut<AssignmentController>(() => AssignmentController());
  }
}
