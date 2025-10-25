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

        // Track view if material is loaded successfully
        await trackMaterialView(materialId);
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
   * Track material view
   */
  Future<void> trackMaterialView(String materialId) async {
    try {
      await _apiService.trackMaterialView(materialId);
    } catch (e) {
      print('Error tracking material view: $e');
    }
  }

  /**
   * Track file download
   */
  Future<void> trackFileDownload(String fileId) async {
    try {
      await _apiService.trackMaterialDownload(fileId);
    } catch (e) {
      print('Error tracking file download: $e');
    }
  }

  /**
   * Get material tracking data
   */
  Future<material_resp.MaterialData?> getMaterialTracking(String materialId,
      {String? groupId, String? status}) async {
    try {
      final response = await _apiService.getMaterialTracking(
          materialId, groupId ?? '', status ?? '');
      return response.data;
    } catch (e) {
      print('Error getting material tracking: $e');
      return null;
    }
  }

  /**
   * Get file download tracking data
   */
  Future<material_resp.MaterialData?> getFileDownloadTracking(String materialId,
      {String? fileId}) async {
    try {
      final response =
          await _apiService.getMaterialFileTracking(materialId, fileId);
      return response.data;
    } catch (e) {
      print('Error getting file download tracking: $e');
      return null;
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
