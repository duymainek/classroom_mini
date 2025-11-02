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
import '../modules/student_management/views/responsive_student_management_page.dart';
import '../modules/student_management/views/create_student_page.dart';
import '../modules/student_management/bindings/student_management_binding.dart';

import 'package:responsive_framework/responsive_framework.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import '../modules/assignments/views/mobile/assignment_list_view.dart';
import '../modules/assignments/views/responsive/assignment_pages.dart';
import '../modules/assignments/bindings/assignment_binding.dart';
import '../modules/assignments/views/mobile/assignment_tracking_page.dart';

// Announcement imports
import '../modules/announcements/bindings/announcement_binding.dart';
import '../modules/announcements/views/mobile/announcement_list_view.dart';
import '../modules/announcements/views/mobile/announcement_create_view.dart';
import '../modules/announcements/views/mobile/announcement_detail_view.dart';
import '../modules/announcements/views/mobile/announcement_tracking_view.dart';
import '../modules/announcements/views/mobile/announcement_file_tracking_view.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';

// Material imports
import '../modules/materials/bindings/material_binding.dart';
import '../modules/materials/views/mobile/material_list_view.dart';
import '../modules/materials/views/mobile/material_detail_view.dart';
import '../modules/materials/widgets/material_form.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;

// Forum imports
import '../modules/forum/bindings/forum_binding.dart';
import '../modules/forum/views/forum_list_view.dart';
import '../modules/forum/views/forum_detail_view.dart';
import '../modules/chat/views/chat_list_view.dart';
import '../modules/chat/views/chat_room_view.dart';
import '../modules/chat/views/new_chat_view.dart';
import '../modules/chat/bindings/chat_binding.dart';

// Profile imports
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/sync_queue_view.dart';

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

    // Student Management Routes
    GetPage(
      name: Routes.STUDENTS_LIST,
      page: () => const ResponsiveStudentManagementPage(),
      binding: StudentManagementBinding(),
    ),

    GetPage(
      name: Routes.CREATE_STUDENT,
      page: () => const CreateStudentPage(),
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
    GetPage(
      name: Routes.SYNC_QUEUE,
      page: () => const SyncQueueView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
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
      binding: AssignmentBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.ASSIGNMENTS_CREATE,
      page: () => const ResponsiveAssignmentCreatePage(),
      binding: AssignmentBinding(),
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
      binding: AssignmentBinding(),
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
      binding: AssignmentBinding(),
      transition: Transition.rightToLeft,
    ),

    // Assignment Tracking Route
    GetPage(
      name: Routes.ASSIGNMENTS_TRACKING,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final assignmentId = args['assignmentId'] as String? ?? '';
        final assignmentTitle =
            args['assignmentTitle'] as String? ?? 'Theo dõi nộp bài';
        return AssignmentTrackingPage(
          assignmentId: assignmentId,
          assignmentTitle: assignmentTitle,
        );
      },
      binding: AssignmentBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: Routes.ASSIGNMENTS_STUDENT_LIST,
      page: () => const MobileStudentAssignmentListView(),
      binding: AssignmentBinding(),
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

    // Announcement Routes
    GetPage(
      name: Routes.ANNOUNCEMENTS_LIST,
      page: () => const MobileAnnouncementListView(),
      binding: AnnouncementBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS_CREATE,
      page: () => const MobileAnnouncementCreateView(),
      binding: AnnouncementBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS_EDIT,
      page: () {
        final announcement = Get.arguments as Announcement?;
        if (announcement == null) {
          return const Scaffold(
            body: Center(child: Text('Thông báo không tìm thấy')),
          );
        }
        return const PlaceholderPage(title: 'Chỉnh sửa thông báo');
      },
      binding: AnnouncementBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS_DETAIL,
      page: () {
        final announcement = Get.arguments as Announcement?;
        if (announcement == null) {
          return const Scaffold(
            body: Center(child: Text('Thông báo không tìm thấy')),
          );
        }
        return MobileAnnouncementDetailView(announcement: announcement);
      },
      binding: AnnouncementBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS_TRACKING,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final announcementId = args['announcementId'] as String? ?? '';
        final announcementTitle =
            args['announcementTitle'] as String? ?? 'Theo dõi thông báo';
        return MobileAnnouncementTrackingView(
          announcementId: announcementId,
          announcementTitle: announcementTitle,
        );
      },
      binding: AnnouncementBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS_FILE_TRACKING,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final announcementId = args['announcementId'] as String? ?? '';
        final announcementTitle =
            args['announcementTitle'] as String? ?? 'Theo dõi file';
        return MobileAnnouncementFileTrackingView(
          announcementId: announcementId,
          announcementTitle: announcementTitle,
        );
      },
      binding: AnnouncementBinding(),
      transition: Transition.rightToLeft,
    ),

    // Material Routes
    GetPage(
      name: Routes.MATERIALS_LIST,
      page: () => const MaterialListView(),
      binding: MaterialBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.MATERIALS_CREATE,
      page: () => const MaterialForm(),
      binding: MaterialBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.MATERIALS_EDIT,
      page: () {
        final material = Get.arguments as material_resp.Material?;
        if (material == null) {
          return const Scaffold(
            body: Center(child: Text('Tài liệu không tìm thấy')),
          );
        }
        return MaterialForm(material: material, isEditing: true);
      },
      binding: MaterialBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.MATERIALS_DETAIL,
      page: () {
        final materialId = Get.parameters['id'] ?? '';
        if (materialId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('ID tài liệu không hợp lệ')),
          );
        }
        return MaterialDetailView(materialId: materialId);
      },
      binding: MaterialBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.MATERIALS_TRACKING,
      page: () {
        return const PlaceholderPage(title: 'Theo dõi tài liệu');
      },
      binding: MaterialBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.MATERIALS_FILE_TRACKING,
      page: () {
        return const PlaceholderPage(title: 'Theo dõi file tài liệu');
      },
      binding: MaterialBinding(),
      transition: Transition.rightToLeft,
    ),

    // Forum Routes
    GetPage(
      name: Routes.FORUM_LIST,
      page: () => const ForumListView(),
      binding: ForumBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.FORUM_DETAIL,
      page: () => const ForumDetailView(),
      binding: ForumBinding(),
      transition: Transition.rightToLeft,
    ),

    // Chat Routes
    GetPage(
      name: Routes.CHAT_LIST,
      page: () => const ChatListView(),
      binding: ChatBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.CHAT_ROOM,
      page: () => const ChatRoomView(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.CHAT_NEW,
      page: () => const NewChatView(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),
  ];

  static Widget _getResponsiveAssignmentList() {
    return Builder(
      builder: (context) {
        if (ResponsiveBreakpoints.of(context).isDesktop) {
          return const MobileAssignmentListView();
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
