import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/semester_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/app_config.dart';

class DashboardController extends GetxController {
  // Services
  late final DashboardRepository _dashboardRepository;
  late final SemesterRepository _semesterRepository;
  late final StorageService _storageService;

  // State
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final currentSemester = Rxn<Semester>();
  final availableSemesters = <Semester>[].obs;

  // Dashboard data
  final instructorDashboardData = Rxn<InstructorDashboardData>();
  final studentDashboardData = Rxn<StudentDashboardData>();

  // User info - reactive variable để view có thể dùng Obx, sync với AppConfig
  final _isInstructor = false.obs;
  bool get isInstructor => _isInstructor.value;
  RxBool get isInstructorRx => _isInstructor;

  Future<void> _loadUserInfoAndDashboard() async {
    print('👤 [DashboardController] Loading user info first...');
    final oldIsInstructor = isInstructor;
    await _loadUserInfo();
    final newIsInstructor = isInstructor;
    print(
        '✅ [DashboardController] User info loaded. isInstructor=$newIsInstructor (was: $oldIsInstructor)');

    // If role changed or dashboard data doesn't match role, reload
    if (oldIsInstructor != newIsInstructor ||
        (newIsInstructor && instructorDashboardData.value == null) ||
        (!newIsInstructor && studentDashboardData.value == null)) {
      print(
          '🔄 [DashboardController] Role changed or wrong data - reloading dashboard...');
      print('🚀 [DashboardController] Starting loadDashboardAsync...');
      await loadDashboardAsync();
    } else {
      print(
          '✅ [DashboardController] Dashboard data already matches role - no reload needed');
    }
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
      print('👤 [DashboardController] Loading user info...');
      final user = await _storageService.getUserData();
      if (user != null) {
        final wasInstructor = isInstructor;
        final newIsInstructor = user.isInstructor;

        // Update cả AppConfig và reactive variable
        AppConfig.instance.setUserRole(newIsInstructor);
        _isInstructor.value = newIsInstructor;
        print(
            '✅ [DashboardController] User info loaded: isInstructor=$newIsInstructor (was: $wasInstructor)');

        // If role changed or wrong dashboard data exists, clear it
        if (wasInstructor != newIsInstructor ||
            (newIsInstructor && studentDashboardData.value != null) ||
            (!newIsInstructor && instructorDashboardData.value != null)) {
          print('🔄 [DashboardController] Clearing wrong dashboard data');
          if (newIsInstructor) {
            studentDashboardData.value = null;
          } else {
            instructorDashboardData.value = null;
          }
        }
      } else {
        print('⚠️ [DashboardController] User data is null');
      }
    } catch (e) {
      AppLogger.error('Failed to load user info', error: e);
      print('❌ [DashboardController] Error loading user info: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    print('🚀 [DashboardController] onInit started');
    _initializeServices();

    // Sync isInstructor từ AppConfig khi init (nếu đã có trong AppConfig)
    _isInstructor.value = AppConfig.instance.isInstructor;

    _loadUserInfoAndDashboard();
  }

  /// Load dashboard data asynchronously without blocking UI
  Future<void> loadDashboardAsync() async {
    print('🚀 [DashboardController] loadDashboardAsync started');
    print('   - Current isInstructor value: ${isInstructor}');
    clearError();

    try {
      // Load semester data first (doesn't depend on role)
      await _loadSemesterData();

      // Then load dashboard data based on CURRENT role
      await _loadDashboardData();

      print('✅ [DashboardController] loadDashboardAsync completed');
      print('📊 [DashboardController] Final state:');
      print('   - isInstructor: $isInstructor');
      print('   - currentSemester: ${currentSemester.value != null}');
      print(
          '   - instructorDashboardData: ${instructorDashboardData.value != null}');
      print('   - studentDashboardData: ${studentDashboardData.value != null}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load dashboard', error: e);
      print('❌ [DashboardController] loadDashboardAsync error: $e');
      print('❌ [DashboardController] Stack trace: $stackTrace');
      if (currentSemester.value == null &&
          instructorDashboardData.value == null &&
          studentDashboardData.value == null) {
        errorMessage.value =
            'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
      }
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
      await _loadDashboardData();
    } catch (e) {
      AppLogger.error('Failed to load dashboard', error: e);
      errorMessage.value = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load dashboard data based on role
  Future<void> _loadDashboardData() async {
    print(
        '🔍 [DashboardController] Loading dashboard data, isInstructor: $isInstructor');

    // Wait a bit to ensure isInstructor is set
    if (!isInstructor) {
      print('⏳ [DashboardController] Waiting for isInstructor to be set...');
      await Future.delayed(const Duration(milliseconds: 100));
      print('🔍 [DashboardController] After wait, isInstructor: $isInstructor');
    }

    try {
      if (isInstructor) {
        print('👨‍🏫 [DashboardController] Loading INSTRUCTOR dashboard');
        await _loadInstructorDashboard();
      } else {
        print('👨‍🎓 [DashboardController] Loading STUDENT dashboard');
        await _loadStudentDashboard();
      }
      print('✅ [DashboardController] Dashboard data loaded successfully');
    } catch (e, stackTrace) {
      print('❌ [DashboardController] Error in _loadDashboardData: $e');
      print('❌ [DashboardController] Stack trace: $stackTrace');
      // Don't rethrow - let it be handled by caller
    }
  }

  /// Load semester data
  Future<void> _loadSemesterData() async {
    try {
      print('📅 [DashboardController] Loading semester data...');
      // Get current semester
      final current = await _dashboardRepository.getCurrentSemester();
      print(
          '✅ [DashboardController] Current semester loaded: ${current != null}');
      if (current != null) {
        print('   - Semester: ${current.name} (${current.id})');
      }
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
      print('🔍 [DashboardController] Loading instructor dashboard...');
      final data = await _dashboardRepository.getInstructorDashboard();
      print(
          '✅ [DashboardController] Instructor dashboard loaded: ${data != null}');
      if (data != null) {
        print(
            '📊 [DashboardController] Stats: courses=${data.statistics.totalCourses}, students=${data.statistics.totalStudents}');
      }
      instructorDashboardData.value = data;
      print('✅ [DashboardController] instructorDashboardData.value SET');
      print('   - Value after set: ${instructorDashboardData.value != null}');
      if (instructorDashboardData.value != null) {
        final stats = instructorDashboardData.value!.statistics;
        print(
            '   - Stats after set: courses=${stats.totalCourses}, students=${stats.totalStudents}');
      }

      // Force update to trigger Obx rebuild
      update();
      print('✅ [DashboardController] update() called to trigger UI rebuild');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load instructor dashboard', error: e);
      print('❌ [DashboardController] Error loading instructor dashboard: $e');
      print('❌ [DashboardController] Stack trace: $stackTrace');
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
      if (isInstructor) {
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

  /// Refresh dashboard data in background
  Future<void> refreshDashboard() async {
    if (isRefreshing.value) return;

    isRefreshing.value = true;

    try {
      await Future.wait([
        _loadSemesterData(),
        _loadDashboardData(),
      ], eagerError: false);
    } catch (e) {
      AppLogger.error('Failed to refresh dashboard', error: e);
    } finally {
      isRefreshing.value = false;
    }
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
