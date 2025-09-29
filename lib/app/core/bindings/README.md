# Core Binding Architecture

## 📋 Overview

Cấu trúc binding mới được thiết kế để quản lý dependencies một cách hiệu quả và tránh lỗi "Service not found".

## 🏗️ Architecture

### **CoreBinding** - Core Services Management
- **Location:** `lib/app/core/bindings/core_binding.dart`
- **Purpose:** Quản lý các core services cần thiết cho toàn bộ app
- **Services:**
  - `ApiService` (tag: 'core_api_service')
  - `StorageService` (tag: 'core_storage_service')

### **AuthBinding** - Authentication Module
- **Location:** `lib/app/modules/auth/bindings/auth_binding.dart`
- **Purpose:** Quản lý dependencies cho authentication module
- **Dependencies:**
  - `AuthRepository`
  - `AuthController`
- **Requires:** Core services phải được khởi tạo trước

### **InitialBinding** - App Startup
- **Location:** `lib/app/modules/auth/bindings/auth_binding.dart`
- **Purpose:** Binding chính cho app startup
- **Flow:** CoreBinding → AuthBinding

## 🔧 Usage Pattern

### **1. App Startup (main.dart)**
```dart
GetMaterialApp(
  initialBinding: InitialBinding(),
  // ...
)
```

### **2. Module Binding**
```dart
class ModuleBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure core services are ready
    if (!Get.isRegistered<ApiService>(tag: 'core_api_service')) {
      CoreBinding().dependencies();
    }
    
    // Initialize module-specific dependencies
    Get.lazyPut<ModuleController>(() => ModuleController());
  }
}
```

### **3. Service Access**
```dart
// Using extension
final apiService = Get.apiService;
final storageService = Get.storageService;

// Or using tags
final apiService = Get.find<ApiService>(tag: 'core_api_service');
final storageService = Get.find<StorageService>(tag: 'core_storage_service');
```

## ✅ Benefits

1. **Separation of Concerns:** Core services tách biệt khỏi module-specific services
2. **Early Initialization:** Core services được khởi tạo sớm và available app-wide
3. **Tag-based Management:** Tránh conflicts khi có multiple instances
4. **Lazy Loading:** Module-specific services chỉ load khi cần
5. **Error Prevention:** Tránh lỗi "Service not found"

## 🚀 Future Modules

Khi thêm modules mới (Course, Assignment, etc.), follow pattern:

```dart
class CourseBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure core services
    if (!Get.isRegistered<ApiService>(tag: 'core_api_service')) {
      CoreBinding().dependencies();
    }
    
    // Initialize course-specific services
    Get.lazyPut<CourseRepository>(() => CourseRepository(
      apiService: Get.find<ApiService>(tag: 'core_api_service'),
    ));
    
    Get.lazyPut<CourseController>(() => CourseController());
  }
}
```

## 🔍 Troubleshooting

### **"Service not found" Error**
1. Check if service is registered with correct tag
2. Ensure CoreBinding is called before module binding
3. Use `Get.isRegistered<ServiceType>(tag: 'tag_name')` to check

### **Async Service Issues**
- `StorageService` is async, use `Get.putAsync()` in CoreBinding
- Other services can use `Get.put()` for synchronous initialization

---

*📅 Created: September 23, 2025*  
*🏗️ Architecture: GetX Dependency Injection*  
*🎯 Purpose: Clean Service Management*