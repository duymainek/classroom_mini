import 'bindings/announcement_binding.dart';

class AnnouncementModule {
  static void init() {
    // Register bindings only; routes are centralized in AppPages
    AnnouncementBinding().dependencies();
  }
}
