import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/chat_socket_service.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  // Form
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // State
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final errorMessage = ''.obs;

  // Services
  late final AuthRepository _authRepository;
  final AuthService _authService = Get.find();

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  void _initializeServices() {
    try {
      final apiService = Get.find<ApiService>();
      final storageService = Get.find<StorageService>();
      _authRepository = AuthRepository(
        apiService: apiService,
        storageService: storageService,
      );
    } catch (e) {
      if (!isClosed) {
        errorMessage.value = 'Không thể khởi tạo dịch vụ. Vui lòng thử lại.';
      }
    }
  }

  void togglePasswordVisibility() {
    if (!isClosed) {
      isPasswordVisible.value = !isPasswordVisible.value;
    }
  }

  void clearError() {
    if (!isClosed) {
      errorMessage.value = '';
    }
  }

  Future<void> login() async {
    // Check if controller is still mounted
    if (isClosed) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    clearError();
    isLoading.value = true;

    try {
      final result = await _authRepository.instructorLogin(
        usernameController.text.trim(),
        passwordController.text,
      );

      if (result.success) {
        // Show success message
        Get.snackbar(
          'Đăng nhập thành công',
          result.message ?? 'Chào mừng bạn quay trở lại!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );

        // Update the reactive authentication state
        _authService.login(result.user);

        // Connect to chat socket after login
        if (result.accessToken != null) {
          try {
            final chatSocketService = Get.isRegistered<ChatSocketService>()
                ? Get.find<ChatSocketService>()
                : null;
            if (chatSocketService != null) {
              await chatSocketService.connect(result.accessToken!);
            }
          } catch (e) {
            debugPrint('Failed to connect chat socket: $e');
          }
        }

        await _navigateAfterLogin(result.user);
      } else {
        if (!isClosed) {
          errorMessage.value = result.message ?? 'Đăng nhập thất bại';
        }
      }
    } catch (e) {
      if (!isClosed) {
        errorMessage.value = 'Có lỗi xảy ra. Vui lòng thử lại.';
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _navigateAfterLogin(dynamic user) async {
    try {
      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Debug: Print user info
      debugPrint('User role: ${user?.role}');
      debugPrint('User isInstructor: ${user?.isInstructor}');

      // Logic from RouteController is now here directly.
      debugPrint('Redirecting to home after login...');
      Get.offAllNamed(Routes.HOME, arguments: {'justLoggedIn': true});
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback navigation
      Get.offAllNamed(Routes.HOME, arguments: {'justLoggedIn': true});
    }
  }

  // Quick login for testing (admin/admin)
  Future<void> quickLogin() async {
    // Check if controller is still mounted
    if (!isClosed) {
      usernameController.text = 'admin';
      passwordController.text = 'admin';
      await login();
    }
  }

  // Quick student login for testing (sv010/sv010)
  Future<void> quickStudentLogin() async {
    // Check if controller is still mounted
    if (isClosed) return;

    clearError();
    isLoading.value = true;

    try {
      final result = await _authRepository.studentLogin('sv010', 'sv010');

      if (result.success) {
        // Show success message
        Get.snackbar(
          'Đăng nhập thành công',
          result.message ?? 'Chào mừng bạn quay trở lại!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );

        // Update the reactive authentication state
        _authService.login(result.user);

        // Connect to chat socket after login
        if (result.accessToken != null) {
          try {
            final chatSocketService = Get.isRegistered<ChatSocketService>()
                ? Get.find<ChatSocketService>()
                : null;
            if (chatSocketService != null) {
              await chatSocketService.connect(result.accessToken!);
            }
          } catch (e) {
            debugPrint('Failed to connect chat socket: $e');
          }
        }

        await _navigateAfterLogin(result.user);
      } else {
        if (!isClosed) {
          errorMessage.value = result.message ?? 'Đăng nhập thất bại';
        }
      }
    } catch (e) {
      if (!isClosed) {
        errorMessage.value = 'Có lỗi xảy ra. Vui lòng thử lại.';
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
