import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/materials/controllers/material_controller.dart';
import 'package:classroom_mini/app/modules/materials/controllers/material_detail_controller.dart';

/**
 * Material Binding
 * Handles dependency injection for Material module
 */
class MaterialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MaterialController>(() => MaterialController());
    Get.lazyPut<MaterialDetailController>(() => MaterialDetailController());
  }
}
