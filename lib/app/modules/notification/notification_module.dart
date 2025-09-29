import 'package:get/get.dart';
import 'bindings/notification_binding.dart';

class NotificationModule {
  static void init() {
    NotificationBinding().dependencies();
  }
}
