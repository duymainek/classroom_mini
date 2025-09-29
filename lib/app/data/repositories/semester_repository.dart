import 'package:dio/dio.dart';
import '../models/semester_model.dart';
import '../services/api_service.dart' show ApiService;
import '../exceptions/api_exceptions.dart';
// removed unused DioClient import

class SemesterRepository {
  final ApiService _apiService;

  SemesterRepository(this._apiService);

  /// Get all semesters with pagination and search
  Future<SemesterListResponse> getSemesters({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final wrapped = await _apiService.getSemestersWrapped(
        page: page,
        limit: limit,
        search: search,
        status: status,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      return wrapped;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get semester by ID
  Future<Semester> getSemesterById(String semesterId) async {
    try {
      final response = await _apiService.getSemesterById(semesterId);
      return response.data.semester;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new semester
  Future<Semester> createSemester(SemesterCreateRequest request) async {
    try {
      final response = await _apiService.createSemester(request);
      return response.data.semester;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update semester
  Future<Semester> updateSemester(
      String semesterId, SemesterUpdateRequest request) async {
    try {
      final response = await _apiService.updateSemester(semesterId, request);
      return response.data.semester;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete semester
  Future<void> deleteSemester(String semesterId) async {
    try {
      await _apiService.deleteSemester(semesterId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get semester statistics
  Future<Map<String, dynamic>> getSemesterStatistics() async {
    try {
      final response = await _apiService.getSemesterStatistics();
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
