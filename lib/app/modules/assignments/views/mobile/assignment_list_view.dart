import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';
import 'dart:io';
import '../../controllers/assignment_controller.dart';
import '../../widgets/assignment_card.dart';
import 'package:classroom_mini/app/core/utils/semester_helper.dart';

class MobileAssignmentListView extends StatelessWidget {
  const MobileAssignmentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Bài tập',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.3),
                          colorScheme.secondaryContainer.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.download, color: colorScheme.primary),
                    onPressed: () => _exportAllAssignments(controller),
                    tooltip: 'Xuất tất cả bài tập',
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: colorScheme.primary),
                    onPressed: () => _showFilterDialog(controller),
                  ),
                  Obx(() {
                    final connectivityService = Get.find<ConnectivityService>();
                    if (!connectivityService.isOnline.value) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: Icon(Icons.add, color: colorScheme.primary),
                      onPressed: () => _navigateToCreateAssignment(),
                    );
                  }),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: Obx(() {
                  if (controller.isLoading && controller.assignments.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Đang tải...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.assignments.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= controller.assignments.length) {
                          return _buildLoadingIndicator();
                        }

                        final assignment = controller.assignments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: AssignmentCard(
                            assignment: assignment,
                            onTap: () =>
                                _navigateToAssignmentDetail(assignment),
                            showActions: true,
                            onTrack: () =>
                                _navigateToAssignmentTracking(assignment),
                          ),
                        );
                      },
                      childCount: controller.assignments.length +
                          (controller.hasMore ? 1 : 0),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài tập nào',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo bài tập đầu tiên để bắt đầu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            Obx(() {
              final connectivityService = Get.find<ConnectivityService>();
              if (!connectivityService.isOnline.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _navigateToCreateAssignment,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo bài tập'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final context = Get.context!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Đang tải thêm...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tìm kiếm bài tập'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa tìm kiếm...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            controller.searchAssignments(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAssignments(refresh: true);
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Lọc bài tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String>(
                  title: const Text('Tất cả'),
                  value: 'all',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Sắp mở'),
                  value: 'upcoming',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Đang mở'),
                  value: 'active',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Nộp trễ'),
                  value: 'lateSubmission',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Đã đóng'),
                  value: 'closed',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAssignments(refresh: true);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateAssignment() async {
    final result = await Get.toNamed(Routes.ASSIGNMENTS_CREATE);
    if (result == true) {
      // Refresh list when returning from create page
      final controller = Get.find<AssignmentController>();
      controller.loadAssignments(refresh: true);
    }
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_DETAIL, arguments: assignment);
  }

  void _navigateToAssignmentTracking(Assignment assignment) {
    Get.toNamed(
      Routes.ASSIGNMENTS_TRACKING,
      arguments: {
        'assignmentId': assignment.id,
        'assignmentTitle': assignment.title,
      },
    );
  }

  Future<void> _exportAllAssignments(AssignmentController controller) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final semesterId = SemesterHelper.getCurrentSemesterId();
      final csvBytes = await controller.exportAllAssignments(
        semesterId: semesterId,
        includeSubmissions: true,
        includeGrades: true,
      );

      // Đóng dialog trước khi xử lý kết quả
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (csvBytes == null || csvBytes.isEmpty) {
        Get.snackbar('Lỗi', 'Không thể xuất dữ liệu');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath = '${directory.path}/all_assignments_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsBytes(csvBytes);

      Get.snackbar(
        'Thành công',
        'Đã xuất file CSV: $filePath',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Đóng dialog nếu có lỗi
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      Get.snackbar('Lỗi', 'Không thể xuất file: $e');
    }
  }
}

class MobileStudentAssignmentListView extends StatelessWidget {
  const MobileStudentAssignmentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StudentAssignmentController>(
      init: StudentAssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bài tập của tôi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(controller),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(controller),
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading && controller.assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.assignments.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadAssignments(refresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: controller.assignments.length +
                    (controller.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.assignments.length) {
                    return _buildLoadingIndicator();
                  }

                  final assignment = controller.assignments[index];
                  return _buildStudentAssignmentCard(context, assignment);
                },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final context = Get.context!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài tập nào',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài tập sẽ xuất hiện ở đây khi được giao',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAssignmentCard(
      BuildContext context, Assignment assignment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = assignment.status;
    final timeRemaining = assignment.timeRemaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToAssignmentDetail(assignment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(context, status),
                ],
              ),

              const SizedBox(height: 12),

              // Course info
              if (assignment.course != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${assignment.course!.code} - ${assignment.course!.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Time info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hạn chót: ${_formatDateTime(assignment.dueDate)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (timeRemaining != null && timeRemaining.inDays > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  _getTimeRemainingColor(context, timeRemaining)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.timer,
                              size: 16,
                              color: _getTimeRemainingColor(
                                  context, timeRemaining),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Còn ${timeRemaining.inDays} ngày',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getTimeRemainingColor(
                                  context, timeRemaining),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Submission info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.upload,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tối đa ${assignment.maxAttempts} lần nộp',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, AssignmentStatus status) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(context, status),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(context, status).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, AssignmentStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case AssignmentStatus.upcoming:
        return colorScheme.primary;
      case AssignmentStatus.open:
        return colorScheme.tertiary;
      case AssignmentStatus.lateSubmission:
        return colorScheme.error;
      case AssignmentStatus.closed:
        return colorScheme.outline;
      case AssignmentStatus.inactive:
        return colorScheme.surfaceVariant;
    }
  }

  Color _getTimeRemainingColor(BuildContext context, Duration timeRemaining) {
    final colorScheme = Theme.of(context).colorScheme;
    if (timeRemaining.inDays <= 1) return colorScheme.error;
    if (timeRemaining.inDays <= 3) return colorScheme.tertiary;
    return colorScheme.primary;
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showSearchDialog(StudentAssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tìm kiếm bài tập'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa tìm kiếm...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            controller.searchAssignments(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAssignments(refresh: true);
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(StudentAssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Lọc bài tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String>(
                  title: const Text('Tất cả'),
                  value: 'all',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Sắp mở'),
                  value: 'upcoming',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Đang mở'),
                  value: 'active',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Nộp trễ'),
                  value: 'lateSubmission',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Đã đóng'),
                  value: 'closed',
                  groupValue: controller.statusFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByStatus(value);
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAssignments(refresh: true);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_DETAIL, arguments: assignment);
  }
}
