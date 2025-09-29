import 'package:dio/dio.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../exceptions/api_exceptions.dart';

class GroupRepository {
  final ApiService _apiService;

  GroupRepository(this._apiService);

  /// Get all groups with pagination and search
  Future<GroupListResponse> getGroups({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String courseId = '',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      return await _apiService.getGroups(
        page: page,
        limit: limit,
        search: search,
        status: status,
        courseId: courseId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get groups by course
  Future<GroupListResponse> getGroupsByCourse(
    String courseId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
  }) async {
    try {
      return await _apiService.getGroupsByCourse(
        courseId,
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group by ID
  Future<Group> getGroupById(String groupId) async {
    try {
      final response = await _apiService.getGroupById(groupId);
      return response.group;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new group
  Future<Group> createGroup(GroupCreateRequest request) async {
    try {
      final response = await _apiService.createGroup(request);
      return response.group;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update group
  Future<Group> updateGroup(String groupId, GroupUpdateRequest request) async {
    try {
      final response = await _apiService.updateGroup(groupId, request);
      return response.group;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _apiService.deleteGroup(groupId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group statistics
  Future<Map<String, dynamic>> getGroupStatistics() async {
    try {
      final response = await _apiService.getGroupStatistics();
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
