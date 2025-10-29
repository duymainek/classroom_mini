import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'package:classroom_mini/app/data/services/api_service.dart';

/**
 * Material Detail Controller
 * Handles material detail operations and state management
 */
class MaterialDetailController extends GetxController {
  final ApiService _apiService = ApiService(DioClient.dio);

  // Observable state
  final Rx<material_resp.Material?> material =
      Rx<material_resp.Material?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  /**
   * Load material detail by ID
   */
  Future<void> loadMaterialDetail(String materialId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getMaterialById(materialId);

      if (response.success && response.data != null) {
        material.value = response.data!.material;
        // Note: View tracking is now handled automatically in backend when fetching material detail
      } else {
        errorMessage.value = response.message;
        material.value = null;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load material detail: $e';
      material.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /**
   * Clear error message
   */
  void clearError() {
    errorMessage.value = '';
  }

  /**
   * Refresh material detail
   */
  Future<void> refreshMaterialDetail(String materialId) async {
    await loadMaterialDetail(materialId);
  }
}
