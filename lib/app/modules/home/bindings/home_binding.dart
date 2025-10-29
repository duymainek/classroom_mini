import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../dashboard/bindings/dashboard_binding.dart';
import '../../notification/bindings/notification_binding.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../forum/bindings/forum_binding.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    DashboardBinding().dependencies();
    ForumBinding().dependencies();
    NotificationBinding().dependencies();
    ProfileBinding().dependencies();
  }
}
