import 'package:classroom_mini/app/core/app_config.dart';
import 'package:classroom_mini/app/core/services/auth_service.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/chat_socket_service.dart';

/// Core binding for essential services that need to be available throughout the app
class CoreBinding {
  Future<void> init() async {
    // Initialize core services that are needed app-wide
    await _initializeStorageService(); // Must be first
    await Future.wait([
      _initializeApiService(),
      _initializeAppConfig(),
    ]);
    // Must be after storage service
    await _initializeAuthService();
  }

  Future<void> _initializeAppConfig() async {
    // AppConfig is now a singleton, no need to register with GetX
    // Just initialize the singleton instance
    AppConfig.instance;
  }

  Future<void> _initializeApiService() async {
    // Initialize ApiService as a singleton
    Get.put<ApiService>(DioClient.apiService, permanent: true);
  }

  Future<void> _initializeStorageService() async {
    // Initialize StorageService asynchronously since it needs SharedPreferences
    final storageService = await StorageService.getInstance();
    Get.put<StorageService>(storageService, permanent: true);
  }

  Future<void> _initializeAuthService() async {
    // Initialize ChatSocketService first (permanent singleton)
    Get.put<ChatSocketService>(ChatSocketService(), permanent: true);
    
    // Initialize AuthService asynchronously
    final authService = await AuthService().init();
    Get.put<AuthService>(authService, permanent: true);
  }
}

/// Extension to easily get core services
extension CoreServices on GetInterface {
  ApiService get apiService => Get.find<ApiService>();
  StorageService get storageService => Get.find<StorageService>();
  AuthService get authService => Get.find<AuthService>();
}
