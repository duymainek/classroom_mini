import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/request/material_request.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';

/**
 * Material Controller
 * Handles all material-related operations
 */
class MaterialController extends GetxController {
  final ApiService _apiService = ApiService(DioClient.dio);

  // Observable state
  final RxList<material_resp.Material> materials =
      <material_resp.Material>[].obs;
  final RxList<Course> courses = <Course>[].obs;
  final RxList<Group> groups = <Group>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isFormLoading = false.obs;
  final RxBool isLoadingCourses = false.obs;
  final RxBool isLoadingGroups = false.obs;
  final RxString errorMessage = ''.obs;

  // Form state
  final RxString title = ''.obs;
  final RxString description = ''.obs;
  final RxString courseId = ''.obs;
  final RxList<String> attachmentIds = <String>[].obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMorePages = false.obs;

  // Search and filters
  final RxString searchQuery = ''.obs;
  final RxString selectedCourseId = ''.obs;
  final RxString sortBy = 'created_at'.obs;
  final RxString sortOrder = 'desc'.obs;

  @override
  void onInit() {
    super.onInit();
    loadMaterials();
    loadCourses();
  }

  /**
   * Initialize form state
   */
  void initFormState() {
    title.value = '';
    description.value = '';
    courseId.value = '';
    attachmentIds.clear();
  }

  /**
   * Update form state
   */
  void updateForm(Function(MaterialFormState) updater) {
    final state = MaterialFormState(
      title: title.value,
      description: description.value,
      courseId: courseId.value,
      attachmentIds: attachmentIds.toList(),
    );
    updater(state);
    title.value = state.title;
    description.value = state.description;
    courseId.value = state.courseId;
    attachmentIds.assignAll(state.attachmentIds);
  }

  /**
   * Load materials with pagination and filters
   */
  Future<void> loadMaterials({
    int page = 1,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        materials.clear();
        currentPage.value = 1;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getMaterials(
        page: page,
        limit: 20,
        search: searchQuery.value,
        courseId:
            selectedCourseId.value.isEmpty ? null : selectedCourseId.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          materials.assignAll(response.data!.materials ?? []);
        } else {
          materials.addAll(response.data!.materials ?? []);
        }

        if (response.data!.pagination != null) {
          currentPage.value = response.data!.pagination!.page;
          totalPages.value = response.data!.pagination!.pages;
          totalItems.value = response.data!.pagination!.total;
          hasMorePages.value = currentPage.value < totalPages.value;
        }
      } else {
        errorMessage.value = response.message;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load materials: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /**
   * Load more materials (pagination)
   */
  Future<void> loadMoreMaterials() async {
    if (hasMorePages.value && !isLoading.value) {
      await loadMaterials(page: currentPage.value + 1);
    }
  }

  /**
   * Refresh materials
   */
  Future<void> refreshMaterials() async {
    await loadMaterials(refresh: true);
  }

  /**
   * Search materials
   */
  Future<void> searchMaterials(String query) async {
    searchQuery.value = query;
    await loadMaterials(refresh: true);
  }

  /**
   * Filter by course
   */
  Future<void> filterByCourse(String? courseId) async {
    selectedCourseId.value = courseId ?? '';
    await loadMaterials(refresh: true);
  }

  /**
   * Sort materials
   */
  Future<void> sortMaterials(String field, String order) async {
    sortBy.value = field;
    sortOrder.value = order;
    await loadMaterials(refresh: true);
  }

  /**
   * Load courses for dropdown
   */
  Future<void> loadCourses() async {
    try {
      isLoadingCourses.value = true;
      final response = await _apiService.getCourses();

      if (response.success) {
        courses.assignAll(response.data.courses);
      }
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      isLoadingCourses.value = false;
    }
  }

  /**
   * Load groups by course
   */
  Future<void> loadGroupsByCourse(String courseId) async {
    try {
      isLoadingGroups.value = true;
      final response = await _apiService.getGroupsByCourse(courseId);

      if (response.success) {
        groups.assignAll(response.data.groups);
      }
    } catch (e) {
      print('Error loading groups: $e');
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /**
   * Create new material
   */
  Future<String?> createMaterial(CreateMaterialRequest request) async {
    try {
      // Không cần thiết lập isFormLoading nếu dialog được quản lý trong form
      // isFormLoading.value = true;  // Comment dòng này
      errorMessage.value = '';

      final response = await _apiService.createMaterial(request);

      if (response.success && response.data != null) {
        // Add to materials list
        materials.insert(0, response.data!.material!);
        totalItems.value++;

        return response.data!.material!.id;
      } else {
        errorMessage.value = response.message;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Failed to create material: $e';
      return null;
    } finally {
      // isFormLoading.value = false;  // Comment dòng này
    }
  }

  /**
   * Update material
   */
  Future<bool> updateMaterial(
      String materialId, UpdateMaterialRequest request) async {
    try {
      // Không cần thiết lập isFormLoading nếu dialog được quản lý trong form
      // isFormLoading.value = true;  // Comment dòng này
      errorMessage.value = '';

      final response = await _apiService.updateMaterial(materialId, request);

      if (response.success && response.data != null) {
        // Update in materials list
        final index = materials.indexWhere((m) => m.id == materialId);
        if (index != -1) {
          materials[index] = response.data!.material!;
        }

        return true;
      } else {
        errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update material: $e';
      return false;
    } finally {
      // isFormLoading.value = false;  // Comment dòng này
    }
  }

  /**
   * Delete material
   */
  Future<bool> deleteMaterial(String materialId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.deleteMaterial(materialId);

      if (response.success) {
        // Remove from materials list
        materials.removeWhere((m) => m.id == materialId);
        totalItems.value--;

        return true;
      } else {
        errorMessage.value = response.message ?? '';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete material: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /**
   * Get material by ID
   */
  Future<material_resp.Material?> getMaterialById(String materialId) async {
    try {
      final response = await _apiService.getMaterialById(materialId);

      if (response.success && response.data != null) {
        return response.data!.material;
      }
      return null;
    } catch (e) {
      print('Error getting material: $e');
      return null;
    }
  }

  /**
   * Finalize attachments for material
   */
  Future<void> finalizeAttachments(
      String materialId, List<String> attachmentIds) async {
    try {
      await _apiService.finalizeMaterialAttachments(materialId, {
        'attachmentIds': attachmentIds,
      });
    } catch (e) {
      print('Error finalizing attachments: $e');
    }
  }

  /**
   * Clear error message
   */
  void clearError() {
    errorMessage.value = '';
  }

  /**
   * Get material by ID from current list
   */
  material_resp.Material? getMaterialFromList(String materialId) {
    try {
      return materials.firstWhere((m) => m.id == materialId);
    } catch (e) {
      return null;
    }
  }
}

/**
 * Form state class for material form
 */
class MaterialFormState {
  String title;
  String description;
  String courseId;
  List<String> attachmentIds;

  MaterialFormState({
    required this.title,
    required this.description,
    required this.courseId,
    required this.attachmentIds,
  });
}
