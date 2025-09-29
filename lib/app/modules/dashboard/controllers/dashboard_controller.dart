import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/semester_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/semester_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/app_config.dart';

class DashboardController extends GetxController {
  // Services
  late final DashboardRepository _dashboardRepository;
  late final SemesterRepository _semesterRepository;
  late final StorageService _storageService;

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentSemester = Rxn<Semester>();
  final availableSemesters = <Semester>[].obs;

  // Dashboard data
  final instructorDashboardData = Rxn<InstructorDashboardData>();
  final studentDashboardData = Rxn<StudentDashboardData>();

  // User info
  final isInstructor = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadUserInfo();
    loadDashboard();
  }

  void _initializeServices() {
    try {
      final apiService = Get.find<ApiService>();
      _dashboardRepository = DashboardRepository(apiService);
      _semesterRepository = SemesterRepository(apiService);
      _storageService = Get.find<StorageService>();
    } catch (e) {
      AppLogger.error('Failed to initialize dashboard services', error: e);
      errorMessage.value = 'Không thể khởi tạo dịch vụ. Vui lòng thử lại.';
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _storageService.getUserData();
      if (user != null) {
        isInstructor.value = user.isInstructor;
      }
    } catch (e) {
      AppLogger.error('Failed to load user info', error: e);
    }
  }

  /// Load dashboard data based on user role
  Future<void> loadDashboard() async {
    if (isLoading.value) return;

    clearError();
    isLoading.value = true;

    try {
      // Load current semester and available semesters
      await _loadSemesterData();

      // Load dashboard data based on role
      if (isInstructor.value) {
        await _loadInstructorDashboard();
      } else {
        await _loadStudentDashboard();
      }
    } catch (e) {
      AppLogger.error('Failed to load dashboard', error: e);
      errorMessage.value = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load semester data
  Future<void> _loadSemesterData() async {
    try {
      // Get current semester
      final current = await _dashboardRepository.getCurrentSemester();
      currentSemester.value = current;

      // Get all semesters for selector
      final semestersResponse = await _semesterRepository.getSemesters(
        page: 1,
        limit: 100,
        status: 'all',
        sortBy: 'created_at',
        sortOrder: 'desc',
      );
      availableSemesters.value = semestersResponse.data.semesters;

      // Nếu chưa có học kì được chọn, tự động chọn học kì mới nhất
      if (currentSemester.value == null && availableSemesters.isNotEmpty) {
        final latestSemester = availableSemesters.first;
        currentSemester.value = latestSemester;

        // Cập nhật AppConfig
        AppConfig.instance.setSelectedSemester(
          semesterId: latestSemester.id,
          semesterName: latestSemester.name,
          semesterCode: latestSemester.code,
        );

        AppLogger.info('Auto-selected latest semester: ${latestSemester.name}');
      }
    } catch (e) {
      AppLogger.error('Failed to load semester data', error: e);
      // Don't throw error here, just log it
    }
  }

  /// Load instructor dashboard data
  Future<void> _loadInstructorDashboard() async {
    try {
      final data = await _dashboardRepository.getInstructorDashboard();
      instructorDashboardData.value = data;
    } catch (e) {
      AppLogger.error('Failed to load instructor dashboard', error: e);
      rethrow;
    }
  }

  /// Load student dashboard data
  Future<void> _loadStudentDashboard() async {
    try {
      final data = await _dashboardRepository.getStudentDashboard();
      studentDashboardData.value = data;
    } catch (e) {
      AppLogger.error('Failed to load student dashboard', error: e);
      rethrow;
    }
  }

  /// Reload dashboard data without checking isLoading state
  Future<void> _reloadDashboardData() async {
    try {
      // Load dashboard data based on role
      if (isInstructor.value) {
        await _loadInstructorDashboard();
      } else {
        await _loadStudentDashboard();
      }
    } catch (e) {
      AppLogger.error('Failed to reload dashboard data', error: e);
      rethrow;
    }
  }

  /// Switch semester context
  Future<void> switchSemester(String semesterId) async {
    if (isLoading.value) return;

    clearError();
    isLoading.value = true;

    try {
      final semester = await _dashboardRepository.switchSemester(semesterId);
      currentSemester.value = semester;

      // Cập nhật AppConfig với thông tin học kì mới
      AppConfig.instance.setSelectedSemester(
        semesterId: semester.id,
        semesterName: semester.name,
        semesterCode: semester.code,
      );

      // Reload dashboard data for new semester
      await _reloadDashboardData();

      Get.snackbar(
        'Thành công',
        'Đã chuyển sang học kỳ: ${semester.name}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Failed to switch semester', error: e);
      errorMessage.value = 'Không thể chuyển học kỳ. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Get dashboard title based on current semester
  String getDashboardTitle() {
    if (currentSemester.value != null) {
      return 'Dashboard - ${currentSemester.value!.name}';
    }
    return 'Dashboard';
  }

  /// Check if current semester is read-only (past semester)
  bool get isReadOnlyMode {
    if (currentSemester.value == null) return false;

    final now = DateTime.now();
    final semesterCreated = currentSemester.value!.createdAt;

    // Consider semester read-only if it's older than 6 months
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    return semesterCreated.isBefore(sixMonthsAgo);
  }

  /// Get semester selector items
  List<DropdownMenuItem<String>> getSemesterSelectorItems() {
    return availableSemesters.map((semester) {
      return DropdownMenuItem<String>(
        value: semester.id,
        child: Text(semester.name),
      );
    }).toList();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
