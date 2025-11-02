/// Application routes constants
class Routes {
  static const String HOME = '/';

  // Authentication routes
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';

  // Student management routes
  static const String STUDENTS_LIST = '/students-list';
  static const String STUDENT_DETAILS = '/student-details';
  static const String CREATE_STUDENT = '/create-student';
  static const String EDIT_STUDENT = '/edit-student';

  // Profile routes
  static const String PROFILE = '/profile';
  static const String EDIT_PROFILE = '/edit-profile';
  static const String SYNC_QUEUE = '/sync-queue';

  // Settings routes
  static const String SETTINGS = '/settings';

  // Import/Export routes
  static const String IMPORT_STUDENTS = '/import-students';
  static const String EXPORT_STUDENTS = '/export-students';

  // Statistics routes
  static const String STATISTICS = '/statistics';

  // Core management routes
  static const String CORE_MANAGEMENT = '/core-management';
  static const String SEMESTERS = '/semesters';
  static const String COURSES = '/courses';
  static const String GROUPS = '/groups';

  // Assignment routes (centralized)
  static const String ASSIGNMENTS_LIST = '/assignments';
  static const String ASSIGNMENTS_CREATE = '/assignments/create';
  static const String ASSIGNMENTS_EDIT = '/assignments/edit';
  static const String ASSIGNMENTS_DETAIL = '/assignments/detail';
  static const String ASSIGNMENTS_TRACKING = '/assignments/tracking';
  static const String ASSIGNMENTS_STUDENT_LIST = '/assignments/student';

  // Quiz routes
  static const String QUIZZES_LIST = '/quizzes';
  static const String QUIZZES_CREATE = '/quizzes/create';
  static const String QUIZZES_EDIT = '/quizzes/edit';
  static const String QUIZZES_DETAIL = '/quizzes/detail';

  // Announcement routes
  static const String ANNOUNCEMENTS_LIST = '/announcements';
  static const String ANNOUNCEMENTS_CREATE = '/announcements/create';
  static const String ANNOUNCEMENTS_EDIT = '/announcements/edit';
  static const String ANNOUNCEMENTS_DETAIL = '/announcements/detail';
  static const String ANNOUNCEMENTS_TRACKING = '/announcements/tracking';
  static const String ANNOUNCEMENTS_FILE_TRACKING =
      '/announcements/file-tracking';

  // Material routes
  static const String MATERIALS_LIST = '/materials';
  static const String MATERIALS_CREATE = '/materials/create';
  static const String MATERIALS_EDIT = '/materials/edit';
  static const String MATERIALS_DETAIL = '/materials/detail/:id';
  static const String MATERIALS_TRACKING = '/materials/tracking';
  static const String MATERIALS_FILE_TRACKING = '/materials/file-tracking';

  // Forum routes
  static const String FORUM_LIST = '/forum';
  static const String FORUM_DETAIL = '/forum/detail/:id';

  // Chat routes
  static const String CHAT_LIST = '/chat';
  static const String CHAT_ROOM = '/chat/room';
  static const String CHAT_NEW = '/chat/new';
}
