import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../student_management/controllers/student_management_controller.dart';
import '../../../routes/app_routes.dart';
import '../views/student_import_page.dart';
import '../views/enhanced_edit_student_sheet.dart';
import '../views/enhanced_student_detail_view.dart';
import '../../../data/models/response/course_response.dart';
import '../../../data/models/response/group_response.dart';
import 'package:classroom_mini/app/core/widgets/responsive_container.dart';

class ResponsiveStudentManagementPage
    extends GetView<StudentManagementController> {
  const ResponsiveStudentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child: _MobileView(controller: controller),
      ),
      floatingActionButton: _FabActions(controller: controller),
    );
  }
}

class _MobileView extends StatelessWidget {
  final StudentManagementController controller;
  const _MobileView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        );
      }

      final data = controller.filteredStudents;

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxWidth = width < 768
              ? double.infinity
              : width < 1024
                  ? 900.0
                  : 1200.0;
          final horizontalPadding = width > maxWidth ? (width - maxWidth) / 2 : 0.0;

          return RefreshIndicator(
            onRefresh: controller.refreshStudents,
            child: CustomScrollView(
              slivers: [
                // SliverAppBar per Material 3 guide
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Quản lý Sinh viên'),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            // Search Section
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16 + horizontalPadding, 16, 16 + horizontalPadding, 8),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  onChanged: controller.setQuery,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm sinh viên',
                    hintText: 'Tìm theo tên, email hoặc username...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            // Filter Section
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16 + horizontalPadding, 0, 16 + horizontalPadding, 8),
              sliver: SliverToBoxAdapter(
                child: Obx(() => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterDropdown<Course>(
                                context,
                                controller: controller,
                                title: 'Khóa học',
                                value: controller.filterCourse.value,
                                items: controller.filterCourses,
                                isLoading:
                                    controller.isLoadingFilterCourses.value,
                                onChanged: (course) {
                                  controller.setFilterCourse(course);
                                },
                                itemBuilder: (course) =>
                                    '${course.code} - ${course.name}',
                                icon: Icons.school_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterDropdown<Group>(
                                context,
                                controller: controller,
                                title: 'Nhóm',
                                value: controller.filterGroup.value,
                                items: controller.filterGroups,
                                isLoading:
                                    controller.isLoadingFilterGroups.value,
                                onChanged: (group) {
                                  controller.setFilterGroup(group);
                                },
                                itemBuilder: (group) => group.name,
                                icon: Icons.group_outlined,
                              ),
                            ),
                          ],
                        ),
                        if (controller.filterCourse.value != null ||
                            controller.filterGroup.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: controller.clearFilters,
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('Xóa bộ lọc'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )),
              ),
            ),

            // Empty State
            if (data.isEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Chưa có sinh viên nào',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hãy thêm sinh viên mới hoặc thử thay đổi từ khóa tìm kiếm',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.9),
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                ),
              )
            else
              // Student Cards
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    16 + horizontalPadding, 0, 16 + horizontalPadding, 100),
                sliver: SliverList.separated(
                  itemBuilder: (_, i) {
                    final s = data[i];
                    return _StudentCard(
                      student: s,
                      controller: controller,
                      onTap: () => _showDetailView(context, controller, s),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: data.length,
                ),
              ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final StudentManagementController controller;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Derive friendlier labels for group and course
    final dynamic groupObj = student['group'];
    final dynamic courseObj = student['course'];
    String groupLabel = '-';
    if (groupObj is Map<String, dynamic>) {
      groupLabel = (groupObj['name'] ?? groupObj['id'] ?? '-').toString();
    } else {
      groupLabel = (student['groupId'] ?? '-').toString();
    }
    String courseLabel = '-';
    if (courseObj is Map<String, dynamic>) {
      final code = courseObj['code']?.toString();
      final name = courseObj['name']?.toString();
      if (code != null && name != null) {
        courseLabel = code + ' - ' + name;
      } else {
        courseLabel =
            (courseObj['name'] ?? courseObj['code'] ?? courseObj['id'] ?? '-')
                .toString();
      }
    } else {
      courseLabel = (student['courseId'] ?? '-').toString();
    }
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Info Row: Avatar + Name + Status + Actions
              Row(
                children: [
                  // Avatar (Material 3 accent container)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        _initials(
                            student['fullName'] ?? student['email'] ?? ''),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name only
                        Text(
                          student['fullName'] ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          student['email'] ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showDetailView(context, controller, student);
                          break;
                        case 'edit':
                          _showEditSheet(context, controller, student);
                          break;
                        case 'delete':
                          _showDeleteDialog(context, controller, student);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility_rounded),
                          title: Text('Xem chi tiết'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Chỉnh sửa'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_rounded),
                          title: Text('Xoá'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Secondary Info: Username and Status
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    student['username'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  _statusChip(student['isActive'] ?? true),
                ],
              ),

              const SizedBox(height: 8),

              // Group/Course Info (two lines)
              if (groupLabel != '-' || courseLabel != '-')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupLabel != '-')
                      Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Group: ' + groupLabel,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.9),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    if (groupLabel != '-' && courseLabel != '-')
                      const SizedBox(height: 6),
                    if (courseLabel != '-')
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Course: ' + courseLabel,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.9),
                                  ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabActions extends StatelessWidget {
  final StudentManagementController controller;
  const _FabActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showActionMenu(context),
      child: const Icon(Icons.add_rounded),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.person_add_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Thêm sinh viên mới'),
                  subtitle: const Text('Tạo tài khoản sinh viên mới'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.CREATE_STUDENT);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.file_upload_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: const Text('Import CSV'),
                  subtitle: const Text('Nhập danh sách từ file CSV'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const StudentImportPage());
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.file_download_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  title: const Text('Export CSV'),
                  subtitle: const Text('Xuất danh sách sinh viên'),
                  onTap: () async {
                    Navigator.pop(context);
                    _exportStudents(context, controller);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _statusIndicator(bool isActive) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        isActive ? 'Hoạt động' : 'Không hoạt động',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    ],
  );
}

Widget _statusChip(bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isActive
          ? Colors.green.withValues(alpha: 0.12)
          : Colors.red.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isActive
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.red.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isActive ? Colors.green.shade600 : Colors.red.shade600,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Hoạt động' : 'Không hoạt động',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    ),
  );
}

String _initials(String nameOrEmail) {
  final source = nameOrEmail.trim();
  if (source.isEmpty) return '?';
  final parts = source.contains(' ')
      ? source.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList()
      : source.split('@').first.split('.');
  final first =
      parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

void _showDetailView(BuildContext context,
    StudentManagementController controller, Map<String, dynamic> student) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết sinh viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: EnhancedStudentDetailView(
                student: student,
                onEdit: () {
                  Navigator.pop(context);
                  _showEditSheet(context, controller, student);
                },
                onDelete: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, controller, student);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showDeleteDialog(BuildContext context,
    StudentManagementController controller, Map<String, dynamic> s) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
      title: const Text('Xoá sinh viên'),
      content: Text(
        'Bạn có chắc chắn muốn xoá sinh viên "${s['fullName'] ?? s['username']}"?\n\nHành động này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final success =
                await controller.deleteStudentById(s['id'] as String);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã xoá sinh viên' : 'Xoá thất bại'),
                  backgroundColor: success
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
}

void _exportStudents(
    BuildContext context, StudentManagementController controller) async {
  Get.dialog(
    const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xuất file CSV...'),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );

  final success = await controller.exportStudents();

  if (Get.isDialogOpen == true) {
    Get.back();
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Đã xuất file CSV thành công' : 'Xuất file thất bại'),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Widget _buildFilterDropdown<T>(
  BuildContext context, {
  required StudentManagementController controller,
  required String title,
  required T? value,
  required List<T> items,
  required bool isLoading,
  required ValueChanged<T?> onChanged,
  required String Function(T) itemBuilder,
  required IconData icon,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.outline.withValues(alpha: 0.2),
      ),
    ),
    child: ListTile(
      dense: true,
      leading: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 16),
            ),
      title: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: value != null
          ? Text(
              itemBuilder(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Tất cả',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
      trailing: const Icon(Icons.arrow_drop_down, size: 18),
      onTap: isLoading
          ? null
          : () => _showFilterDropdownDialog<T>(
                context,
                title: title,
                items: items,
                currentValue: value,
                onChanged: onChanged,
                itemBuilder: itemBuilder,
              ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
  );
}

void _showFilterDropdownDialog<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required T? currentValue,
  required ValueChanged<T?> onChanged,
  required String Function(T) itemBuilder,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                dense: true,
                title: const Text('Tất cả'),
                leading: const Icon(Icons.clear, size: 18),
                selected: currentValue == null,
                onTap: () {
                  onChanged(null);
                  Navigator.of(context).pop();
                },
              );
            }
            final item = items[index - 1];
            return ListTile(
              dense: true,
              title: Text(itemBuilder(item)),
              selected: currentValue == item,
              onTap: () {
                onChanged(item);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    ),
  );
}

void _showEditSheet(
    BuildContext context,
    StudentManagementController controller,
    Map<String, dynamic> student) async {
  await controller.initializeEditStudentDialog();

  final courseId = student['courseId'];
  if (courseId != null) {
    await controller.loadEditGroupsForCourse(courseId);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) {
      return Obx(() => EnhancedEditStudentSheet(
            student: student,
            courses: controller.editCourses,
            groups: controller.editGroups,
            isLoadingCourses: controller.isLoadingEditCourses.value,
            isLoadingGroups: controller.isLoadingEditGroups.value,
            onCourseChanged: (courseId) async {
              await controller.loadEditGroupsForCourse(courseId);
            },
            onSubmit: (email, fullName, isActive, groupId, courseId) async {
              final success = await controller.updateStudent(
                id: student['id'] as String,
                email: email,
                fullName: fullName,
                isActive: isActive,
                groupId: groupId,
                courseId: courseId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã cập nhật sinh viên'
                        : 'Cập nhật thất bại'),
                    backgroundColor: success
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }

              if (success) {
                await controller.refreshStudents();
              }
            },
          ));
    },
  );
}
