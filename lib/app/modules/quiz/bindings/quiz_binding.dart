import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/quiz_api_service.dart';
import '../controllers/quiz_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.find<ApiService>().dio;
    Get.lazyPut<QuizApiService>(() => QuizApiService(dio));
    Get.lazyPut<QuizController>(
      () => QuizController(Get.find<QuizApiService>(), Get.find<ApiService>()),
    );
  }
}
