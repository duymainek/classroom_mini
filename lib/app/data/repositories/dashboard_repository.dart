import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../exceptions/api_exceptions.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  /// Get instructor dashboard data
  Future<InstructorDashboardData> getInstructorDashboard() async {
    try {
      debugPrint('🔍 [DashboardRepository] Calling getInstructorDashboard...');
      final response = await _apiService.getInstructorDashboard();
      debugPrint('✅ [DashboardRepository] Response received');
      debugPrint('📊 [DashboardRepository] Response data: ${response.data != null}');
      
      if (response.data == null) {
        throw Exception('Response data is null');
      }
      
      final data = response.data;
      debugPrint('📊 [DashboardRepository] Data stats: courses=${data.statistics.totalCourses}, students=${data.statistics.totalStudents}');
      debugPrint('✅ [DashboardRepository] Returning data');
      return data;
    } on DioException catch (e) {
      debugPrint('❌ [DashboardRepository] DioException: ${e.message}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      debugPrint('❌ [DashboardRepository] Error: $e');
      debugPrint('❌ [DashboardRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get student dashboard data
  Future<StudentDashboardData> getStudentDashboard() async {
    try {
      debugPrint('🔍 [DashboardRepository] Calling getStudentDashboard...');
      final response = await _apiService.getStudentDashboard();
      debugPrint('✅ [DashboardRepository] Student response received');
      debugPrint('📊 [DashboardRepository] Student response data: ${response.data != null}');
      
      if (response.data == null) {
        throw Exception('Response data is null');
      }
      
      final data = response.data;
      debugPrint('📊 [DashboardRepository] Student enrolled courses: ${data.enrolledCourses.length}');
      debugPrint('📊 [DashboardRepository] Student studyProgress: ${data.studyProgress != null}');
      if (data.studyProgress != null) {
        debugPrint('   - Assignments: ${data.studyProgress!.assignments.completed}/${data.studyProgress!.assignments.total}');
        debugPrint('   - Quizzes: ${data.studyProgress!.quizzes.completed}/${data.studyProgress!.quizzes.total}');
      } else {
        debugPrint('   ⚠️ studyProgress is NULL - may be cached old data');
      }
      debugPrint('✅ [DashboardRepository] Returning student data');
      return data;
    } on DioException catch (e) {
      debugPrint('❌ [DashboardRepository] DioException: ${e.message}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      debugPrint('❌ [DashboardRepository] Error: $e');
      debugPrint('❌ [DashboardRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get current semester
  Future<Semester?> getCurrentSemester() async {
    try {
      final response = await _apiService.getCurrentSemester();
      return response.data?.currentSemester;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Switch semester context
  Future<Semester> switchSemester(String semesterId) async {
    try {
      final response = await _apiService.switchSemester(semesterId);
      if (response.data?.semester == null) {
        throw Exception('No semester data received');
      }
      return response.data!.semester;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      final message = data['message'] ?? 'An error occurred';
      final code = data['code'] ?? 'UNKNOWN_ERROR';

      switch (e.response!.statusCode) {
        case 400:
          return ValidationException(message, code);
        case 404:
          return NotFoundException(message, code);
        case 409:
          return ConflictException(message, code);
        case 401:
          return UnauthorizedException(message, code);
        case 403:
          return ForbiddenException(message, code);
        default:
          return ServerException(message, code);
      }
    } else {
      return NetworkException('Network error: ${e.message}');
    }
  }
}
