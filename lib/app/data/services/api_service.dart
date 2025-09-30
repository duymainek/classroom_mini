import 'dart:convert';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/request/assignment_request.dart';
import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/logger.dart';
import 'package:classroom_mini/app/data/models/request/auth_request.dart';
import 'package:classroom_mini/app/data/models/request/course_request.dart';
import 'package:classroom_mini/app/data/models/request/group_request.dart';
import 'package:classroom_mini/app/data/models/request/semester_request.dart';
import 'package:classroom_mini/app/data/models/request/profile_request.dart'
    as profile_req;

import 'package:classroom_mini/app/data/models/response/auth_response.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:classroom_mini/app/data/models/response/profile_response.dart';
import 'storage_service.dart';

import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
part 'api_service.g.dart';

@RestApi(baseUrl: ApiEndpoints.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Authentication endpoints
  @POST(ApiEndpoints.instructorLogin)
  Future<AuthResponse> instructorLogin(@Body() LoginRequest request);

  @POST(ApiEndpoints.studentLogin)
  Future<AuthResponse> studentLogin(@Body() LoginRequest request);

  @POST(ApiEndpoints.createStudent)
  Future<AuthResponse> createStudent(@Body() CreateStudentRequest request);

  @POST(ApiEndpoints.logout)
  Future<LogoutResponse> logout();

  @POST(ApiEndpoints.refreshToken)
  Future<AuthResponse> refreshToken(@Body() RefreshTokenRequest request);

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
  Future<SimpleResponse> deleteStudent(@Path('studentId') String studentId);

  @POST(ApiEndpoints.studentsBulk)
  Future<BulkOperationResponse> bulkUpdateStudentsRequest(
    @Body() BulkOperationRequest bulkData,
  );

  @GET(ApiEndpoints.studentsStatistics)
  Future<StatisticsResponse> getStudentStatistics();

  @POST('/students/{studentId}/reset-password')
  Future<SimpleResponse> resetStudentPasswordRequest(
    @Path('studentId') String studentId,
    @Body() ResetPasswordRequest passwordData,
  );

  @GET(ApiEndpoints.studentsExport)
  Future<SimpleResponse> exportStudents({
    @Query('format') String format = 'csv',
  });

  // Student import endpoints
  @POST(ApiEndpoints.studentsImportPreview)
  Future<ImportPreviewResponse> importStudentsPreview(
      @Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.studentsImport)
  Future<ImportResponse> importStudents(@Body() ImportStudentsRequest body);

  @POST(ApiEndpoints.studentsImport)
  Future<ImportResponse> importStudentsWithAssignments(
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
  Future<SimpleResponse> deleteSemester(@Path('semesterId') String semesterId);

  @GET('/semesters/statistics')
  Future<StatisticsResponse> getSemesterStatistics();

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
  Future<SimpleResponse> deleteCourse(@Path('courseId') String courseId);

  @GET('/courses/statistics')
  Future<StatisticsResponse> getCourseStatistics();

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
  Future<SimpleResponse> deleteGroup(@Path('groupId') String groupId);

  @GET('/groups/statistics')
  Future<StatisticsResponse> getGroupStatistics();

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
  Future<SimpleResponse> deleteAssignment(
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
  });

  @PUT('/assignments/submissions/{submissionId}/grade')
  Future<SubmissionResponse> gradeSubmission(
    @Path('submissionId') String submissionId,
    @Body() GradeSubmissionRequest request,
  );

  @GET('/assignments/{assignmentId}/export')
  Future<List<int>> exportSubmissions(
      @Path('assignmentId') String assignmentId);

  // Assignment Submission endpoints
  @POST('/submissions/assignments/{assignmentId}')
  Future<SubmissionResponse> submitAssignment(
    @Path('assignmentId') String assignmentId,
    @Body() SubmitAssignmentRequest request,
  );

  @GET('/submissions/assignments/{assignmentId}')
  Future<StudentSubmissionResponse> getStudentSubmissions(
      @Path('assignmentId') String assignmentId);

  @GET('/submissions')
  Future<SubmissionListResponse> getStudentAllSubmissions({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'submitted_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @PUT('/submissions/{submissionId}')
  Future<SubmissionResponse> updateSubmission(
    @Path('submissionId') String submissionId,
    @Body() UpdateSubmissionRequest request,
  );

  @DELETE('/submissions/{submissionId}')
  Future<SimpleResponse> deleteSubmission(
      @Path('submissionId') String submissionId);

  @POST('/submissions/{submissionId}/attachments')
  Future<AttachmentResponse> uploadAttachment(
    @Path('submissionId') String submissionId,
    @Body() FileUploadRequest request,
  );

  @DELETE('/submissions/attachments/{attachmentId}')
  Future<SimpleResponse> deleteAttachment(
      @Path('attachmentId') String attachmentId);
}

class DioClient {
  static Dio? _dio;
  static ApiService? _apiService;

  static Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  static ApiService get apiService {
    _apiService ??= ApiService(dio);
    return _apiService!;
  }

  static Dio _createDio() {
    final dio = Dio();

    // Configure base options
    dio.options.baseUrl = ApiEndpoints.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    // Add interceptors
    dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
      AwesomeDioInterceptor(
        logRequestHeaders: false,
        logRequestTimeout: false,
        logResponseHeaders: false,
      ),
    ]);

    return dio;
  }

  static void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
  }
}

// Auth interceptor to add JWT token to requests
class _AuthInterceptor extends Interceptor {
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
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Handle token refresh on 401 (excluding refresh endpoint itself)
    if (err.response?.statusCode == 401 &&
        !requestOptions.path.contains('/refresh')) {
      // If already refreshing, queue this request
      if (_isRefreshing) {
        _requestsQueue.add(() async {
          try {
            final storageService = await StorageService.getInstance();
            final newToken = await storageService.getAccessToken();

            if (newToken != null) {
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              final response = await DioClient.dio.request(
                requestOptions.path,
                options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
              );
              handler.resolve(response);
            } else {
              handler.next(err);
            }
          } catch (e) {
            handler.next(err);
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
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );

            // Process queued requests
            _processQueue();

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
      final refreshDio = Dio();
      refreshDio.options.baseUrl = ApiEndpoints.baseUrl;
      refreshDio.options.connectTimeout = const Duration(seconds: 30);
      refreshDio.options.receiveTimeout = const Duration(seconds: 30);

      // Add logging for refresh request
      refreshDio.interceptors.add(LogInterceptor(
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
      if (e is DioException) {
        AppLogger.error('Dio error details: ${e.response?.data}');
        AppLogger.error('Dio error status: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  void _processQueue() {
    final queue = List<Function>.from(_requestsQueue);
    _requestsQueue.clear();

    for (final request in queue) {
      request();
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

// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    AppLogger.error('ERROR MESSAGE: ${err.message}');
    handler.next(err);
  }
}

// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = _handleHttpError(err.response?.statusCode);
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      default:
        message = 'Network error occurred. Please try again.';
    }

    handler.next(DioException(
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
