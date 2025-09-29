import 'package:classroom_mini/app/modules/quiz/bindings/quiz_binding.dart';
import 'package:classroom_mini/app/modules/quiz/views/quiz_list_view.dart';
import 'package:classroom_mini/app/modules/quiz/views/quiz_create_view.dart';
import 'package:classroom_mini/app/modules/quiz/views/quiz_edit_view.dart';
import 'package:classroom_mini/app/modules/quiz/views/quiz_detail_view.dart';
import 'package:classroom_mini/app/modules/home/bindings/home_binding.dart';
import 'package:classroom_mini/app/modules/home/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/auth/views/responsive_login_page.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/core_management/views/responsive_core_management_page.dart';
import '../modules/core_management/bindings/core_management_binding.dart';
import '../modules/dashboard/views/responsive_dashboard_page.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/student_management/views/responsive_student_management_page.dart';
import '../modules/student_management/views/student_detail_page.dart';
import '../modules/student_management/bindings/student_management_binding.dart';

import 'package:responsive_framework/responsive_framework.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import '../modules/assignments/views/mobile/assignment_list_view.dart';
import '../modules/assignments/views/desktop/assignment_list_view.dart';
import '../modules/assignments/views/responsive/assignment_pages.dart';

class AppPages {
  static const String INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),

    // Login Page
    GetPage(
      name: Routes.LOGIN,
      page: () => const ResponsiveLoginPage(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: Routes.STUDENT_DETAILS,
      page: () {
        final id = Get.parameters['id'] ?? '';
        return StudentDetailPage(studentId: id);
      },
      binding: StudentManagementBinding(),
    ),

    GetPage(
      name: Routes.CREATE_STUDENT,
      page: () => const PlaceholderPage(title: 'Create Student'),
      binding: StudentManagementBinding(),
    ),

    GetPage(
      name: Routes.EDIT_STUDENT,
      page: () => const PlaceholderPage(title: 'Edit Student'),
      binding: StudentManagementBinding(),
    ),

    // Profile Routes
    GetPage(
      name: Routes.PROFILE,
      page: () => const PlaceholderPage(title: 'Profile'),
    ),

    GetPage(
      name: Routes.EDIT_PROFILE,
      page: () => const PlaceholderPage(title: 'Edit Profile'),
    ),

    // Settings
    GetPage(
      name: Routes.SETTINGS,
      page: () => const PlaceholderPage(title: 'Settings'),
    ),

    // Import/Export Routes
    GetPage(
      name: Routes.IMPORT_STUDENTS,
      page: () => const PlaceholderPage(title: 'Import Students'),
    ),

    GetPage(
      name: Routes.EXPORT_STUDENTS,
      page: () => const PlaceholderPage(title: 'Export Students'),
    ),

    // Statistics
    GetPage(
      name: Routes.STATISTICS,
      page: () => const PlaceholderPage(title: 'Statistics'),
    ),

    // Core Management Routes
    GetPage(
      name: Routes.CORE_MANAGEMENT,
      page: () => const ResponsiveCoreManagementPage(),
      binding: CoreManagementBinding(),
    ),

    // Assignments (centralized)
    GetPage(
      name: Routes.ASSIGNMENTS_LIST,
      page: () => _getResponsiveAssignmentList(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.ASSIGNMENTS_CREATE,
      page: () => const ResponsiveAssignmentCreatePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ASSIGNMENTS_EDIT,
      page: () {
        final assignment = Get.arguments as Assignment?;
        if (assignment == null) {
          return const Scaffold(
            body: Center(child: Text('Assignment not found')),
          );
        }
        return ResponsiveAssignmentEditPage(assignment: assignment);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ASSIGNMENTS_DETAIL,
      page: () {
        final assignment = Get.arguments as Assignment?;
        if (assignment == null) {
          return const Scaffold(
            body: Center(child: Text('Assignment not found')),
          );
        }
        return ResponsiveAssignmentDetailPage(assignment: assignment);
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ASSIGNMENTS_STUDENT_LIST,
      page: () => const MobileStudentAssignmentListView(),
      transition: Transition.fadeIn,
    ),

    // Quiz Routes
    GetPage(
      name: Routes.QUIZZES_LIST,
      page: () => const QuizListView(),
      binding: QuizBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.QUIZZES_CREATE,
      page: () => const QuizCreateView(),
      binding: QuizBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.QUIZZES_EDIT,
      page: () {
        final quizId = Get.parameters['id'] ?? '';
        return QuizEditView(quizId: quizId);
      },
      binding: QuizBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.QUIZZES_DETAIL,
      page: () {
        final quizId = Get.parameters['id'] ?? '';
        return QuizDetailView(quizId: quizId);
      },
      binding: QuizBinding(),
      transition: Transition.rightToLeft,
    ),
  ];

  static Widget _getResponsiveAssignmentList() {
    return Builder(
      builder: (context) {
        if (ResponsiveBreakpoints.of(context).isDesktop) {
          return const DesktopAssignmentListView();
        } else if (ResponsiveBreakpoints.of(context).isTablet) {
          return const MobileAssignmentListView();
        } else {
          return const MobileAssignmentListView();
        }
      },
    );
  }
}

// Placeholder page for routes that haven't been implemented yet
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This page is under construction',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
