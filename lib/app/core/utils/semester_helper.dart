import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../app_config.dart';
import '../../data/repositories/semester_repository.dart';
import '../../data/services/api_service.dart';
import '../utils/logger.dart';

/// Helper class để làm việc với thông tin học kì
/// Cung cấp các utility methods để kiểm tra và lấy thông tin học kì
class SemesterHelper {
  static AppConfig get _appConfig => AppConfig.instance;
  static SemesterRepository? _semesterRepository;

  /// Khởi tạo SemesterRepository
  static void _initializeRepository() {
    if (_semesterRepository == null) {
      try {
        final apiService = Get.find<ApiService>();
        _semesterRepository = SemesterRepository(apiService);
      } catch (e) {
        AppLogger.error('Failed to initialize SemesterRepository', error: e);
      }
    }
  }

  /// Tự động load và chọn học kì mới nhất
  /// @returns {Future<bool>} true nếu thành công, false nếu thất bại
  static Future<bool> autoSelectLatestSemester() async {
    try {
      _initializeRepository();
      if (_semesterRepository == null) return false;

      // Lấy danh sách học kì, sắp xếp theo thời gian tạo mới nhất
      final response = await _semesterRepository!.getSemesters(
        page: 1,
        limit: 10,
        status: 'all',
        sortBy: 'created_at',
        sortOrder: 'desc',
      );

      if (response.data.semesters.isNotEmpty) {
        final latestSemester = response.data.semesters.first;

        // Cập nhật AppConfig với học kì mới nhất
        _appConfig.setSelectedSemester(
          semesterId: latestSemester.id,
          semesterName: latestSemester.name,
          semesterCode: latestSemester.code,
        );

        AppLogger.info('Auto-selected latest semester: ${latestSemester.name}');
        return true;
      }
    } catch (e) {
      AppLogger.error('Failed to auto-select latest semester', error: e);
    }
    return false;
  }

  /// Load danh sách học kì từ API
  /// @returns {Future<List<Semester>>} Danh sách học kì
  static Future<List<Semester>> loadSemestersFromAPI() async {
    try {
      _initializeRepository();
      if (_semesterRepository == null) return [];

      final response = await _semesterRepository!.getSemesters(
        page: 1,
        limit: 100,
        status: 'all',
        sortBy: 'created_at',
        sortOrder: 'desc',
      );

      return response.data.semesters;
    } catch (e) {
      AppLogger.error('Failed to load semesters from API', error: e);
      return [];
    }
  }

  /// Kiểm tra xem có học kì nào được chọn không
  /// @returns {bool} true nếu có học kì được chọn
  static bool hasSelectedSemester() {
    return _appConfig.hasSelectedSemester();
  }

  /// Lấy ID của học kì hiện tại
  /// @returns {String} ID của học kì hoặc chuỗi rỗng nếu chưa chọn
  static String getCurrentSemesterId() {
    return _appConfig.selectedSemesterId;
  }

  /// Lấy tên của học kì hiện tại
  /// @returns {String} Tên học kì hoặc chuỗi rỗng nếu chưa chọn
  static String getCurrentSemesterName() {
    return _appConfig.selectedSemesterName;
  }

  /// Lấy mã của học kì hiện tại
  /// @returns {String} Mã học kì hoặc chuỗi rỗng nếu chưa chọn
  static String getCurrentSemesterCode() {
    return _appConfig.selectedSemesterCode;
  }

  /// Lấy thông tin đầy đủ của học kì hiện tại
  /// @returns {Map<String, String>} Map chứa id, name, code của học kì
  static Map<String, String> getCurrentSemesterInfo() {
    return _appConfig.getCurrentSemesterInfo();
  }

  /// Kiểm tra và hiển thị thông báo nếu chưa chọn học kì
  /// @returns {bool} true nếu đã chọn học kì, false nếu chưa chọn
  static bool checkSemesterSelected() {
    if (!hasSelectedSemester()) {
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng chọn học kì trước khi thực hiện thao tác này',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Chuyển đổi danh sách Semester thành SemesterOption
  /// @param {List<Semester>} semesters - Danh sách Semester từ API
  /// @returns {List<SemesterOption>} Danh sách SemesterOption
  static List<SemesterOption> convertToSemesterOptions(
      List<Semester> semesters) {
    return semesters
        .map((semester) => SemesterOption(
              id: semester.id,
              name: semester.name,
              code: semester.code,
            ))
        .toList();
  }

  /// Tìm học kì theo ID trong danh sách
  /// @param {String} semesterId - ID của học kì
  /// @param {List<Semester>} semesters - Danh sách học kì
  /// @returns {Semester?} Học kì tìm được hoặc null
  static Semester? findSemesterById(
      String semesterId, List<Semester> semesters) {
    try {
      return semesters.firstWhere((s) => s.id == semesterId);
    } catch (e) {
      return null;
    }
  }

  // Note: Reactive streams are now handled by DashboardController
  // Use DashboardController.currentSemester for reactive UI updates
}

/// Model cho option học kì (được sử dụng trong SemesterSelector)
class SemesterOption {
  final String id;
  final String name;
  final String code;

  const SemesterOption({
    required this.id,
    required this.name,
    required this.code,
  });
}
