import 'package:get/get.dart';
import '../controllers/core_management_controller.dart';
import '../../../data/repositories/semester_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/services/api_service.dart';

class CoreManagementBinding extends Bindings {
  @override
  void dependencies() {
    // Get API service instance
    final apiService = Get.find<ApiService>();

    // Initialize repositories
    final semesterRepository = SemesterRepository(apiService);
    final courseRepository = CourseRepository(apiService);
    final groupRepository = GroupRepository(apiService);

    // Register repositories
    Get.lazyPut<SemesterRepository>(() => semesterRepository);
    Get.lazyPut<CourseRepository>(() => courseRepository);
    Get.lazyPut<GroupRepository>(() => groupRepository);

    // Initialize and register controller
    Get.lazyPut<CoreManagementController>(
      () => CoreManagementController(
        semesterRepository,
        courseRepository,
        groupRepository,
      ),
    );
  }
}
