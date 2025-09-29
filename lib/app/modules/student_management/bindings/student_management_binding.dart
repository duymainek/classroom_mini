import 'package:get/get.dart';
import '../../student_management/controllers/student_management_controller.dart';

class StudentManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentManagementController>(
        () => StudentManagementController());
  }
}
