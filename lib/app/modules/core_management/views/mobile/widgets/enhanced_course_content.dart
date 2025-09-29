import 'package:classroom_mini/app/modules/core_management/controllers/core_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'enhanced_search_bar.dart';
import 'enhanced_course_card.dart';
import 'enhanced_empty_state.dart';
import 'enhanced_loading_state.dart';
import 'enhanced_filter_chip.dart';

class EnhancedCourseContent extends StatelessWidget {
  final CoreManagementController controller;

  const EnhancedCourseContent({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.loadCourses(refresh: true),
      child: Column(
        children: [
          // Enhanced Search Bar
          EnhancedSearchBar(
            hintText: 'Tìm kiếm khóa học...',
            onChanged: controller.setCourseSearch,
          ),

          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lọc theo học kỳ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                EnhancedFilterChip(
                  items: controller.semesters
                      .where((s) => s.isActive)
                      .map((semester) => FilterItem(
                            id: semester.id,
                            label: '${semester.code} - ${semester.name}',
                          ))
                      .toList(),
                  selectedId: controller.selectedSemesterId,
                  onChanged: (value) =>
                      controller.setSelectedSemester(value ?? ''),
                ),
              ],
            ),
          ),

          // Course List
          Expanded(
            child: controller.isLoading
                ? const EnhancedLoadingState()
                : controller.courses.isEmpty
                    ? const EnhancedEmptyState(
                        icon: Icons.school,
                        title: 'Chưa có khóa học nào',
                        subtitle: 'Tạo khóa học đầu tiên để bắt đầu',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.courses.length,
                        itemBuilder: (context, index) {
                          final course = controller.courses[index];
                          return EnhancedCourseCard(
                            course: course,
                            onEdit: () => _showEditDialog(context, course),
                            onDelete: () => _showDeleteDialog(context, course),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa khóa học'),
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

  void _showDeleteDialog(BuildContext context, course) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khóa học "${course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteCourse(course.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
