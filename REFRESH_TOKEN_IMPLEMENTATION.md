# Cải thiện cơ chế Refresh Token trong Dio Interceptor

## Tóm tắt vấn đề
- Token expired (401) không được xử lý đúng cách
- Không có cơ chế retry request sau khi refresh token
- Race condition khi nhiều requests cùng lúc cần refresh token
- Sử dụng print statements thay vì proper logging

## Giải pháp đã triển khai

### 1. Cải thiện _AuthInterceptor

#### **Proactive Token Refresh**
- Kiểm tra token expiry trước khi gửi request
- Tự động refresh token nếu sắp hết hạn (trong vòng 30 giây)
- Tránh việc request bị fail do token expired

```dart
// Check if token is expired or about to expire
if (_isTokenExpired(token) && !_isRefreshing) {
  AppLogger.info('Token is expired/expiring, attempting refresh...');
  // ... refresh logic
}
```

#### **Queue Management cho Multiple Requests**
- Sử dụng static flag `_isRefreshing` để tránh multiple refresh calls
- Queue các requests đang chờ khi token đang được refresh
- Process queue sau khi refresh thành công

```dart
static bool _isRefreshing = false;
static final List<Function> _requestsQueue = [];

// If already refreshing, queue this request
if (_isRefreshing) {
  _requestsQueue.add(() async {
    // ... retry logic
  });
  return;
}
```

#### **Improved Error Handling**
- Tạo Dio instance riêng cho refresh request để tránh interceptor loop
- Detailed logging cho debugging
- Proper error handling với fallback logic

### 2. JWT Token Expiry Check

```dart
bool _isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payload = parts[1];
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
```

### 3. Proper Logging System

Tạo `AppLogger` utility để thay thế print statements:

```dart
class AppLogger {
  static void info(String message, {String? tag}) {
    developer.log(message, name: 'ClassroomMini', level: 800);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'ClassroomMini', level: 1000, error: error, stackTrace: stackTrace);
  }
  
  // ... debug, warning methods
}
```

### 4. Enhanced Refresh Token Flow

```dart
Future<bool> _refreshToken() async {
  try {
    final storageService = await StorageService.getInstance();
    final refreshToken = await storageService.getRefreshToken();

    if (refreshToken == null) {
      AppLogger.warning('No refresh token available');
      return false;
    }

    // Create separate Dio instance to avoid interceptor loops
    final refreshDio = Dio();
    refreshDio.options.baseUrl = ApiEndpoints.baseUrl;
    
    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final tokens = responseData['data']['tokens'];
        
        await storageService.saveTokens(
          tokens['accessToken'],
          tokens['refreshToken'],
        );
        
        AppLogger.info('Token refreshed successfully');
        return true;
      }
    }
    
    return false;
  } catch (e) {
    AppLogger.error('Token refresh error', error: e);
    return false;
  }
}
```

## Lợi ích của giải pháp

1. **Tự động xử lý token expired**: Không cần user login lại khi token hết hạn
2. **Tránh race conditions**: Multiple requests không gây ra multiple refresh calls
3. **Better UX**: Requests được retry tự động sau khi refresh token
4. **Proper error handling**: Clear logging và fallback mechanisms
5. **Proactive approach**: Token được refresh trước khi hết hạn

## Test Results

✅ Token expiry detection hoạt động chính xác
✅ Request format đúng với backend API
✅ Logging system hoạt động tốt
✅ Linter warnings đã được giải quyết

## Usage

Sau khi triển khai, hệ thống sẽ tự động:

1. Kiểm tra token expiry trước mỗi request
2. Refresh token nếu cần thiết
3. Retry failed requests với token mới
4. Queue multiple requests khi đang refresh
5. Clear tokens và redirect về login nếu refresh fails

Không cần thay đổi code ở controller hoặc repository level - tất cả được xử lý ở interceptor level.