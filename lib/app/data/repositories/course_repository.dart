import 'package:dio/dio.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../exceptions/api_exceptions.dart';

class CourseRepository {
  final ApiService _apiService;

  CourseRepository(this._apiService);

  /// Get all courses with pagination and search
  Future<CourseListResponse> getCourses({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String semesterId = '',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      return await _apiService.getCourses(
        page: page,
        limit: limit,
        search: search,
        status: status,
        semesterId: semesterId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get courses by semester
  Future<CourseListResponse> getCoursesBySemester(
    String semesterId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
  }) async {
    try {
      return await _apiService.getCoursesBySemester(
        semesterId,
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get course by ID
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await _apiService.getCourseById(courseId);
      return response.course;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new course
  Future<Course> createCourse(CourseCreateRequest request) async {
    try {
      final response = await _apiService.createCourse(request);
      return response.course;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update course
  Future<Course> updateCourse(
      String courseId, CourseUpdateRequest request) async {
    try {
      final response = await _apiService.updateCourse(courseId, request);
      return response.course;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _apiService.deleteCourse(courseId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get course statistics
  Future<Map<String, dynamic>> getCourseStatistics() async {
    try {
      final response = await _apiService.getCourseStatistics();
      return response.data ?? {};
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
