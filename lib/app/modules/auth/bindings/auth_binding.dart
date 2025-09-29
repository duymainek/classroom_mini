import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Use put to register the controller permanently
    Get.put<LoginController>(LoginController(), permanent: true);
  }
}
