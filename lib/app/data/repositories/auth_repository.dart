import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/request_models.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final List<String>? errors;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errors,
  });

  factory AuthResult.success({
    UserModel? user,
    String? accessToken,
    String? refreshToken,
    String? message,
  }) {
    return AuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      message: message,
    );
  }

  factory AuthResult.failure({
    String? message,
    List<String>? errors,
  }) {
    return AuthResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Instructor login
  Future<AuthResult> instructorLogin(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _apiService.instructorLogin(request);

      if (response.success && response.data != null) {
        // Save tokens and user data
        await _storageService.saveTokens(
          response.data!.tokens!.accessToken,
          response.data!.tokens!.refreshToken,
        );
        if (response.data!.user != null) {
          await _storageService.saveUserData(response.data!.user!);
        }

        return AuthResult.success(
          user: response.data!.user,
          accessToken: response.data!.tokens!.accessToken,
          refreshToken: response.data!.tokens!.refreshToken,
          message: 'Login successful',
        );
      } else {
        return AuthResult.failure(
          message: response.message ?? 'Login failed',
          errors: response.errors,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Student login
  Future<AuthResult> studentLogin(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _apiService.studentLogin(request);

      if (response.success && response.data != null) {
        // Save tokens and user data
        await _storageService.saveTokens(
          response.data!.tokens!.accessToken,
          response.data!.tokens!.refreshToken,
        );
        if (response.data!.user != null) {
          await _storageService.saveUserData(response.data!.user!);
        }

        return AuthResult.success(
          user: response.data!.user,
          accessToken: response.data!.tokens!.accessToken,
          refreshToken: response.data!.tokens!.refreshToken,
          message: 'Login successful',
        );
      } else {
        return AuthResult.failure(
          message: response.message ?? 'Login failed',
          errors: response.errors,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Generic login method that tries both instructor and student
  Future<AuthResult> login(String username, String password) async {
    // First try instructor login if username is 'admin'
    if (username.toLowerCase() == 'admin') {
      return await instructorLogin(username, password);
    } else {
      // Try student login
      return await studentLogin(username, password);
    }
  }

  // Create student account (instructor only)
  Future<AuthResult> createStudent({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    try {
      final request = CreateStudentRequest(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
      );

      final response = await _apiService.createStudent(request);

      if (response.success && response.data != null) {
        return AuthResult.success(
          user: response.data!.user,
          message: 'Student account created successfully',
        );
      } else {
        return AuthResult.failure(
          message: response.message ?? 'Failed to create student account',
          errors: response.errors,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error occurred. Please try again.',
      );
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      // First try to get from local storage
      final localUser = await _storageService.getUserData();
      if (localUser != null) {
        return localUser;
      }

      // If not in storage, try to fetch from API
      final user = await _apiService.getCurrentUser();
      await _storageService.saveUserData(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout API to invalidate server-side session
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      // Clear local storage
      await _storageService.clearAll();
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final hasToken = await _storageService.getAccessToken() != null;
    final isLoggedIn = await _storageService.isLoggedIn();
    return hasToken && isLoggedIn;
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiService.refreshToken({
        'refreshToken': refreshToken,
      });

      if (response.success && response.data != null) {
        await _storageService.saveTokens(
          response.data!.tokens!.accessToken,
          response.data!.tokens!.refreshToken,
        );
        if (response.data!.user != null) {
          await _storageService.saveUserData(response.data!.user!);
        }
        return true;
      }
    } catch (e) {
      // Refresh failed
    }

    return false;
  }

  // Update profile
  Future<AuthResult> updateProfile(UpdateProfileRequest profileData) async {
    try {
      final updatedUser = await _apiService.updateProfile(profileData);
      await _storageService.saveUserData(updatedUser);

      return AuthResult.success(
        user: updatedUser,
        message: 'Profile updated successfully',
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Failed to update profile. Please try again.',
      );
    }
  }

  // Upload avatar (placeholder - will be implemented later)
  Future<AuthResult> uploadAvatar(String imagePath) async {
    return AuthResult.failure(
      message: 'Avatar upload feature will be implemented in the next phase',
    );
  }
}
