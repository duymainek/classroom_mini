import 'package:get/get.dart';
import 'bindings/profile_binding.dart';

class ProfileModule {
  static void init() {
    ProfileBinding().dependencies();
  }
}
