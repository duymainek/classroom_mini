import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';
import '../../widgets/assignment_card.dart';

class DesktopAssignmentListView extends StatelessWidget {
  const DesktopAssignmentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Bài tập'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadAssignments(refresh: true),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToCreateAssignment(),
              ),
            ],
          ),
          body: Row(
            children: [
              // Sidebar with filters
              SizedBox(
                width: 300,
                child: _buildSidebar(context, controller),
              ),

              // Main content
              Expanded(
                child: _buildMainContent(context, controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, AssignmentController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bài tập...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.searchAssignments(value);
              },
              onSubmitted: (_) => controller.loadAssignments(refresh: true),
            ),
          ),

          // Filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ lọc',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Status filter
                  Text(
                    'Trạng thái',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'all',
                    'upcoming',
                    'active',
                    'lateSubmission',
                    'closed',
                    'inactive'
                  ]
                      .map((status) => _buildFilterOption(status, controller))
                      .toList(),

                  const SizedBox(height: 24),

                  // Sort options
                  Text(
                    'Sắp xếp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: controller.sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sắp xếp theo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'created_at', child: Text('Ngày tạo')),
                      DropdownMenuItem(
                          value: 'due_date', child: Text('Hạn chót')),
                      DropdownMenuItem(value: 'title', child: Text('Tiêu đề')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.sortAssignments(value, controller.sortOrder);
                        controller.loadAssignments(refresh: true);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: controller.sortOrder,
                    decoration: const InputDecoration(
                      labelText: 'Thứ tự',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Mới nhất')),
                      DropdownMenuItem(value: 'asc', child: Text('Cũ nhất')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.sortAssignments(controller.sortBy, value);
                        controller.loadAssignments(refresh: true);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Apply filters button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.loadAssignments(refresh: true),
                      child: const Text('Áp dụng bộ lọc'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String status, AssignmentController controller) {
    final statusLabels = {
      'all': 'Tất cả',
      'upcoming': 'Sắp mở',
      'active': 'Đang mở',
      'lateSubmission': 'Nộp trễ',
      'closed': 'Đã đóng',
      'inactive': 'Không hoạt động',
    };

    return Obx(() {
      final isSelected = controller.statusFilter == status;
      return CheckboxListTile(
        title: Text(statusLabels[status] ?? status),
        value: isSelected,
        onChanged: (value) {
          controller.filterByStatus(status);
        },
        dense: true,
      );
    });
  }

  Widget _buildMainContent(
      BuildContext context, AssignmentController controller) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Obx(() => Text(
                    'Danh sách bài tập (${controller.assignments.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  )),
              const Spacer(),
              // Action buttons would go here
            ],
          ),
        ),

        // Assignment list
        Expanded(
          child: Obx(() {
            if (controller.isLoading && controller.assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.assignments.isEmpty) {
              return _buildEmptyState();
            }

            return _buildAssignmentList(controller);
          }),
        ),
      ],
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
            'Tạo bài tập đầu tiên để bắt đầu',
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
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

  Widget _buildAssignmentList(AssignmentController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.assignments.length,
      itemBuilder: (context, index) {
        final assignment = controller.assignments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: AssignmentListCard(
            assignment: assignment,
            onTap: () => _navigateToAssignmentDetail(assignment),
          ),
        );
      },
    );
  }

  void _navigateToCreateAssignment() {
    Get.toNamed(Routes.ASSIGNMENTS_CREATE);
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_DETAIL, arguments: assignment);
  }
}
