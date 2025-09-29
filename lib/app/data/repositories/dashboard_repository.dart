import 'package:classroom_mini/app/data/models/semester_model.dart';
import 'package:dio/dio.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';
import '../exceptions/api_exceptions.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  /// Get instructor dashboard data
  Future<InstructorDashboardData> getInstructorDashboard() async {
    try {
      final response = await _apiService.getInstructorDashboard();
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get student dashboard data
  Future<StudentDashboardData> getStudentDashboard() async {
    try {
      final response = await _apiService.getStudentDashboard();
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
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
