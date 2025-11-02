# OFFLINE-FIRST VỚI DIO INTERCEPTOR - HIGH-LEVEL GUIDE

## 🎯 CHIẾN LƯỢC

**Mục tiêu:** Handle tất cả offline logic ở **DioClient level**, repository/controller KHÔNG cần thay đổi gì.

```
┌─────────────────────────────────────────────┐
│          Controller (NO CHANGES)             │
│         repository.getCourses()              │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│        Repository (NO CHANGES)               │
│         api.getCourses()                     │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            DioClient                         │
│  ┌────────────────────────────────────────┐ │
│  │  OfflineInterceptor (ALL LOGIC HERE)   │ │
│  │  - onRequest: Check cache + network    │ │
│  │  - onResponse: Save to cache + queue   │ │
│  │  - onError: Use cache fallback         │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼────┐          ┌─────▼─────┐
   │  Cache  │          │ SyncQueue │
   │  (Hive) │          │  (Hive)   │
   └─────────┘          └───────────┘
```

---

## 📋 KIẾN TRÚC TỔNG QUAN

### 3 Components Chính:

1. **OfflineInterceptor** - Xử lý tất cả offline logic
2. **Cache Storage (Hive)** - Lưu responses của GET requests
3. **Sync Queue (Hive)** - Lưu pending operations (POST/PUT/DELETE)

### Flow Hoạt Động:

#### **GET Request (Read):**
```
User calls API
    ↓
onRequest: Check cache
    ↓
If cache valid → Return cache (no API call)
If cache expired or miss → Continue to API
    ↓
onResponse: Save response to cache
    ↓
Return to user
```

#### **POST/PUT/DELETE (Write):**
```
User calls API
    ↓
onRequest: Add to sync queue first
    ↓
If online → Execute API call normally
If offline → Return fake success response
    ↓
Background: SyncQueue processes pending operations
```

---

## 🗄️ HIVE STRUCTURE

### Box 1: `http_cache`
```dart
{
  "key_hash_xxx": {
    path: "/courses",
    queryParams: {...},
    response: {...},
    cachedAt: timestamp,
    expiresAt: timestamp,
  }
}
```

### Box 2: `sync_queue`
```dart
{
  "operation_id_xxx": {
    method: "POST",
    path: "/courses",
    payload: {...},
    createdAt: timestamp,
    status: "pending",
    retryCount: 0,
  }
}
```

---

## 🔧 IMPLEMENTATION OVERVIEW

### Step 1: Setup Hive

```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2
```

### Step 2: Create Models

**Chỉ cần 2 models:**
- `CacheEntry` - Lưu HTTP responses
- `SyncOperation` - Lưu pending operations

### Step 3: Create OfflineInterceptor

**`offline_interceptor.dart`:**

```dart
class OfflineInterceptor extends Interceptor {
  // TTL rules map (path pattern → duration)
  static final Map<RegExp, Duration> _ttlRules = {...};
  
  // Paths not to cache
  static final List<RegExp> _noCachePatterns = [...];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    /**
     * TODO:
     * 1. Check network status
     * 2. For GET: Check cache, return if valid
     * 3. For POST/PUT/DELETE:
     *    - Add to sync queue
     *    - If offline: return fake success
     *    - If online: continue to API
     */
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    /**
     * TODO:
     * 1. For GET: Save to cache with TTL
     * 2. For POST/PUT/DELETE: Remove from sync queue (success)
     */
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    /**
     * TODO:
     * 1. If network error + GET request:
     *    - Try cache fallback (even stale)
     * 2. If network error + write request:
     *    - Already in sync queue, return fake success
     */
  }
}
```

### Step 4: Add SyncService (Background Worker)

```dart
class SyncService {
  Timer? _timer;
  
  void startAutoSync() {
    /**
     * TODO:
     * 1. Listen connectivity changes
     * 2. When online: process sync queue
     * 3. Retry failed operations (max 3 times)
     * 4. Remove completed operations
     */
  }
  
  Future<void> processSyncQueue() {
    /**
     * TODO:
     * 1. Get all pending operations from Hive
     * 2. Sort by createdAt (FIFO)
     * 3. Execute one by one
     * 4. Handle conflicts (server wins)
     */
  }
}
```

### Step 5: Update DioClient

```dart
class DioClient {
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    await Hive.openBox('http_cache');
    await Hive.openBox('sync_queue');
    
    // Start sync service
    Get.put(ConnectivityService());
    Get.put(SyncService());
  }
  
  static Dio _createDio() {
    final dio = Dio();
    
    dio.interceptors.addAll([
      _AuthInterceptor(),
      OfflineInterceptor(), // ← Add here
      PrettyDioLogger(),
      _ErrorInterceptor(),
    ]);
    
    return dio;
  }
}
```

---

## 🎨 UI INDICATORS (Optional)

### Sync Status Bar

```dart
// Show at top of app when offline with pending changes
if (syncService.hasPending && !isOnline) {
  Container(
    color: Colors.orange,
    child: Text('Offline: ${pendingCount} changes waiting to sync'),
  )
}
```

### Loading Indicators

```dart
// Show different states
if (response.extra['cached'] == true) {
  Icon(Icons.cached) // From cache
}
if (response.extra['stale'] == true) {
  Icon(Icons.warning) // Stale cache (fallback)
}
```

---

## ⚖️ CONFLICT RESOLUTION

### Strategy: **Server Wins**

Khi sync pending operation mà server trả về conflict:
```dart
// Simple: Always use server data
if (response.statusCode == 409) {
  // Discard local changes
  // Fetch latest from server
  // Update cache
}
```

**Hoặc Complex:** Show conflict dialog cho user chọn.

---

## 🔄 SYNC TRIGGERS

1. **Auto-sync:** When connectivity changes offline → online
2. **Manual sync:** Pull-to-refresh trigger
3. **Periodic sync:** Every 5 minutes if online
4. **On app resume:** When app comes to foreground

---

## 📊 TTL MAPPING (Reuse từ trước)

```dart
static final Map<RegExp, Duration> _ttlRules = {
  // Priority High
  RegExp(r'^/courses'): Duration(days: 1),
  RegExp(r'^/students'): Duration(days: 1),
  RegExp(r'^/groups'): Duration(days: 1),
  RegExp(r'^/assignments'): Duration(hours: 1),
  RegExp(r'^/quizzes'): Duration(hours: 1),
  RegExp(r'^/materials'): Duration(days: 1),
  RegExp(r'^/announcements'): Duration(hours: 6),
  
  // Priority Medium
  RegExp(r'^/.*/tracking'): Duration(minutes: 30),
  RegExp(r'^/dashboard'): Duration(hours: 1),
  
  // Priority Low
  RegExp(r'^/semesters'): Duration(days: 7),
  RegExp(r'^/forum/topics'): Duration(minutes: 5),
};
```

---

## ✅ BENEFITS

1. **Zero Changes** to existing controllers/repositories
2. **Transparent** to developers
3. **Works offline** automatically
4. **Auto-sync** when online
5. **Optimistic UI** - instant feedback

---

## 🚫 LIMITATIONS

1. **Cannot handle complex conflicts** (server wins only)
2. **No offline file uploads** (multipart)
3. **Real-time features** (chat, forum replies) không cache
4. **Large data** có thể làm Hive chậm

---

## 📝 IMPLEMENTATION CHECKLIST

- [ ] Setup Hive dependencies
- [ ] Create `CacheEntry` model + generate
- [ ] Create `SyncOperation` model + generate
- [ ] Create `OfflineInterceptor` with 3 methods
- [ ] Create `SyncService` for background sync
- [ ] Create `ConnectivityService` for network monitoring
- [ ] Update `DioClient.init()` to initialize Hive
- [ ] Add interceptor to Dio
- [ ] Test offline create/update/delete
- [ ] Test auto-sync when back online
- [ ] Add UI indicators (optional)

---

Đây là **high-level guide** không đi sâu vào code. Bạn có thể implement từng piece một, test từng bước. 

Key point: **TẤT CẢ logic ở Dio Interceptor**, repository/controller giữ nguyên 100%. 

Bạn có muốn tôi detail phần nào cụ thể không?