import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../local/cache_manager.dart';
import '../../local/sync_queue_manager.dart';
import '../../services/connectivity_service.dart';

class PendingOperationTracker {
  static final Map<String, String> _latestQueueIdByPath = {};

  static void setQueueIdForPath(String path, String queueId) {
    _latestQueueIdByPath[path] = queueId;
  }

  static String? getLatestQueueIdForPath(String path) {
    return _latestQueueIdByPath[path];
  }

  static void clearQueueIdForPath(String path) {
    _latestQueueIdByPath.remove(path);
  }
}

class OfflineInterceptor extends Interceptor {
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
    RegExp(r'^/chat/conversations(\?.*)?$'): const Duration(minutes: 2),
  };

  static final List<RegExp> _noCachePatterns = [
    RegExp(r'^/forum/.*/replies'),
    RegExp(r'^/chat/unread-count'),
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

  static final List<RegExp> _noSyncPatterns = [
    RegExp(r'^/upload'),
    RegExp(r'^/.*/attachments'),
    RegExp(r'^/chat/messages'),
    RegExp(r'^/.*/export'),
  ];

  ConnectivityService? _connectivityService;

  ConnectivityService get connectivityService {
    _connectivityService ??= Get.find<ConnectivityService>();
    return _connectivityService!;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final method = options.method.toUpperCase();
    final path = _normalizePath(options.path);

    print(
        '🔍 [OfflineInterceptor] Request: $method $path (original: ${options.path})');

    if (method == 'GET') {
      await _handleGetRequest(options, path, handler);
    } else if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
      await _handleMutatingRequest(options, path, method, handler);
    } else {
      handler.next(options);
    }
  }

  Future<void> _handleGetRequest(
    RequestOptions options,
    String path,
    RequestInterceptorHandler handler,
  ) async {
    final isOnline = connectivityService.isOnline.value;

    if (isOnline) {
      return handler.next(options);
    }

    if (_shouldNotCache(path)) {
      return handler.next(options);
    }

    final ttl = _getTTL(path);
    if (ttl == null) {
      return handler.next(options);
    }

    final cachedEntry = CacheManager.get(path, options.queryParameters);

    if (cachedEntry != null) {
      print('📦 Offline - Using cache: $path');

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
          'stale': cachedEntry.isExpired,
          'cachedAt': cachedEntry.cachedAt.toIso8601String(),
          'expiresAt': cachedEntry.expiresAt.toIso8601String(),
        },
      );
      return handler.resolve(response);
    }

    return handler.next(options);
  }

  Future<void> _handleMutatingRequest(
    RequestOptions options,
    String path,
    String method,
    RequestInterceptorHandler handler,
  ) async {
    final isOnline = connectivityService.isOnline.value;
    print(
        '🔍 [OfflineInterceptor] Handling mutating request: $method $path, isOnline: $isOnline');

    if (_shouldNotSync(path)) {
      print('🚫 Path should not sync: $path');
      if (!isOnline) {
        print('❌ Rejecting: Cannot perform this operation offline for $path');
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Cannot perform this operation offline',
            type: DioExceptionType.connectionError,
          ),
        );
      }
      return handler.next(options);
    }

    print('✅ Path can be synced: $path');

    if (!isOnline) {
      print('📴 Offline - Queueing: $method $path');

      try {
        final id = await SyncQueueManager.add(
          method: method,
          path: path,
          queryParams: options.queryParameters,
          data: options.data is Map<String, dynamic>
              ? options.data as Map<String, dynamic>
              : null,
        );

        PendingOperationTracker.setQueueIdForPath(path, id);

        final cachedEntry = CacheManager.get(path, options.queryParameters);
        if (cachedEntry != null) {
          print('✅ Optimistic update - returning cached data');

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
              'queued': true,
              'queueId': id,
            },
          );
          return handler.resolve(response);
        }

        final optimisticData =
            _createOptimisticResponse(path, method, options.data);
        if (optimisticData != null) {
          print('✅ Optimistic update - returning optimistic data');
          print('   Optimistic data: $optimisticData');

          // Format response to match API response structure
          final formattedResponse = {
            'success': true,
            'message': 'Queued for sync',
            'data': optimisticData,
          };

          final response = Response(
            requestOptions: options,
            data: formattedResponse,
            statusCode: 200,
            headers: Headers(),
            extra: {
              'optimistic': true,
              'queued': true,
              'queueId': id,
            },
          );
          return handler.resolve(response);
        }

        print('⚠️ No optimistic data created for $method $path');
        print('   Data type: ${options.data.runtimeType}');
        print('   Data: ${options.data}');

        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Offline and no cached data available',
            type: DioExceptionType.connectionError,
          ),
        );
      } catch (e) {
        print('❌ Error queueing operation: $e');
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Failed to queue operation',
            type: DioExceptionType.unknown,
          ),
        );
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final method = response.requestOptions.method.toUpperCase();

    // Clear cache for quiz detail when quiz is updated/deleted
    if ((method == 'PUT' || method == 'DELETE') &&
        response.requestOptions.path.contains('/quizzes/') &&
        !response.requestOptions.path.contains('/questions')) {
      final quizId = _extractQuizId(response.requestOptions.path);
      if (quizId != null) {
        await CacheManager.clear('/quizzes/$quizId', null);
        print('🗑️ Cleared cache for quiz: $quizId');
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
        print('🗑️ Cleared cache for topic: $topicId (after view tracking)');
      }
    }

    return handler.next(response);
  }

  String? _extractQuizId(String path) {
    final match = RegExp(r'/quizzes/([^/]+)').firstMatch(path);
    return match?.group(1);
  }

  String? _extractTopicId(String path) {
    final match = RegExp(r'/forum/topics/([^/]+)').firstMatch(path);
    return match?.group(1);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isNetworkError(err) &&
        err.requestOptions.method.toUpperCase() == 'GET') {
      final path = _normalizePath(err.requestOptions.path);
      final cachedEntry = CacheManager.get(
        path,
        err.requestOptions.queryParameters,
      );

      if (cachedEntry != null) {
        print('⚠️ Network error, using STALE cache: $path');

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
    return _noCachePatterns.any((pattern) => pattern.hasMatch(path));
  }

  bool _shouldNotSync(String path) {
    print('🔍 [DEBUG] Checking _shouldNotSync for path: $path');
    print('🔍 [DEBUG] _noSyncPatterns count: ${_noSyncPatterns.length}');
    for (var i = 0; i < _noSyncPatterns.length; i++) {
      print('🔍 [DEBUG] Pattern $i: ${_noSyncPatterns[i].pattern}');
    }

    final shouldNotSync = _noSyncPatterns.any((pattern) {
      final matches = pattern.hasMatch(path);
      if (matches) {
        print('🚫 Pattern matched (no sync): ${pattern.pattern} -> $path');
      }
      return matches;
    });
    if (shouldNotSync) {
      print('🚫 Path should not sync: $path');
    } else {
      print('✅ Path CAN sync: $path');
    }
    return shouldNotSync;
  }

  Duration? _getTTL(String path) {
    for (final entry in _ttlRules.entries) {
      if (entry.key.hasMatch(path)) {
        return entry.value;
      }
    }
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
    String normalized;
    if (path.startsWith('/api/')) {
      normalized = path.substring(4);
    } else if (path.startsWith('/')) {
      normalized = path;
    } else {
      normalized = '/$path';
    }
    print('🔍 [OfflineInterceptor] Normalized path: $path -> $normalized');
    return normalized;
  }

  Map<String, dynamic>? _createOptimisticResponse(
    String path,
    String method,
    dynamic data,
  ) {
    if (method == 'POST' && data is Map<String, dynamic>) {
      final optimistic = Map<String, dynamic>.from(data);
      optimistic['id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      optimistic['createdAt'] = DateTime.now().toIso8601String();
      optimistic['_optimistic'] = true;
      return optimistic;
    } else if (method == 'PUT' || method == 'PATCH') {
      if (data is Map<String, dynamic>) {
        final optimistic = Map<String, dynamic>.from(data);
        optimistic['updatedAt'] = DateTime.now().toIso8601String();
        optimistic['_optimistic'] = true;
        return optimistic;
      }
    }
    return null;
  }
}
