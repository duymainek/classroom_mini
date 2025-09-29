import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/assignment_model.dart';
import 'storage_service.dart';

/**
 * Model đơn giản cho group response từ API
 */
class SimpleGroup {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SimpleGroup({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SimpleGroup.fromJson(Map<String, dynamic> json) {
    return SimpleGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/**
 * Service để load metadata (courses và groups) cho các form
 * Tách biệt khỏi AssignmentController để tránh gọi API không cần thiết
 */
class MetadataService extends GetxService {
  final ApiService _apiService;
  final Dio _dio;

  MetadataService(this._apiService) : _dio = Dio() {
    _dio.options.baseUrl = 'http://localhost:3131';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Thêm auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Lấy token từ storage
        try {
          final storageService = Get.find<StorageService>();
          final token = await storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Ignore nếu không có token
        }
        handler.next(options);
      },
    ));
  }

  /**
   * Load danh sách courses cho form
   * @returns {Future<List<CourseInfo>>} Danh sách courses
   */
  Future<List<CourseInfo>> loadCourses() async {
    try {
      final response = await _apiService.getCourses(
        page: 1,
        limit: 200,
        search: '',
        status: 'all',
        semesterId: '',
        sortBy: 'created_at',
        sortOrder: 'desc',
      );

      if (response.success) {
        // Chuyển đổi từ Course sang CourseInfo
        return response.data.courses
            .map((course) => CourseInfo(
                  id: course.id,
                  code: course.code,
                  name: course.name,
                ))
            .toList();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load courses: $e');
      return [];
    }
  }

  /**
   * Load danh sách groups cho một course cụ thể
   * @param {String} courseId - ID của course
   * @returns {Future<List<GroupInfo>>} Danh sách groups
   */
  Future<List<GroupInfo>> loadGroupsForCourse(String courseId) async {
    try {
      // Gọi API trực tiếp để tránh lỗi cast model
      final response = await _dio.get(
        '/api/groups/course/$courseId',
        queryParameters: {
          'page': 1,
          'limit': 200,
          'search': '',
          'status': 'all',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final groupsData = data['data']['groups'] as List<dynamic>;
          final List<GroupInfo> groups = [];

          for (final groupData in groupsData) {
            groups.add(GroupInfo(
              id: groupData['id'] as String,
              name: groupData['name'] as String,
            ));
          }

          return groups;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load groups: $e');
      return [];
    }
  }

  /**
   * Load cả courses và groups cho form
   * @param {String?} selectedCourseId - Course ID đã chọn (optional)
   * @returns {Future<Map<String, dynamic>>} Map chứa courses và groups
   */
  Future<Map<String, dynamic>> loadFormMetadata(
      {String? selectedCourseId}) async {
    try {
      // Load courses
      final courses = await loadCourses();

      // Load groups nếu có course được chọn
      List<GroupInfo> groups = [];
      if (selectedCourseId != null && selectedCourseId.isNotEmpty) {
        groups = await loadGroupsForCourse(selectedCourseId);
      }

      return {
        'courses': courses,
        'groups': groups,
      };
    } catch (e) {
      Get.snackbar('Error', 'Failed to load metadata: $e');
      return {
        'courses': <CourseInfo>[],
        'groups': <GroupInfo>[],
      };
    }
  }
}
