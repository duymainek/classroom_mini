import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../local/cache_manager.dart';

class CacheInterceptor extends Interceptor {
  static final Map<RegExp, Duration> _ttlRules = {
    RegExp(r'^/courses(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/courses/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/courses/course/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/courses/semester/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/students(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/students/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/groups(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/groups/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/groups/course/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/materials(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/materials/[^/]+(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/assignments(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/assignments/[^/]+(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/quizzes(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/quizzes/[^/]+(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/announcements(\?.*)?$'): const Duration(hours: 6),
    RegExp(r'^/announcements/[^/]+(\?.*)?$'): const Duration(hours: 6),
    RegExp(r'^/assignments/.*/tracking(\?.*)?$'): const Duration(minutes: 30),
    RegExp(r'^/quizzes/.*/tracking(\?.*)?$'): const Duration(minutes: 30),
    RegExp(r'^/materials/.*/tracking(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/announcements/.*/tracking(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/dashboard(/.*)?(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/dashboard/instructor(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/dashboard/student(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/dashboard/current-semester(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/auth/me(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/profile(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/semesters(\?.*)?$'): const Duration(days: 7),
    RegExp(r'^/questions(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/forum/topics/[^/]+(\?.*)?$'): const Duration(minutes: 10),
    RegExp(r'^/forum/topics(\?.*)?$'): const Duration(minutes: 5),
  };

  static final List<RegExp> _noCachePatterns = [
    RegExp(r'^/forum/.*/replies'),
    RegExp(r'^/chat/unread-count'),
    RegExp(r'^/chat/conversations'),
    RegExp(r'^/chat/messages'),
    RegExp(r'^/upload'),
    RegExp(r'^/.*/attachments'),
    RegExp(r'^/.*/export'),
    RegExp(r'^/.*/import'),
    RegExp(r'^/.*/submissions'),
    RegExp(r'^/.*/grade'),
    RegExp(r'^/.*/statistics$'),
    RegExp(r'^/.*/comments$'),
    RegExp(r'^/.*/views$'),
    RegExp(r'^/.*/questions$'),
    RegExp(r'^/.*/reset-password$'),
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final path = _normalizePath(options.path);
    debugPrint('🔍 Cache check: original=${options.path}, normalized=$path');

    if (_shouldNotCache(path)) {
      debugPrint('🚫 Not caching: $path (blocked by noCachePatterns)');
      return handler.next(options);
    }

    final ttl = _getTTL(path);
    if (ttl == null) {
      debugPrint('⏭️ Not caching: $path (no TTL rule)');
      return handler.next(options);
    }

    final cachedEntry = CacheManager.get(
      path,
      options.queryParameters,
    );

    if (cachedEntry != null && cachedEntry.isValid) {
      debugPrint('📦 Cache HIT: $path (TTL: ${ttl.inMinutes}m remaining)');

      final cachedData = _ensureMapStringDynamic(cachedEntry.responseData);

      final response = Response(
        requestOptions: options,
        data: cachedData,
        statusCode: cachedEntry.statusCode,
        headers: cachedEntry.headers != null
            ? Headers.fromMap(cachedEntry.headers!)
            : Headers(),
        extra: {
          'cached': true,
          'cachedAt': cachedEntry.cachedAt.toIso8601String(),
          'expiresAt': cachedEntry.expiresAt.toIso8601String(),
        },
      );

      return handler.resolve(response);
    }

    debugPrint('📦 Cache MISS: $path (will cache with TTL: ${ttl.inMinutes}m)');

    options.extra['shouldCache'] = true;
    options.extra['cachePath'] = path;

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final method = response.requestOptions.method.toUpperCase();
    
    // Clear cache for POST/PUT/DELETE requests
    if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
      if (response.statusCode != null && 
          response.statusCode! >= 200 && 
          response.statusCode! < 300) {
        final path = _normalizePath(response.requestOptions.path);
        await _clearRelatedCache(path, method);
      }
    }
    
    // Clear cache for topic detail when view is tracked
    if (method == 'POST' && 
        response.statusCode == 200 &&
        response.requestOptions.path.contains('/forum/topics/') &&
        response.requestOptions.path.contains('/views')) {
      final topicId = _extractTopicId(response.requestOptions.path);
      if (topicId != null) {
        await CacheManager.clear('/forum/topics/$topicId', null);
        debugPrint('🗑️ Cleared cache for topic: $topicId (after view tracking)');
      }
    }
    
    if (method != 'GET') {
      return handler.next(response);
    }

    if (response.statusCode != 200) {
      return handler.next(response);
    }

    final shouldCache = response.requestOptions.extra['shouldCache'] == true;
    if (!shouldCache) {
      return handler.next(response);
    }

    final path = response.requestOptions.extra['cachePath'] as String? ??
        _normalizePath(response.requestOptions.path);

    if (_shouldNotCache(path)) {
      return handler.next(response);
    }

    final ttl = _getTTL(path);
    if (ttl == null) {
      return handler.next(response);
    }

    try {
      if (response.data is! Map<String, dynamic>) {
        debugPrint('⚠️ Skipping cache: response data is not Map<String, dynamic>');
        return handler.next(response);
      }

      final headersMap = <String, List<String>>{};
      response.headers.forEach((key, values) {
        headersMap[key] = values;
      });

      await CacheManager.put(
        path: path,
        queryParams: response.requestOptions.queryParameters,
        responseData: response.data as Map<String, dynamic>,
        statusCode: response.statusCode!,
        ttl: ttl,
        headers: headersMap,
      );
    } catch (e) {
      debugPrint('❌ Error caching response: $e');
    }

    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isNetworkError(err) &&
        err.requestOptions.method.toUpperCase() == 'GET') {
      final path = _normalizePath(err.requestOptions.path);
      final cachedEntry = CacheManager.get(
        path,
        err.requestOptions.queryParameters,
      );

      if (cachedEntry != null) {
        debugPrint('⚠️ Network error, using STALE cache: $path');

        final cachedData = _ensureMapStringDynamic(cachedEntry.responseData);

        final response = Response(
          requestOptions: err.requestOptions,
          data: cachedData,
          statusCode: cachedEntry.statusCode,
          headers: cachedEntry.headers != null
              ? Headers.fromMap(cachedEntry.headers!)
              : Headers(),
          extra: {
            'cached': true,
            'stale': true,
            'cachedAt': cachedEntry.cachedAt.toIso8601String(),
            'expiresAt': cachedEntry.expiresAt.toIso8601String(),
          },
        );

        return handler.resolve(response);
      }
    }

    return handler.next(err);
  }

  bool _shouldNotCache(String path) {
    for (final pattern in _noCachePatterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  Duration? _getTTL(String path) {
    for (final entry in _ttlRules.entries) {
      if (entry.key.hasMatch(path)) {
        debugPrint(
            '✅ [CacheInterceptor] Pattern matched: ${entry.key.pattern} → TTL: ${entry.value.inMinutes}m');
        return entry.value;
      }
    }
    debugPrint('⚠️ [CacheInterceptor] No TTL pattern matched for: $path');
    return null;
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown && err.error != null);
  }

  Map<String, dynamic> _ensureMapStringDynamic(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return Map<String, dynamic>.from(data);
    }
  }

  String _normalizePath(String path) {
    if (path.startsWith('/api/')) {
      return path.substring(4);
    } else if (path.startsWith('/')) {
      return path;
    } else {
      return '/$path';
    }
  }
  
  String? _extractTopicId(String path) {
    final match = RegExp(r'/forum/topics/([^/]+)').firstMatch(path);
    return match?.group(1);
  }

  Future<void> _clearRelatedCache(String path, String method) async {
    try {
      final patternsToClear = <String>[];
      
      // Extract resource name and ID from path
      // Examples:
      // /auth/student/create → students
      // /students → students
      // /students/123 → students, students/123
      // /courses → courses
      // /groups/course/123 → groups, groups/course/123
      
      // Pattern matching rules
      if (path.contains('/auth/student/create') || path.contains('/students')) {
        patternsToClear.add('/students');
        
        // Extract student ID if exists (e.g., /students/123)
        final studentIdMatch = RegExp(r'/students/([^/]+)').firstMatch(path);
        if (studentIdMatch != null) {
          final studentId = studentIdMatch.group(1);
          patternsToClear.add('/students/$studentId');
        }
        
        // Also clear dashboard if student-related
        patternsToClear.add('/dashboard');
      }
      
      if (path.contains('/courses')) {
        patternsToClear.add('/courses');
        
        final courseIdMatch = RegExp(r'/courses/([^/]+)').firstMatch(path);
        if (courseIdMatch != null) {
          final courseId = courseIdMatch.group(1);
          // Don't clear if it's a sub-resource like /courses/semester/123
          if (!path.contains('/courses/semester/') && 
              !path.contains('/courses/course/')) {
            patternsToClear.add('/courses/$courseId');
          }
        }
        
        // Clear courses by semester if path contains semester
        if (path.contains('/courses/semester/')) {
          final semesterIdMatch = RegExp(r'/courses/semester/([^/]+)').firstMatch(path);
          if (semesterIdMatch != null) {
            patternsToClear.add('/courses/semester/${semesterIdMatch.group(1)}');
          }
        }
        
        patternsToClear.add('/dashboard');
      }
      
      if (path.contains('/groups')) {
        patternsToClear.add('/groups');
        
        final groupIdMatch = RegExp(r'/groups/([^/]+)').firstMatch(path);
        if (groupIdMatch != null) {
          final groupId = groupIdMatch.group(1);
          // Don't clear if it's a sub-resource like /groups/course/123
          if (!path.contains('/groups/course/')) {
            patternsToClear.add('/groups/$groupId');
          }
        }
        
        // Clear groups by course if path contains course
        if (path.contains('/groups/course/')) {
          final courseIdMatch = RegExp(r'/groups/course/([^/]+)').firstMatch(path);
          if (courseIdMatch != null) {
            patternsToClear.add('/groups/course/${courseIdMatch.group(1)}');
          }
        }
      }
      
      if (path.contains('/semesters')) {
        patternsToClear.add('/semesters');
        
        final semesterIdMatch = RegExp(r'/semesters/([^/]+)').firstMatch(path);
        if (semesterIdMatch != null) {
          final semesterId = semesterIdMatch.group(1);
          patternsToClear.add('/semesters/$semesterId');
        }
        
        patternsToClear.add('/dashboard');
      }
      
      if (path.contains('/assignments')) {
        patternsToClear.add('/assignments');
        
        final assignmentIdMatch = RegExp(r'/assignments/([^/]+)').firstMatch(path);
        if (assignmentIdMatch != null) {
          final assignmentId = assignmentIdMatch.group(1);
          patternsToClear.add('/assignments/$assignmentId');
        }
      }
      
      if (path.contains('/materials')) {
        patternsToClear.add('/materials');
        
        final materialIdMatch = RegExp(r'/materials/([^/]+)').firstMatch(path);
        if (materialIdMatch != null) {
          final materialId = materialIdMatch.group(1);
          patternsToClear.add('/materials/$materialId');
        }
      }
      
      if (path.contains('/announcements')) {
        patternsToClear.add('/announcements');
        
        final announcementIdMatch = RegExp(r'/announcements/([^/]+)').firstMatch(path);
        if (announcementIdMatch != null) {
          final announcementId = announcementIdMatch.group(1);
          patternsToClear.add('/announcements/$announcementId');
        }
      }
      
      if (path.contains('/profile') || path.contains('/auth/me')) {
        patternsToClear.add('/profile');
        patternsToClear.add('/auth/me');
      }
      
      // Clear cache by pattern for each matched path
      for (final pattern in patternsToClear) {
        await CacheManager.clearByPathPattern(pattern);
        debugPrint('🗑️ Cleared cache pattern: $pattern (after $method $path)');
      }
    } catch (e) {
      debugPrint('❌ Error clearing related cache: $e');
    }
  }
}
