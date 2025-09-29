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
  static const String ASSIGNMENTS_STUDENT_LIST = '/assignments/student';

  // Quiz routes
  static const String QUIZZES_LIST = '/quizzes';
  static const String QUIZZES_CREATE = '/quizzes/create';
  static const String QUIZZES_EDIT = '/quizzes/edit';
  static const String QUIZZES_DETAIL = '/quizzes/detail';
}
