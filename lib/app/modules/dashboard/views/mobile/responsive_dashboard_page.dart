import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';

import '../shared/charts/student_progress_chart.dart';
import '../shared/charts/instructor_kpi_chart.dart';
import '../shared/charts/content_distribution_chart.dart';
import 'package:classroom_mini/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/semester_selector_widget.dart';
import '../../../../routes/app_routes.dart';

class ResponsiveDashboardPage extends StatelessWidget {
  const ResponsiveDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.getDashboardTitle())),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshDashboard,
          ),
        ],
      ),
      body: Obx(() {
        debugPrint('🖥️ [DashboardView] Rebuilding UI');
        debugPrint('   - isLoading: ${controller.isLoading.value}');
        debugPrint('   - isRefreshing: ${controller.isRefreshing.value}');
        debugPrint('   - isInstructor: ${controller.isInstructorRx.value}');
        debugPrint(
            '   - instructorDashboardData: ${controller.instructorDashboardData.value != null}');
        debugPrint(
            '   - studentDashboardData: ${controller.studentDashboardData.value != null}');
        debugPrint('   - errorMessage: "${controller.errorMessage.value}"');

        if (controller.instructorDashboardData.value != null) {
          final data = controller.instructorDashboardData.value!;
          debugPrint('   📊 Instructor Data:');
          debugPrint('      - stats.courses: ${data.statistics.totalCourses}');
          debugPrint(
              '      - stats.students: ${data.statistics.totalStudents}');
          debugPrint('      - recentActivity: ${data.recentActivity.length}');
        }

        if (controller.studentDashboardData.value != null) {
          final data = controller.studentDashboardData.value!;
          debugPrint('   📊 Student Data:');
          debugPrint('      - enrolledCourses: ${data.enrolledCourses.length}');
          debugPrint(
              '      - upcomingAssignments: ${data.upcomingAssignments.length}');
        }

        if (controller.isLoading.value &&
            controller.instructorDashboardData.value == null &&
            controller.studentDashboardData.value == null) {
          debugPrint('🔄 [DashboardView] Showing LOADING state');
          return _buildLoadingState(context);
        }

        if (controller.errorMessage.value.isNotEmpty) {
          debugPrint(
              '❌ [DashboardView] Showing ERROR state: ${controller.errorMessage.value}');
          return _buildErrorState(context, controller);
        }

        debugPrint('✅ [DashboardView] Showing CONTENT state');

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Welcome header
              _buildWelcomeHeader(context, controller),

              // Quick actions for instructors
              if (controller.isInstructorRx.value) ...[
                _buildQuickActions(context, controller),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildInstructorDashboard(context, controller),
                      ],
                    ),
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStudentDashboard(context, controller),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// Enhanced loading state with skeleton
  Widget _buildLoadingState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                5,
                (index) => Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Enhanced error state with retry options
  Widget _buildErrorState(
      BuildContext context, DashboardController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể tải dữ liệu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.refreshDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.clearError();
                    controller.loadDashboard();
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Về trang chủ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Welcome header with user info
  Widget _buildWelcomeHeader(
      BuildContext context, DashboardController controller) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    controller.isInstructorRx.value
                        ? Icons.school
                        : Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isInstructorRx.value
                            ? 'Giảng viên'
                            : 'Sinh viên',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chào mừng trở lại! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Semester selector integrated into welcome header
            const SemesterSelectorWidget(),
          ],
        ),
      ),
    );
  }

  /// Quick actions for instructors
  Widget _buildQuickActions(
      BuildContext context, DashboardController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác nhanh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Tạo mới: Khóa/ Nhóm/ Kỳ',
                    Icons.add_circle_outline,
                    Colors.blue,
                    () {
                      Get.toNamed(Routes.CORE_MANAGEMENT);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Quản lý sinh viên',
                    Icons.people_outline,
                    Colors.green,
                    () {
                      Get.toNamed(Routes.STUDENTS_LIST);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Tất cả\n ',
                    Icons.apps_outlined,
                    Colors.purple,
                    () {
                      _showAllFeaturesBottomSheet(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAllFeaturesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.apps_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tất cả tính năng',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Features grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildFeatureCard(
                      context,
                      'Quản lý Quiz',
                      Icons.quiz_outlined,
                      Colors.red,
                      () {
                        Navigator.of(context).pop();
                        Get.toNamed(Routes.QUIZZES_LIST);
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Thông báo',
                      Icons.announcement_outlined,
                      Colors.purple,
                      () {
                        Navigator.of(context).pop();
                        Get.toNamed(Routes.ANNOUNCEMENTS_LIST);
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Tài liệu',
                      Icons.folder_outlined,
                      Colors.teal,
                      () {
                        Navigator.of(context).pop();
                        Get.toNamed(Routes.MATERIALS_LIST);
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Danh sách bài tập',
                      Icons.assignment_outlined,
                      Colors.orange,
                      () {
                        Navigator.of(context).pop();
                        Get.toNamed(Routes.ASSIGNMENTS_LIST);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorDashboard(
      BuildContext context, DashboardController controller) {
    final data = controller.instructorDashboardData.value;
    debugPrint('🎨 [DashboardView] _buildInstructorDashboard called');
    debugPrint('   - data: ${data != null}');

    if (data == null) {
      debugPrint(
          '   ⚠️ [DashboardView] Instructor data is NULL - showing empty state');
      return _buildEmptyState(
        context,
        'Không có dữ liệu',
        'Chưa có dữ liệu dashboard để hiển thị',
        Icons.dashboard_outlined,
      );
    }

    debugPrint('   ✅ [DashboardView] Instructor data exists - showing content');
    debugPrint(
        '      - Stats: courses=${data.statistics.totalCourses}, students=${data.statistics.totalStudents}');
    debugPrint('      - Recent activity: ${data.recentActivity.length} items');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview combined section: stats + chart
        _buildSectionHeader(context, 'Tổng quan', Icons.analytics_outlined),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                InstructorKPIChart(stats: data.statistics),
                const SizedBox(height: 16),
                ContentDistributionChart(stats: data.statistics),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Recent activity with better mobile design
        if (data.recentActivity.isNotEmpty) ...[
          _buildSectionHeader(context, 'Hoạt động gần đây', Icons.history),
          const SizedBox(height: 16),
          _buildRecentActivity(context, data.recentActivity),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(
      BuildContext context, DashboardController controller) {
    return Obx(() {
      final stats = controller.instructorDashboardData.value?.statistics;
      if (stats == null) return const SizedBox.shrink();

      return Column(
        children: [
          // First row - 2 cards
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Khóa học',
                  stats.totalCourses.toString(),
                  Icons.book_outlined,
                  Colors.blue,
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Nhóm học',
                  stats.totalGroups.toString(),
                  Icons.group_outlined,
                  Colors.green,
                  null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row - 3 cards
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Sinh viên',
                  stats.totalStudents.toString(),
                  Icons.people_outlined,
                  Colors.orange,
                  null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Bài tập',
                  stats.totalAssignments.toString(),
                  Icons.assignment_outlined,
                  Colors.purple,
                  null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Quiz',
                  stats.totalQuizzes.toString(),
                  Icons.quiz_outlined,
                  Colors.red,
                  null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Third row - 2 cards for announcements and forum
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Thông báo',
                  stats.totalAnnouncements.toString(),
                  Icons.announcement_outlined,
                  Colors.teal,
                  null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStatCard(
                  context,
                  'Tài liệu',
                  '0',
                  Icons.folder_outlined,
                  Colors.teal,
                  () {
                    Get.toNamed(Routes.MATERIALS_LIST);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMobileStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  Widget _buildStudentDashboard(
      BuildContext context, DashboardController controller) {
    final data = controller.studentDashboardData.value;
    debugPrint('🎨 [DashboardView] _buildStudentDashboard called');
    debugPrint('   - data: ${data != null}');

    if (data == null) {
      debugPrint(
          '   ⚠️ [DashboardView] Student data is NULL - showing empty state');
      return _buildEmptyState(
        context,
        'Không có dữ liệu',
        'Chưa có dữ liệu dashboard để hiển thị',
        Icons.dashboard_outlined,
      );
    }

    debugPrint('   ✅ [DashboardView] Student data exists - showing content');
    debugPrint('      - Enrolled courses: ${data.enrolledCourses.length}');
    debugPrint(
        '      - Upcoming assignments: ${data.upcomingAssignments.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enrolled courses with improved design
        _buildSectionHeader(context, 'Khóa học của tôi', Icons.school_outlined),
        const SizedBox(height: 16),
        if (data.enrolledCourses.isEmpty)
          _buildEmptyState(
            context,
            'Chưa có khóa học',
            'Bạn chưa được đăng ký vào khóa học nào trong học kỳ này',
            Icons.school_outlined,
            actionText: 'Tìm khóa học',
            onAction: () {
              Get.toNamed(Routes.CORE_MANAGEMENT);
            },
          )
        else
          _buildCoursesList(context, data.enrolledCourses),

        const SizedBox(height: 24),

        // Upcoming assignments with better design
        if (data.upcomingAssignments.isNotEmpty) ...[
          _buildSectionHeader(
              context, 'Bài tập sắp đến hạn', Icons.assignment_outlined),
          const SizedBox(height: 16),
          _buildUpcomingAssignments(context, data.upcomingAssignments),
          const SizedBox(height: 24),
        ],

        // Study progress
        _buildStudyProgress(context, data),

        // Quick access for students
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Truy cập nhanh', Icons.apps_outlined),
        const SizedBox(height: 16),
        _buildStudentQuickAccess(context),
      ],
    );
  }

  Widget _buildCoursesList(BuildContext context, List<EnrolledCourse> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildEnhancedCourseCard(context, courses[index]);
      },
    );
  }

  Widget _buildEnhancedCourseCard(
      BuildContext context, EnrolledCourse enrolledCourse) {
    final course = enrolledCourse.course;
    final group = enrolledCourse.group;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(Routes.CORE_MANAGEMENT);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã: ${course.code}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đang học',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.group,
                    'Nhóm: ${group.name}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    context,
                    Icons.schedule,
                    '${course.sessionCount} buổi',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyProgress(BuildContext context, StudentDashboardData data) {
    final studyProgress = data.studyProgress;

    // Use default values if studyProgress is null (e.g., from cache)
    final totalAssignments = studyProgress?.assignments.total ?? 0;
    final completedAssignments = studyProgress?.assignments.completed ?? 0;

    final totalQuizzes = studyProgress?.quizzes.total ?? 0;
    final completedQuizzes = studyProgress?.quizzes.completed ?? 0;

    final totalTasks = totalAssignments + totalQuizzes;
    final completedTasks = completedAssignments + completedQuizzes;
    final completionPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Tiến độ học tập', Icons.trending_up_outlined),
        if (studyProgress == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Đang tải dữ liệu tiến độ...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StudentProgressChart(
                        completed: completedTasks,
                        pending: totalTasks - completedTasks,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressItem(
                          context,
                          'Hoàn thành',
                          '$completionPercentage%',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildProgressItem(
                          context,
                          'Tổng số',
                          totalTasks.toString(),
                          Icons.assignment,
                          Colors.blue,
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressDetailCard(
                        context,
                        'Bài tập',
                        completedAssignments,
                        totalAssignments,
                        Icons.assignment_outlined,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgressDetailCard(
                        context,
                        'Quiz',
                        completedQuizzes,
                        totalQuizzes,
                        Icons.quiz_outlined,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDetailCard(
    BuildContext context,
    String title,
    int completed,
    int total,
    IconData icon,
    Color color,
  ) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$completed / $total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% hoàn thành',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentQuickAccess(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Thông báo',
                Icons.announcement_outlined,
                Colors.purple,
                () {
                  Get.toNamed(Routes.ANNOUNCEMENTS_LIST);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Bài tập',
                Icons.assignment_outlined,
                Colors.orange,
                () {
                  Get.toNamed(Routes.ASSIGNMENTS_LIST);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Quiz',
                Icons.quiz_outlined,
                Colors.red,
                () {
                  Get.toNamed(Routes.QUIZZES_LIST);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Tài liệu',
                Icons.folder_outlined,
                Colors.teal,
                () {
                  Get.toNamed(Routes.MATERIALS_LIST);
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String description,
    IconData icon, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<ActivityLog> activities) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.action,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeAgo(activity.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAssignments(
      BuildContext context, List<Assignment> assignments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final isUrgent = _isAssignmentUrgent(assignment.dueDate);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Get.toNamed(Routes.ASSIGNMENTS_LIST);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: isUrgent ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.course?.name ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDueDate(assignment.dueDate),
                      style: TextStyle(
                        color: isUrgent
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isAssignmentUrgent(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays <= 1 && difference.inHours >= 0;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return 'Còn ${difference.inHours} giờ';
    } else if (difference.inMinutes > 0) {
      return 'Còn ${difference.inMinutes} phút';
    } else {
      return 'Đã hết hạn';
    }
  }
}
