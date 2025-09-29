class ApiEndpoints {
  // Base URL - for development use localhost
  static const String baseUrl = 'http://localhost:3131/api';

  // Authentication endpoints
  static const String instructorLogin = '/auth/instructor/login';
  static const String studentLogin = '/auth/student/login';
  static const String createStudent = '/auth/student/create';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // User management endpoints
  static const String updateProfile = '/auth/profile';
  static const String uploadAvatar = '/auth/avatar';

  // Student management endpoints (instructor only)
  static const String students = '/students';
  static const String studentsBulk = '/students/bulk';
  static const String studentsStatistics = '/students/statistics';
  static const String studentsExport = '/students/export';
  static const String studentsImport = '/students/import';
  static const String studentsImportPreview = '/students/import/preview';
  static const String studentsImportTemplate = '/students/import/template';
  static const String studentsHealth = '/students/health';

  // Dynamic endpoints
  static String updateStudent(String studentId) => '/students/$studentId';
  static String deleteStudent(String studentId) => '/students/$studentId';
  static String resetStudentPassword(String studentId) =>
      '/students/$studentId/reset-password';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String isLoggedIn = 'is_logged_in';
}
