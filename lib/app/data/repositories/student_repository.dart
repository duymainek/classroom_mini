import 'dart:typed_data';
import 'package:classroom_mini/app/data/models/request/auth_request.dart';
import 'package:classroom_mini/app/data/models/response/auth_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../services/storage_service.dart';

class StudentResult {
  final bool success;
  final String? message;
  final UserModel? student;
  final List<String>? errors;

  StudentResult({
    required this.success,
    this.message,
    this.student,
    this.errors,
  });

  factory StudentResult.success({
    UserModel? student,
    String? message,
  }) {
    return StudentResult(
      success: true,
      student: student,
      message: message,
    );
  }

  factory StudentResult.failure({
    String? message,
    List<String>? errors,
  }) {
    return StudentResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

class StudentsListResult {
  final bool success;
  final String? message;
  final List<UserModel>? students;
  final PaginationInfo? pagination;
  final List<String>? errors;
  // Nested relation objects aligned by students order
  final List<Map<String, dynamic>?>? groups;
  final List<Map<String, dynamic>?>? courses;

  StudentsListResult({
    required this.success,
    this.message,
    this.students,
    this.pagination,
    this.errors,
    this.groups,
    this.courses,
  });

  factory StudentsListResult.success({
    List<UserModel>? students,
    PaginationInfo? pagination,
    String? message,
    List<Map<String, dynamic>?>? groups,
    List<Map<String, dynamic>?>? courses,
  }) {
    return StudentsListResult(
      success: true,
      students: students,
      pagination: pagination,
      message: message,
      groups: groups,
      courses: courses,
    );
  }

  factory StudentsListResult.failure({
    String? message,
    List<String>? errors,
  }) {
    return StudentsListResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

class StatisticsResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final List<String>? errors;

  StatisticsResult({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory StatisticsResult.success({
    Map<String, dynamic>? data,
    String? message,
  }) {
    return StatisticsResult(
      success: true,
      data: data,
      message: message,
    );
  }

  factory StatisticsResult.failure({
    String? message,
    List<String>? errors,
  }) {
    return StatisticsResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

class StudentRepository {
  final ApiService _apiService;

  StudentRepository({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService;

  // Create student account (instructor only)
  Future<StudentResult> createStudent({
    required String username,
    required String password,
    required String email,
    required String fullName,
    String? groupId,
    String? courseId,
  }) async {
    try {
      final request = CreateStudentRequest(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
        groupId: groupId,
        courseId: courseId,
      );

      final response = await _apiService.createStudent(request);

      if (response.success && response.data != null) {
        return StudentResult.success(
          student: response.data!.user,
          message: 'Student account created successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to create student account',
          errors: response.errors,
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Get students with pagination, search, and filters
  Future<StudentsListResult> getStudents({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await _apiService.getStudents(
        page: page,
        limit: limit,
        search: search,
        status: status,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      // Group and course objects are now parsed directly in UserModel
      // No need for additional extraction since UserModel.fromJson handles them

      if (response.success) {
        return StudentsListResult.success(
          students: response.data.students,
          pagination: response.data.pagination,
          message: 'Students loaded successfully',
        );
      } else {
        return StudentsListResult.failure(
          message: response.message ?? 'Failed to load students',
        );
      }
    } catch (e) {
      print('StudentRepository.getStudents error: $e');
      return StudentsListResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Update student
  Future<StudentResult> updateStudent(
      String studentId, UpdateStudentRequest updateData) async {
    try {
      final response = await _apiService.updateStudent(studentId, updateData);

      if (response.success && response.student != null) {
        return StudentResult.success(
          student: response.student!,
          message: response.message ?? 'Student updated successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to update student',
          errors: response.errors,
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Delete student
  Future<StudentResult> deleteStudent(String studentId) async {
    try {
      final response = await _apiService.deleteStudent(studentId);

      if (response.success) {
        return StudentResult.success(
          message: response.message ?? 'Student deleted successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to delete student',
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Bulk update students
  Future<StudentResult> bulkUpdateStudents(
      List<String> studentIds, String action) async {
    try {
      final request = BulkOperationRequest(
        studentIds: studentIds,
        action: action,
      );
      final response = await _apiService.bulkUpdateStudentsRequest(request);

      if (response.success) {
        return StudentResult.success(
          message: response.message ?? 'Bulk operation completed successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to perform bulk operation',
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Get student statistics
  Future<StatisticsResult> getStudentStatistics() async {
    try {
      final response = await _apiService.getStudentStatistics();

      if (response.success && response.data != null) {
        return StatisticsResult.success(
          data: response.data!,
          message: 'Statistics loaded successfully',
        );
      } else {
        return StatisticsResult.failure(
          message: response.message ?? 'Failed to load statistics',
        );
      }
    } catch (e) {
      print('StudentRepository.getStudentStatistics error: $e');
      return StatisticsResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Reset student password
  Future<StudentResult> resetStudentPassword(
      String studentId, String newPassword) async {
    try {
      final request = ResetPasswordRequest(newPassword: newPassword);
      final response =
          await _apiService.resetStudentPasswordRequest(studentId, request);

      if (response.success) {
        return StudentResult.success(
          message: response.message ?? 'Password reset successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Export students
  Future<StudentResult> exportStudents({String format = 'csv'}) async {
    try {
      final response = await _apiService.exportStudents(format: format);

      if (response.success) {
        return StudentResult.success(
          message: response.message ?? 'Students exported successfully',
        );
      } else {
        return StudentResult.failure(
          message: response.message ?? 'Failed to export students',
        );
      }
    } catch (e) {
      return StudentResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Download CSV bytes directly (bypass JSON retrofit)
  Future<(Uint8List? bytes, String filename)> downloadStudentsCsv(
      {String format = 'csv'}) async {
    try {
      final dio = DioClient.dio;
      final response = await dio.get(
        ApiEndpoints.studentsExport,
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      final headers = response.headers.map;
      String filename = 'students.$format';
      final cd = headers['content-disposition']?.first;
      if (cd != null) {
        final match = RegExp(r'filename="?([^";]+)"?').firstMatch(cd);
        if (match != null) {
          filename = match.group(1) ?? filename;
        }
      }
      final data = response.data;
      if (data is Uint8List) {
        return (data, filename);
      } else if (data is List<int>) {
        return (Uint8List.fromList(data), filename);
      }
      return (null, filename);
    } catch (e) {
      return (null, 'students.$format');
    }
  }

  // Import preview
  Future<StatisticsResult> importStudentsPreview(
      List<Map<String, dynamic>> rows) async {
    try {
      final response =
          await _apiService.importStudentsPreview({'records': rows});

      if (response.success) {
        return StatisticsResult.success(
          data: response.summary,
          message: response.message ?? 'Preview generated',
        );
      } else {
        return StatisticsResult.failure(
          message: response.message ?? 'Failed to preview import',
          errors: response.errors,
        );
      }
    } catch (e) {
      return StatisticsResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Import preview (raw response: includes results per row)
  Future<ImportPreviewResponse> importStudentsPreviewRaw(
      List<Map<String, dynamic>> rows) async {
    try {
      final response =
          await _apiService.importStudentsPreview({'records': rows});
      return response;
    } catch (e) {
      return ImportPreviewResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Import students
  Future<StatisticsResult> importStudents(List<Map<String, dynamic>> rows,
      {String? idempotencyKey}) async {
    try {
      final request = ImportStudentsRequest(
        records: rows,
        idempotencyKey: idempotencyKey,
      );
      final response = await _apiService.importStudents(request);

      if (response.success) {
        return StatisticsResult.success(
          data: response.summary,
          message: response.message ?? 'Import completed',
        );
      } else {
        return StatisticsResult.failure(
          message: response.message ?? 'Failed to import students',
          errors: response.errors,
        );
      }
    } catch (e) {
      return StatisticsResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Import students (raw response: includes results per row)
  Future<ImportResponse> importStudentsRaw(List<Map<String, dynamic>> rows,
      [Map<String, dynamic>? assignmentData, String? idempotencyKey]) async {
    try {
      // Create request body with assignment data
      final requestBody = {
        'records': rows,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };

      // Add assignment data to request body
      if (assignmentData != null) {
        requestBody.addAll(assignmentData.cast<String, Object>());
      }

      final response =
          await _apiService.importStudentsWithAssignments(requestBody);
      return response;
    } catch (e) {
      return ImportResponse(
        success: false,
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Get CSV template
  Future<String?> getStudentsImportTemplate() async {
    try {
      final content = await _apiService.getStudentsImportTemplate();
      return content;
    } catch (e) {
      return null;
    }
  }
}
