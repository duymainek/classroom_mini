import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import 'package:classroom_mini/app/data/services/notification_service.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
