import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';
import '../../widgets/assignment_card.dart';

class MobileAssignmentListView extends StatelessWidget {
  const MobileAssignmentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bài tập'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(controller),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToCreateAssignment(),
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading && controller.assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.assignments.isEmpty) {
              return _buildEmptyState(context);
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
                  return AssignmentCard(
                    assignment: assignment,
                    onTap: () => _navigateToAssignmentDetail(assignment),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài tập nào',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo bài tập đầu tiên để bắt đầu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateAssignment,
            icon: const Icon(Icons.add),
            label: const Text('Tạo bài tập'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài tập nào',
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bài tập sẽ xuất hiện ở đây khi được giao',
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAssignmentCard(
      BuildContext context, Assignment assignment) {
    final theme = Theme.of(context);
    final status = assignment.status;
    final timeRemaining = assignment.timeRemaining;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToAssignmentDetail(assignment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 8),

              // Course info
              if (assignment.course != null)
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${assignment.course!.code} - ${assignment.course!.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Time info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hạn chót: ${_formatDateTime(assignment.dueDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),

              if (timeRemaining != null && timeRemaining.inDays > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: _getTimeRemainingColor(timeRemaining),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Còn ${timeRemaining.inDays} ngày',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTimeRemainingColor(timeRemaining),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Submission info
              Row(
                children: [
                  Icon(
                    Icons.upload,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tối đa ${assignment.maxAttempts} lần nộp',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AssignmentStatus status) {
    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.upcoming:
        return Colors.blue;
      case AssignmentStatus.open:
        return Colors.green;
      case AssignmentStatus.lateSubmission:
        return Colors.orange;
      case AssignmentStatus.closed:
        return Colors.red;
      case AssignmentStatus.inactive:
        return Colors.grey;
    }
  }

  Color _getTimeRemainingColor(Duration timeRemaining) {
    if (timeRemaining.inDays <= 1) return Colors.red;
    if (timeRemaining.inDays <= 3) return Colors.orange;
    return Colors.green;
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
