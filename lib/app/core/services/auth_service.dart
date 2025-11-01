import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/chat_socket_service.dart';
import '../../routes/app_routes.dart';

class AuthService extends GetxService {
  final StorageService _storageService = Get.find();

  final RxBool isAuthenticated = false.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);

  Future<AuthService> init() async {
    print('[AuthService] Initializing...');
    final token = await _storageService.getAccessToken();
    print(
        '[AuthService] Token from storage: ${token != null ? "Exists" : "Null"}');

    if (token != null) {
      final userModel =
          await _storageService.getUserData(); // This returns UserModel?
      print(
          '[AuthService] User data from storage: ${userModel != null ? "Exists" : "Null"}');

      if (userModel != null) {
        user.value = userModel;
        isAuthenticated.value = true;
        print('[AuthService] User authenticated: true');
        
        // Connect to chat socket if user is authenticated
        try {
          if (Get.isRegistered<ChatSocketService>()) {
            final chatSocketService = Get.find<ChatSocketService>();
            await chatSocketService.connect(token);
          }
        } catch (e) {
          print('[AuthService] Failed to connect chat socket: $e');
          // Try to reconnect with fresh token if connect fails
          try {
            if (Get.isRegistered<ChatSocketService>()) {
              final chatSocketService = Get.find<ChatSocketService>();
              await chatSocketService.connect(null); // Will fetch token from storage
            }
          } catch (e2) {
            print('[AuthService] Failed to reconnect chat socket: $e2');
          }
        }
      } else {
        // Has token but no valid UserModel? This is an inconsistent state.
        print(
            '[AuthService] Inconsistent state: Token exists but no valid UserModel. Clearing session.');
        await _storageService.clearAll();
        isAuthenticated.value = false;
        user.value = null;
        print('[AuthService] User authenticated: false (cleared session)');
      }
    } else {
      isAuthenticated.value = false;
      user.value = null;
      print('[AuthService] User authenticated: false (no token)');
    }
    print(
        '[AuthService] Initialization complete. isAuthenticated: ${isAuthenticated.value}');
    return this;
  }

  void login(dynamic loggedInUser) {
    if (loggedInUser is UserModel) {
      user.value = loggedInUser;
      isAuthenticated.value = true;
    } else if (loggedInUser is Map<String, dynamic>) {
      user.value = UserModel.fromJson(loggedInUser);
      isAuthenticated.value = true;
    } else {
      // Handle unexpected type, perhaps log an error
      print("AuthService Error: Could not parse user data on login.");
      // Do not set isAuthenticated to true if user data is invalid
    }
  }

  Future<void> logout() async {
    isAuthenticated.value = false;
    user.value = null;
    
    // Disconnect chat socket
    try {
      if (Get.isRegistered<ChatSocketService>()) {
        final chatSocketService = Get.find<ChatSocketService>();
        chatSocketService.disconnect();
      }
    } catch (e) {
      print('Error disconnecting socket: $e');
    }
    
    // Also clear tokens from storage
    await _storageService.clearAll();
    // Navigate to login after logout
    Get.offAllNamed(Routes.LOGIN);
  }
}
