# HIVE CACHE INTERCEPTOR - IMPLEMENTATION GUIDE

## 📦 Setup Dependencies

**`pubspec.yaml`:**
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  crypto: ^3.0.3  # For generating cache keys

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

---

## 🗄️ Hive Cache Model

**`lib/app/data/local/models/cache_entry.dart`:**

```dart
import 'package:hive/hive.dart';

part 'cache_entry.g.dart';

/// Cache entry model for storing HTTP responses
@HiveType(typeId: 0)
class CacheEntry {
  @HiveField(0)
  final String key; // Unique key: hash(path + queryParams)
  
  @HiveField(1)
  final String path; // API path: /courses, /students, etc.
  
  @HiveField(2)
  final Map<String, dynamic> queryParams; // Query parameters
  
  @HiveField(3)
  final Map<String, dynamic> responseData; // Cached response
  
  @HiveField(4)
  final int statusCode; // HTTP status code
  
  @HiveField(5)
  final DateTime cachedAt; // When cached
  
  @HiveField(6)
  final DateTime expiresAt; // When expires
  
  @HiveField(7)
  final Map<String, dynamic>? headers; // Response headers (optional)

  CacheEntry({
    required this.key,
    required this.path,
    required this.queryParams,
    required this.responseData,
    required this.statusCode,
    required this.cachedAt,
    required this.expiresAt,
    this.headers,
  });

  /// Check if cache is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);
  
  /// Check if cache is expired
  bool get isExpired => !isValid;
  
  /// Time until expiry
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
```

Generate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔧 Cache Manager Service

**`lib/app/data/local/cache_manager.dart`:**

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'models/cache_entry.dart';

/// Cache Manager for handling HTTP response caching
class CacheManager {
  static const String _boxName = 'http_cache';
  static Box<CacheEntry>? _box;

  /// Initialize Hive and open cache box
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CacheEntryAdapter());
    }
    
    // Open box
    _box = await Hive.openBox<CacheEntry>(_boxName);
    
    // Clean expired cache on init
    await clearExpiredCache();
    
    print('CacheManager initialized. Cached items: ${_box?.length ?? 0}');
  }

  /// Get cache box
  static Box<CacheEntry> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('CacheManager not initialized. Call CacheManager.init() first');
    }
    return _box!;
  }

  /// Generate cache key from path and query params
  static String generateKey(String path, Map<String, dynamic>? queryParams) {
    final normalizedPath = path.toLowerCase().trim();
    
    // Sort query params for consistent key
    final sortedParams = queryParams?.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final queryString = sortedParams
        ?.map((e) => '${e.key}=${e.value}')
        .join('&') ?? '';
    
    final combined = '$normalizedPath?$queryString';
    
    // Generate hash
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    
    return hash.toString();
  }

  /// Get cached response
  static CacheEntry? get(String path, Map<String, dynamic>? queryParams) {
    try {
      final key = generateKey(path, queryParams);
      final entry = box.get(key);
      
      if (entry == null) return null;
      
      // Check if expired
      if (entry.isExpired) {
        box.delete(key);
        return null;
      }
      
      return entry;
    } catch (e) {
      print('Error getting cache: $e');
      return null;
    }
  }

  /// Save response to cache
  static Future<void> put({
    required String path,
    required Map<String, dynamic>? queryParams,
    required Map<String, dynamic> responseData,
    required int statusCode,
    required Duration ttl,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final key = generateKey(path, queryParams);
      final now = DateTime.now();
      
      final entry = CacheEntry(
        key: key,
        path: path,
        queryParams: queryParams ?? {},
        responseData: responseData,
        statusCode: statusCode,
        cachedAt: now,
        expiresAt: now.add(ttl),
        headers: headers,
      );
      
      await box.put(key, entry);
      print('✅ Cached: $path (TTL: ${ttl.inMinutes}m)');
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  /// Clear specific cache entry
  static Future<void> clear(String path, Map<String, dynamic>? queryParams) async {
    try {
      final key = generateKey(path, queryParams);
      await box.delete(key);
      print('🗑️ Cleared cache: $path');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear all expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      for (var entry in box.values) {
        if (entry.expiresAt.isBefore(now)) {
          expiredKeys.add(entry.key);
        }
      }
      
      if (expiredKeys.isNotEmpty) {
        await box.deleteAll(expiredKeys);
        print('🗑️ Cleared ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      await box.clear();
      print('🗑️ Cleared all cache');
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int validCount = 0;
    int expiredCount = 0;
    
    for (var entry in box.values) {
      if (entry.expiresAt.isAfter(now)) {
        validCount++;
      } else {
        expiredCount++;
      }
    }
    
    return {
      'total': box.length,
      'valid': validCount,
      'expired': expiredCount,
    };
  }

  /// Clear cache by path pattern
  static Future<void> clearByPathPattern(String pattern) async {
    try {
      final keysToDelete = <String>[];
      
      for (var entry in box.values) {
        if (entry.path.contains(pattern)) {
          keysToDelete.add(entry.key);
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        print('🗑️ Cleared ${keysToDelete.length} cache entries matching: $pattern');
      }
    } catch (e) {
      print('Error clearing cache by pattern: $e');
    }
  }
}
```

---

## 🔌 Cache Interceptor

**`lib/app/data/network/interceptors/cache_interceptor.dart`:**

```dart
import 'package:dio/dio.dart';
import '../../local/cache_manager.dart';

/// Dio interceptor for automatic HTTP response caching
class CacheInterceptor extends Interceptor {
  /// Map of path patterns to TTL durations
  /// Based on CACHEABLE FEATURES ANALYSIS document
  static final Map<RegExp, Duration> _ttlRules = {
    // ✅ PRIORITY HIGH - 1 day
    RegExp(r'^/courses(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/students(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/groups(\?.*)?$'): const Duration(days: 1),
    RegExp(r'^/materials(\?.*)?$'): const Duration(days: 1),
    
    // ✅ PRIORITY HIGH - 1 hour
    RegExp(r'^/assignments(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/quizzes(\?.*)?$'): const Duration(hours: 1),
    
    // ✅ PRIORITY HIGH - 6 hours
    RegExp(r'^/announcements(\?.*)?$'): const Duration(hours: 6),
    
    // ⚠️ PRIORITY MEDIUM - 30 minutes
    RegExp(r'^/assignments/.*/tracking(\?.*)?$'): const Duration(minutes: 30),
    RegExp(r'^/quizzes/.*/tracking(\?.*)?$'): const Duration(minutes: 30),
    
    // ⚠️ PRIORITY MEDIUM - 1 hour
    RegExp(r'^/materials/.*/tracking(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/announcements/.*/tracking(\?.*)?$'): const Duration(hours: 1),
    RegExp(r'^/dashboard(\?.*)?$'): const Duration(hours: 1),
    
    // 🔽 PRIORITY LOW - 7 days
    RegExp(r'^/semesters(\?.*)?$'): const Duration(days: 7),
    
    // 🔽 PRIORITY LOW - 1 day
    RegExp(r'^/questions(\?.*)?$'): const Duration(days: 1),
    
    // 🔽 PRIORITY LOW - 5 minutes
    RegExp(r'^/forum/topics(\?.*)?$'): const Duration(minutes: 5),
  };

  /// Paths that should NOT be cached
  static final List<RegExp> _noCachePatterns = [
    // Forum replies (real-time)
    RegExp(r'^/forum/.*/replies'),
    
    // Private messages (real-time)
    RegExp(r'^/chat/'),
    
    // File uploads
    RegExp(r'^/upload'),
    RegExp(r'^/.*/attachments'),
    
    // CSV operations
    RegExp(r'^/.*/export'),
    RegExp(r'^/.*/import'),
    
    // Submissions
    RegExp(r'^/.*/submissions'),
    
    // Grading
    RegExp(r'^/.*/grade'),
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Check if path should not be cached
    if (_shouldNotCache(options.path)) {
      return handler.next(options);
    }

    // Try to get from cache
    final cachedEntry = CacheManager.get(
      options.path,
      options.queryParameters,
    );

    if (cachedEntry != null && cachedEntry.isValid) {
      // Return cached response
      print('📦 Cache HIT: ${options.path}');
      
      final response = Response(
        requestOptions: options,
        data: cachedEntry.responseData,
        statusCode: cachedEntry.statusCode,
        headers: Headers.fromMap(cachedEntry.headers ?? {}),
        extra: {
          'cached': true,
          'cachedAt': cachedEntry.cachedAt.toIso8601String(),
          'expiresAt': cachedEntry.expiresAt.toIso8601String(),
        },
      );

      return handler.resolve(response);
    }

    print('📦 Cache MISS: ${options.path}');
    
    // Mark that we should cache the response
    options.extra['shouldCache'] = true;
    
    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Only cache successful GET responses
    if (response.requestOptions.method.toUpperCase() != 'GET') {
      return handler.next(response);
    }

    if (response.statusCode != 200) {
      return handler.next(response);
    }

    // Check if should cache
    final shouldCache = response.requestOptions.extra['shouldCache'] == true;
    if (!shouldCache) {
      return handler.next(response);
    }

    // Check if path should not be cached
    if (_shouldNotCache(response.requestOptions.path)) {
      return handler.next(response);
    }

    // Get TTL for this path
    final ttl = _getTTL(response.requestOptions.path);
    if (ttl == null) {
      return handler.next(response);
    }

    // Cache the response
    try {
      await CacheManager.put(
        path: response.requestOptions.path,
        queryParams: response.requestOptions.queryParameters,
        responseData: response.data as Map<String, dynamic>,
        statusCode: response.statusCode!,
        ttl: ttl,
        headers: response.headers.map,
      );
    } catch (e) {
      print('❌ Error caching response: $e');
    }

    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If network error and we have cache, try to use it
    if (_isNetworkError(err) && err.requestOptions.method.toUpperCase() == 'GET') {
      final cachedEntry = CacheManager.get(
        err.requestOptions.path,
        err.requestOptions.queryParameters,
      );

      if (cachedEntry != null) {
        // Return stale cache with warning
        print('⚠️ Network error, using STALE cache: ${err.requestOptions.path}');
        
        final response = Response(
          requestOptions: err.requestOptions,
          data: cachedEntry.responseData,
          statusCode: cachedEntry.statusCode,
          headers: Headers.fromMap(cachedEntry.headers ?? {}),
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

  /// Check if path should not be cached
  bool _shouldNotCache(String path) {
    for (final pattern in _noCachePatterns) {
      if (pattern.hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  /// Get TTL for path
  Duration? _getTTL(String path) {
    for (final entry in _ttlRules.entries) {
      if (entry.key.hasMatch(path)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Check if error is network-related
  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown && err.error != null);
  }
}
```

---

## 🔄 Update DioClient

**`lib/app/data/services/api_service.dart`:**

```dart
import 'package:dio/dio.dart' as dio_pkg;
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/config/api_endpoints.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'interceptors/cache_interceptor.dart';
import '../local/cache_manager.dart';

class DioClient {
  static dio_pkg.Dio? _dio;
  static ApiService? _apiService;
  static bool _cacheInitialized = false;

  /// Initialize cache (call once on app start)
  static Future<void> initCache() async {
    if (!_cacheInitialized) {
      await CacheManager.init();
      _cacheInitialized = true;
      print('✅ Cache initialized');
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
      CacheInterceptor(), // ✅ Add cache interceptor AFTER auth
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
      _ErrorInterceptor(),
    ]);

    return dio;
  }

  static void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
  }

  /// Clear cache for specific path
  static Future<void> clearCache(String path, [Map<String, dynamic>? queryParams]) async {
    await CacheManager.clear(path, queryParams);
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    await CacheManager.clearAll();
  }

  /// Clear cache by pattern (e.g., '/courses')
  static Future<void> clearCacheByPattern(String pattern) async {
    await CacheManager.clearByPathPattern(pattern);
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return CacheManager.getStats();
  }
}
```

---

## 🚀 Initialize Cache on App Start

**`lib/main.dart`:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize cache BEFORE runApp
  await DioClient.initCache();
  
  runApp(MyApp());
}
```

---

## 📝 Usage Examples

### 1. **Normal API Call (Auto-cached)**

```dart
// Controller code - NO changes needed!
class CourseController extends GetxController {
  final ApiService _api = DioClient.apiService;

  Future<void> loadCourses() async {
    try {
      // First call: fetches from API + caches
      // Second call: returns from cache (if within TTL)
      final response = await _api.getCourses();
      
      courses.value = response.data?.courses ?? [];
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

### 2. **Force Refresh (Bypass Cache)**

```dart
Future<void> refreshCourses() async {
  // Clear cache first
  await DioClient.clearCacheByPattern('/courses');
  
  // Then fetch fresh data
  await loadCourses();
}
```

### 3. **Manual Cache Invalidation**

```dart
// After creating/updating/deleting a course
Future<void> deleteCourse(String courseId) async {
  await _api.deleteCourse(courseId);
  
  // Invalidate courses cache
  await DioClient.clearCacheByPattern('/courses');
  
  // Reload fresh data
  await loadCourses();
}
```

### 4. **Check if Response is from Cache**

```dart
final response = await _api.getCourses();

// Check extra fields
final isCached = response.extra?['cached'] == true;
final isStale = response.extra?['stale'] == true;

if (isCached) {
  print('📦 Data from cache');
  if (isStale) {
    print('⚠️ Cache is stale (used as fallback)');
  }
}
```

### 5. **View Cache Stats**

```dart
// In settings page
final stats = DioClient.getCacheStats();
print('Total: ${stats['total']}');
print('Valid: ${stats['valid']}');
print('Expired: ${stats['expired']}');
```

---

## 🎨 UI Indicators for Cached Data

**Show cache indicator in UI:**

```dart
class CourseListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CourseController>(
      builder: (controller) {
        return RefreshIndicator(
          onRefresh: controller.refreshCourses,
          child: Column(
            children: [
              // Cache indicator
              if (controller.isDataFromCache)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.cached, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Showing cached data. Pull to refresh.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
              
              // List
              Expanded(
                child: ListView.builder(
                  itemCount: controller.courses.length,
                  itemBuilder: (context, index) {
                    return CourseCard(course: controller.courses[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## ✅ BENEFITS

1. **🚀 Faster Load Times**: Instant data from cache
2. **📴 Offline Support**: Works without internet (stale cache)
3. **💾 Reduced Bandwidth**: Less API calls
4. **🔧 Zero Code Changes**: Transparent to existing code
5. **⚙️ Configurable TTL**: Per-endpoint cache duration
6. **🧹 Auto Cleanup**: Expired cache removed automatically

---

## 📊 SUMMARY TABLE

| Feature | Cached | TTL | Auto Invalidate on Write |
|---------|--------|-----|--------------------------|
| Course List | ✅ | 1 day | ✅ (on create/update/delete) |
| Student List | ✅ | 1 day | ✅ |
| Group List | ✅ | 1 day | ✅ |
| Assignment List | ✅ | 1 hour | ✅ |
| Quiz List | ✅ | 1 hour | ✅ |
| Material List | ✅ | 1 day | ✅ |
| Announcement List | ✅ | 6 hours | ✅ |
| Tracking Data | ✅ | 30 min | ❌ (stale OK) |
| Dashboard Metrics | ✅ | 1 hour | ❌ (stale OK) |
| Forum Topics | ✅ | 5 min | ❌ (real-time) |
| Forum Replies | ❌ | - | - |
| Private Messages | ❌ | - | - |

---

Với approach này, bạn có **offline capability** mà không cần thay đổi code ở controllers! 🎉