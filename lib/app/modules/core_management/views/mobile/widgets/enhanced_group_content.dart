import 'package:classroom_mini/app/modules/core_management/controllers/core_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'enhanced_search_bar.dart';
import 'enhanced_group_card.dart';
import 'enhanced_empty_state.dart';
import 'enhanced_loading_state.dart';
import 'enhanced_filter_chip.dart';

class EnhancedGroupContent extends StatelessWidget {
  final CoreManagementController controller;

  const EnhancedGroupContent({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.loadGroups(refresh: true),
      child: Column(
        children: [
          // Enhanced Search Bar
          EnhancedSearchBar(
            hintText: 'Tìm kiếm nhóm...',
            onChanged: controller.setGroupSearch,
          ),

          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lọc theo khóa học',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EnhancedFilterChip(
                  items: controller.courses
                      .where((c) => c.isActive)
                      .map((course) => FilterItem(
                            id: course.id,
                            label: '${course.code} - ${course.name}',
                          ))
                      .toList(),
                  selectedId: controller.selectedCourseId,
                  onChanged: (value) =>
                      controller.setSelectedCourse(value ?? ''),
                ),
              ],
            ),
          ),

          // Group List
          Expanded(
            child: controller.isLoading
                ? const EnhancedLoadingState()
                : controller.groups.isEmpty
                    ? const EnhancedEmptyState(
                        icon: Icons.group,
                        title: 'Chưa có nhóm nào',
                        subtitle: 'Tạo nhóm đầu tiên để bắt đầu',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.groups.length,
                        itemBuilder: (context, index) {
                          final group = controller.groups[index];
                          return EnhancedGroupCard(
                            group: group,
                            onEdit: () => _showEditDialog(context, group),
                            onDelete: () => _showDeleteDialog(context, group),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa nhóm'),
        content: const Text('Form chỉnh sửa sẽ được hiển thị ở đây'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, group) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhóm "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteGroup(group.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
