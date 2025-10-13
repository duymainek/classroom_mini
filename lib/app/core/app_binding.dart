import 'package:get/get.dart';
import 'app_config.dart';

/**
 * AppBinding khởi tạo các dependencies toàn cục của ứng dụng
 * Bao gồm AppConfig và các controller cần thiết
 */
class AppBinding extends Bindings {
  @override
  void dependencies() {
    print('Registering AppConfig...');
    Get.put<AppConfig>(AppConfig(), permanent: true);
  }
}
