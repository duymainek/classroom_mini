import 'dart:convert';
import 'dart:io';
import 'package:classroom_mini/app/data/models/request/profile_request.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/attachment_response.dart'
    as attachment_resp;
import 'package:classroom_mini/app/data/models/request/assignment_request.dart';
import 'package:classroom_mini/app/data/models/response/attachment_response.dart';
import 'package:classroom_mini/app/data/models/response/auth_response.dart';
import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/data/models/request/material_request.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/logger.dart';
import 'package:classroom_mini/app/data/models/request/auth_request.dart';
import 'package:classroom_mini/app/data/models/request/course_request.dart';
import 'package:classroom_mini/app/data/models/request/group_request.dart';
import 'package:classroom_mini/app/data/models/request/semester_request.dart';
import 'package:classroom_mini/app/data/models/request/profile_request.dart'
    as profile_req;

import 'package:classroom_mini/app/data/models/response/auth_response.dart'
    as auth_response;
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:classroom_mini/app/data/models/response/profile_response.dart';
import 'package:classroom_mini/app/data/services/forum_api_service.dart';
import 'package:classroom_mini/app/data/network/interceptors/offline_interceptor.dart';
import 'package:classroom_mini/app/data/network/interceptors/cache_interceptor.dart';
import 'package:classroom_mini/app/data/local/cache_manager.dart';
import 'package:classroom_mini/app/data/local/sync_queue_manager.dart';
import 'storage_service.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: ApiEndpoints.baseUrl)
abstract class ApiService {
  factory ApiService(dio_pkg.Dio dio, {String baseUrl}) = _ApiService;

  // Authentication endpoints
  @POST(ApiEndpoints.instructorLogin)
  Future<auth_response.AuthResponse> instructorLogin(
      @Body() LoginRequest request);

  @POST(ApiEndpoints.studentLogin)
  Future<auth_response.AuthResponse> studentLogin(@Body() LoginRequest request);

  @POST(ApiEndpoints.createStudent)
  Future<auth_response.AuthResponse> createStudent(
      @Body() CreateStudentRequest request);

  @POST(ApiEndpoints.logout)
  Future<auth_response.LogoutResponse> logout();

  @POST(ApiEndpoints.refreshToken)
  Future<auth_response.AuthResponse> refreshToken(
      @Body() RefreshTokenRequest request);

  @GET(ApiEndpoints.currentUser)
  Future<UserSingleResponse> getCurrentUser();

  // Profile management
  @PUT(ApiEndpoints.updateProfile)
  Future<ProfileResponse> updateProfile(
      @Body() profile_req.UpdateProfileRequest profileData);

  // Enhanced Student Management endpoints
  @GET(ApiEndpoints.students)
  Future<StudentsListResponse> getStudents({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @PUT('/students/{studentId}')
  Future<StudentUpdateResponse> updateStudent(
    @Path('studentId') String studentId,
    @Body() UpdateStudentRequest updateData,
  );

  @DELETE('/students/{studentId}')
  Future<auth_response.SimpleResponse> deleteStudent(
      @Path('studentId') String studentId);

  @POST(ApiEndpoints.studentsBulk)
  Future<auth_response.BulkOperationResponse> bulkUpdateStudentsRequest(
    @Body() BulkOperationRequest bulkData,
  );

  @GET(ApiEndpoints.studentsStatistics)
  Future<auth_response.StatisticsResponse> getStudentStatistics();

  @POST('/students/{studentId}/reset-password')
  Future<auth_response.SimpleResponse> resetStudentPasswordRequest(
    @Path('studentId') String studentId,
    @Body() ResetPasswordRequest passwordData,
  );

  @GET(ApiEndpoints.studentsExport)
  Future<auth_response.SimpleResponse> exportStudents({
    @Query('format') String format = 'csv',
  });

  // Student import endpoints
  @POST(ApiEndpoints.studentsImportPreview)
  Future<auth_response.ImportPreviewResponse> importStudentsPreview(
      @Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.studentsImport)
  Future<auth_response.ImportResponse> importStudents(
      @Body() ImportStudentsRequest body);

  @POST(ApiEndpoints.studentsImport)
  Future<auth_response.ImportResponse> importStudentsWithAssignments(
      @Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.studentsImportTemplate)
  Future<String> getStudentsImportTemplate();

  // Semester Management endpoints
  @GET('/semesters')
  Future<SemesterListResponse> getSemesters({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  // Wrapped response variant for semesters to access root { success, data }
  @GET('/semesters')
  Future<SemesterListResponse> getSemestersWrapped({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @GET('/semesters/{semesterId}')
  Future<SemesterResponse> getSemesterById(
      @Path('semesterId') String semesterId);

  @POST('/semesters')
  Future<SemesterResponse> createSemester(
      @Body() SemesterCreateRequest request);

  @PUT('/semesters/{semesterId}')
  Future<SemesterResponse> updateSemester(
    @Path('semesterId') String semesterId,
    @Body() SemesterUpdateRequest request,
  );

  @DELETE('/semesters/{semesterId}')
  Future<auth_response.SimpleResponse> deleteSemester(
      @Path('semesterId') String semesterId);

  @GET('/semesters/statistics')
  Future<auth_response.StatisticsResponse> getSemesterStatistics();

  // Course Management endpoints
  @GET('/courses')
  Future<CourseListResponse> getCourses({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('semesterId') String semesterId = '',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @GET('/courses/semester/{semesterId}')
  Future<CourseListResponse> getCoursesBySemester(
    @Path('semesterId') String semesterId, {
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
  });

  @GET('/courses/{courseId}')
  Future<CourseResponse> getCourseById(@Path('courseId') String courseId);

  @POST('/courses')
  Future<CourseResponse> createCourse(@Body() CourseCreateRequest request);

  @PUT('/courses/{courseId}')
  Future<CourseResponse> updateCourse(
    @Path('courseId') String courseId,
    @Body() CourseUpdateRequest request,
  );

  @DELETE('/courses/{courseId}')
  Future<auth_response.SimpleResponse> deleteCourse(
      @Path('courseId') String courseId);

  @GET('/courses/statistics')
  Future<auth_response.StatisticsResponse> getCourseStatistics();

  // Group Management endpoints
  @GET('/groups')
  Future<GroupListResponse> getGroups({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('courseId') String courseId = '',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @GET('/groups/course/{courseId}')
  Future<GroupListResponse> getGroupsByCourse(
    @Path('courseId') String courseId, {
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
  });

  @GET('/groups/{groupId}')
  Future<GroupResponse> getGroupById(@Path('groupId') String groupId);

  @POST('/groups')
  Future<GroupResponse> createGroup(@Body() GroupCreateRequest request);

  @PUT('/groups/{groupId}')
  Future<GroupResponse> updateGroup(
    @Path('groupId') String groupId,
    @Body() GroupUpdateRequest request,
  );

  @DELETE('/groups/{groupId}')
  Future<auth_response.SimpleResponse> deleteGroup(
      @Path('groupId') String groupId);

  @GET('/groups/statistics')
  Future<auth_response.StatisticsResponse> getGroupStatistics();

  // Dashboard endpoints
  @GET('/dashboard/instructor')
  Future<InstructorDashboardResponse> getInstructorDashboard();

  @GET('/dashboard/student')
  Future<StudentDashboardResponse> getStudentDashboard();

  @GET('/dashboard/current-semester')
  Future<CurrentSemesterResponse> getCurrentSemester();

  @POST('/dashboard/switch-semester/{semesterId}')
  Future<SwitchSemesterResponse> switchSemester(
      @Path('semesterId') String semesterId);

  // Assignment Management endpoints
  @GET('/assignments')
  Future<AssignmentListResponse> getAssignments({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('courseId') String courseId = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
    @Query('semesterId') String? semesterId,
  });

  @GET('/assignments/{assignmentId}')
  Future<AssignmentResponse> getAssignmentById(
      @Path('assignmentId') String assignmentId);

  @POST('/assignments')
  Future<AssignmentResponse> createAssignment(
      @Body() AssignmentCreateRequest request);

  @PUT('/assignments/{assignmentId}')
  Future<AssignmentResponse> updateAssignment(
    @Path('assignmentId') String assignmentId,
    @Body() AssignmentUpdateRequest request,
  );

  @DELETE('/assignments/{assignmentId}')
  Future<auth_response.SimpleResponse> deleteAssignment(
      @Path('assignmentId') String assignmentId);

  @GET('/assignments/{assignmentId}/submissions')
  Future<SubmissionTrackingResponse> getAssignmentSubmissions(
    @Path('assignmentId') String assignmentId, {
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'submitted_at',
    @Query('sortOrder') String sortOrder = 'desc',
    @Query('groupId') String groupId = '',
    @Query('attemptFilter') String attemptFilter = 'all',
  });

  @PUT('/assignments/submissions/{submissionId}/grade')
  Future<SubmissionResponse> gradeSubmission(
    @Path('submissionId') String submissionId,
    @Body() GradeSubmissionRequest request,
  );

  @GET('/assignments/{assignmentId}/export')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> exportSubmissions(
    @Path('assignmentId') String assignmentId, {
    @Query('includeGrades') bool includeGrades = true,
    @Query('includeFeedback') bool includeFeedback = true,
    @Query('includeAttempts') bool includeAttempts = true,
    @Query('groupFilter') String groupFilter = '',
    @Query('statusFilter') String statusFilter = 'all',
  });

  @GET('/assignments/{assignmentId}/export/tracking')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> exportAssignmentTracking(
    @Path('assignmentId') String assignmentId, {
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('groupId') String groupId = '',
    @Query('sortBy') String sortBy = 'fullName',
    @Query('sortOrder') String sortOrder = 'asc',
  });

  @GET('/assignments/export/all')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> exportAllAssignments({
    @Query('courseId') String courseId = '',
    @Query('semesterId') String semesterId = '',
    @Query('includeSubmissions') bool includeSubmissions = true,
    @Query('includeGrades') bool includeGrades = true,
  });

  @GET('/assignments/{assignmentId}/attachments')
  Future<attachment_resp.AttachmentListResponse> getAssignmentAttachments(
    @Path('assignmentId') String assignmentId,
  );

  @DELETE('/assignments/attachments/{attachmentId}')
  Future<SimpleResponse> deleteAssignmentAttachment(
    @Path('attachmentId') String attachmentId,
  );

  // Student Assignment Submission endpoints
  @POST('/student/assignments/{assignmentId}/submit')
  Future<SubmissionResponse> submitAssignment(
    @Path('assignmentId') String assignmentId,
    @Body() SubmitAssignmentRequest request,
  );

  @GET('/student/assignments/{assignmentId}/submissions')
  Future<StudentSubmissionResponse> getStudentSubmissions(
      @Path('assignmentId') String assignmentId);

  @GET('/student/submissions')
  Future<SubmissionListResponse> getStudentAllSubmissions({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'submitted_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @PUT('/student/submissions/{submissionId}')
  Future<SubmissionResponse> updateSubmission(
    @Path('submissionId') String submissionId,
    @Body() UpdateSubmissionRequest request,
  );

  @DELETE('/student/submissions/{submissionId}')
  Future<auth_response.SimpleResponse> deleteSubmission(
      @Path('submissionId') String submissionId);

  @POST('/student/submissions/upload')
  @MultiPart()
  Future<attachment_resp.TempAttachmentResponse> uploadSubmissionTempFile(
    @Part(name: "file") File file,
  );

  @POST('/student/submissions/{submissionId}/finalize')
  Future<auth_response.SimpleResponse> finalizeSubmissionAttachments(
    @Path('submissionId') String submissionId,
    @Body() Map<String, dynamic> tempAttachmentIds,
  );

  @POST('/attachments/temp')
  @MultiPart()
  Future<attachment_resp.TempAttachmentResponse> uploadTempAttachment(
    @Part(name: "file") File file,
  );

  @POST('/announcements/temp-attachments')
  @MultiPart()
  Future<attachment_resp.TempAttachmentResponse>
      uploadTempAnnouncementAttachment(
    @Part(name: "file") File file,
  );

  // Assignment attachment management
  @POST('/assignments/{assignmentId}/attachments/finalize')
  Future<auth_response.SimpleResponse> finalizeAssignmentAttachments(
    @Path('assignmentId') String assignmentId,
    @Body() Map<String, dynamic> attachmentIds,
  );

  @GET('/assignments/{assignmentId}/attachments')
  Future<attachment_resp.AttachmentListResponse> getAssignmentAttachmentsById(
    @Path('assignmentId') String assignmentId,
  );

  @DELETE('/assignments/attachments/{attachmentId}')
  Future<auth_response.SimpleResponse> deleteAssignmentAttachmentById(
    @Path('attachmentId') String attachmentId,
  );

  // Announcement attachment management
  @POST('/announcements/{announcementId}/attachments/finalize')
  Future<auth_response.SimpleResponse> finalizeAnnouncementAttachments(
    @Path('announcementId') String announcementId,
    @Body() Map<String, dynamic> attachmentIds,
  );

  @GET('/announcements/{announcementId}/attachments')
  Future<attachment_resp.AttachmentListResponse> getAnnouncementAttachments(
    @Path('announcementId') String announcementId,
  );

  @DELETE('/announcements/attachments/{attachmentId}')
  Future<auth_response.SimpleResponse> deleteAnnouncementAttachment(
    @Path('attachmentId') String attachmentId,
  );

  // Material Management endpoints
  @POST('/materials')
  Future<MaterialResponse> createMaterial(
      @Body() CreateMaterialRequest request);

  @GET('/materials')
  Future<MaterialResponse> getMaterials({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('courseId') String? courseId,
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @GET('/materials/{materialId}')
  Future<MaterialResponse> getMaterialById(
      @Path('materialId') String materialId);

  @PUT('/materials/{materialId}')
  Future<MaterialResponse> updateMaterial(
    @Path('materialId') String materialId,
    @Body() UpdateMaterialRequest request,
  );

  @DELETE('/materials/{materialId}')
  Future<auth_response.SimpleResponse> deleteMaterial(
    @Path('materialId') String materialId,
  );

  // Material attachment management
  @POST('/materials/temp-attachments')
  @MultiPart()
  Future<attachment_resp.TempAttachmentResponse> uploadTempMaterialAttachment(
    @Part(name: "file") File file,
  );

  @POST('/materials/{materialId}/attachments/finalize')
  Future<auth_response.SimpleResponse> finalizeMaterialAttachments(
    @Path('materialId') String materialId,
    @Body() Map<String, dynamic> attachmentIds,
  );

  @GET('/materials/{materialId}/attachments')
  Future<attachment_resp.AttachmentListResponse> getMaterialAttachments(
    @Path('materialId') String materialId,
  );

  @DELETE('/materials/attachments/{attachmentId}')
  Future<auth_response.SimpleResponse> deleteMaterialAttachment(
    @Path('attachmentId') String attachmentId,
  );
}

class DioClient {
  static dio_pkg.Dio? _dio;
  static ApiService? _apiService;
  static bool _cacheInitialized = false;

  static Future<void> initCache() async {
    if (!_cacheInitialized) {
      await CacheManager.init();
      await SyncQueueManager.init();
      _cacheInitialized = true;
      debugPrint('✅ Cache and sync queue initialized');
    }
  }

  static dio_pkg.Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  static ApiService get apiService {
    _apiService ??= ApiService(dio);
    return _apiService!;
  }

  static dio_pkg.Dio _createDio() {
    final dio = dio_pkg.Dio();

    // Configure base options
    dio.options.baseUrl = ApiEndpoints.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    // Add interceptors (ORDER MATTERS!)
    dio.interceptors.addAll([
      _AuthInterceptor(),
      OfflineInterceptor(),
      CacheInterceptor(),
      PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true),
      _ErrorInterceptor(),
    ]);

    return dio;
  }

  static void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
  }

  static dio_pkg.Dio createCleanInstance() {
    final cleanDio = dio_pkg.Dio();
    cleanDio.options.baseUrl = dio.options.baseUrl;
    cleanDio.options.connectTimeout = dio.options.connectTimeout;
    cleanDio.options.receiveTimeout = dio.options.receiveTimeout;
    cleanDio.options.sendTimeout = dio.options.sendTimeout;
    return cleanDio;
  }

  static Future<void> clearCache(String path,
      [Map<String, dynamic>? queryParams]) async {
    await CacheManager.clear(path, queryParams);
  }

  static Future<void> clearAllCache() async {
    await CacheManager.clearAll();
  }

  static Future<void> clearCacheByPattern(String pattern) async {
    await CacheManager.clearByPathPattern(pattern);
  }

  static Map<String, dynamic> getCacheStats() {
    return CacheManager.getStats();
  }

  static Future<attachment_resp.TempAttachmentResponse>
      uploadSubmissionTempFileFromBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final formData = dio_pkg.FormData.fromMap({
      'file': dio_pkg.MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });

    final response = await dio.post(
      '/student/submissions/upload',
      data: formData,
    );

    return attachment_resp.TempAttachmentResponse.fromJson(response.data);
  }

  static Future<AvatarUploadResponse> uploadAvatarFromBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final formData = dio_pkg.FormData.fromMap({
      'avatar': dio_pkg.MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });

    final response = await dio.post(
      '/profile/avatar',
      data: formData,
    );

    return AvatarUploadResponse.fromJson(response.data);
  }
}

// Auth interceptor to add JWT token to requests
class _AuthInterceptor extends dio_pkg.Interceptor {
  static bool _isRefreshing = false;
  static final List<Function> _requestsQueue = [];

  // Helper method to check if token is expired
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      // Add padding if needed
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      // Consider token expired if it expires within 30 seconds
      return expDate.isBefore(now.add(const Duration(seconds: 30)));
    } catch (e) {
      AppLogger.error('Error checking token expiry', error: e);
      return true;
    }
  }

  @override
  void onRequest(dio_pkg.RequestOptions options,
      dio_pkg.RequestInterceptorHandler handler) async {
    // Skip auth for login endpoints
    if (options.path.contains('/login') || options.path.contains('/refresh')) {
      handler.next(options);
      return;
    }

    // Add authorization header if token exists
    try {
      final storageService = await StorageService.getInstance();
      String? token = await storageService.getAccessToken();

      if (token != null) {
        // Check if token is expired or about to expire
        if (_isTokenExpired(token) && !_isRefreshing) {
          AppLogger.info('Token is expired/expiring, attempting refresh...');

          _isRefreshing = true;
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Get the new token
              token = await storageService.getAccessToken();
              AppLogger.info('Token refreshed proactively');
            } else {
              AppLogger.warning('Proactive token refresh failed');
            }
          } catch (e) {
            AppLogger.error('Error during proactive token refresh', error: e);
          } finally {
            _isRefreshing = false;
          }
        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      // Continue without token if storage fails
      AppLogger.error('Error getting token', error: e);
    }

    handler.next(options);
  }

  @override
  void onError(
      dio_pkg.DioException err, dio_pkg.ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Handle token refresh on 401 (excluding refresh endpoint itself)
    if (err.response?.statusCode == 401 &&
        !requestOptions.path.contains('/refresh')) {
      // If already refreshing, queue this request
      if (_isRefreshing) {
        _requestsQueue.add(() async {
          try {
            // Wait a bit for refresh to complete
            int attempts = 0;
            while (_isRefreshing && attempts < 10) {
              await Future.delayed(const Duration(milliseconds: 100));
              attempts++;
            }

            final storageService = await StorageService.getInstance();
            final newToken = await storageService.getAccessToken();

            if (newToken != null) {
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              final response = await DioClient.dio.request(
                requestOptions.path,
                options: dio_pkg.Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } else {
              return handler.next(err);
            }
          } catch (e) {
            AppLogger.error('Error retrying queued request', error: e);
            return handler.next(err);
          }
        });
        return;
      }

      try {
        _isRefreshing = true;
        final refreshed = await _refreshToken();

        if (refreshed) {
          // Update the failed request with new token
          final storageService = await StorageService.getInstance();
          final newToken = await storageService.getAccessToken();

          if (newToken != null) {
            requestOptions.headers['Authorization'] = 'Bearer $newToken';

            // Retry the original request
            final response = await DioClient.dio.request(
              requestOptions.path,
              options: dio_pkg.Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );

            // Process queued requests
            _processQueue().catchError((e) {
              AppLogger.error('Error processing request queue', error: e);
            });

            handler.resolve(response);
            return;
          }
        }

        // Refresh failed, clear tokens and redirect to login
        await _handleRefreshFailure();
      } catch (e) {
        AppLogger.error('Error during token refresh', error: e);
        await _handleRefreshFailure();
      } finally {
        _isRefreshing = false;
        _requestsQueue.clear();
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final storageService = await StorageService.getInstance();
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken == null) {
        AppLogger.warning('No refresh token available');
        return false;
      }

      AppLogger.info('Attempting to refresh token...');

      // Create a new Dio instance to avoid interceptor loops
      // Sử dụng DioClient để tạo instance sạch (không có interceptors)
      final refreshDio = DioClient.createCleanInstance();

      // Add logging for refresh request
      refreshDio.interceptors.add(dio_pkg.LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (obj) => AppLogger.debug('Refresh: $obj'),
      ));

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      AppLogger.debug('Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        AppLogger.debug('Response data: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final tokens = responseData['data']['tokens'];

          if (tokens['accessToken'] != null && tokens['refreshToken'] != null) {
            await storageService.saveTokens(
              tokens['accessToken'],
              tokens['refreshToken'],
            );

            AppLogger.info('Token refreshed successfully');
            return true;
          } else {
            AppLogger.error('Token refresh failed: Missing tokens in response');
            return false;
          }
        } else {
          AppLogger.error(
              'Token refresh failed: ${responseData['message'] ?? 'Unknown error'}');
          return false;
        }
      }

      AppLogger.error('Token refresh failed: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      AppLogger.error('Token refresh error', error: e);
      if (e is dio_pkg.DioException) {
        AppLogger.error('Dio error details: ${e.response?.data}');
        AppLogger.error('Dio error status: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  Future<void> _processQueue() async {
    while (_requestsQueue.isNotEmpty) {
      final queue = List<Function>.from(_requestsQueue);
      _requestsQueue.clear();

      for (final request in queue) {
        try {
          await request();
        } catch (e) {
          AppLogger.error('Error processing queued request', error: e);
        }
      }
    }
  }

  Future<void> _handleRefreshFailure() async {
    try {
      final storageService = await StorageService.getInstance();
      await storageService.clearAll();
      AppLogger.info('Tokens cleared due to refresh failure');

      // Here you could also navigate to login page
      // Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      AppLogger.error('Error clearing tokens', error: e);
    }
  }
}

// Error handling interceptor
class _ErrorInterceptor extends dio_pkg.Interceptor {
  @override
  void onError(
      dio_pkg.DioException err, dio_pkg.ErrorInterceptorHandler handler) {
    String message;

    switch (err.type) {
      case dio_pkg.DioExceptionType.connectionTimeout:
      case dio_pkg.DioExceptionType.sendTimeout:
      case dio_pkg.DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case dio_pkg.DioExceptionType.badResponse:
        message = _handleHttpError(err.response?.statusCode);
        break;
      case dio_pkg.DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      default:
        message = 'Network error occurred. Please try again.';
    }

    handler.next(dio_pkg.DioException(
      requestOptions: err.requestOptions,
      message: message,
      type: err.type,
      response: err.response,
    ));
  }

  String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. Resource already exists.';
      case 500:
        return 'Internal server error. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Service wrapper that contains all API services
class ApiServiceWrapper {
  late final ApiService _apiService;
  late final ForumApiService forumApiService;

  ApiServiceWrapper(Dio dio) {
    _apiService = ApiService(dio);
    forumApiService = ForumApiService(dio);
  }

  ApiService get apiService => _apiService;
}
