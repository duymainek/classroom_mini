import 'package:get/get.dart';
import 'bindings/home_binding.dart';

class HomeModule {
  static void init() {
    HomeBinding().dependencies();
  }
}
