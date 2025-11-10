import 'package:classroom_mini/app/modules/core_management/controllers/core_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'enhanced_search_bar.dart';
import 'enhanced_semester_card.dart';
import 'enhanced_empty_state.dart';
import 'enhanced_loading_state.dart';
import 'enhanced_edit_semester_dialog.dart';

class EnhancedSemesterContent extends StatelessWidget {
  final CoreManagementController controller;

  const EnhancedSemesterContent({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.loadSemesters(refresh: true),
      child: Column(
        children: [
          // Enhanced Search Bar
          EnhancedSearchBar(
            hintText: 'Tìm kiếm học kỳ...',
            onChanged: controller.setSemesterSearch,
          ),

          // Semester List
          Expanded(
            child: controller.isLoading
                ? const EnhancedLoadingState()
                : controller.semesters.isEmpty
                    ? const EnhancedEmptyState(
                        icon: Icons.calendar_today,
                        title: 'Chưa có học kỳ nào',
                        subtitle: 'Tạo học kỳ đầu tiên để bắt đầu',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.semesters.length,
                        itemBuilder: (context, index) {
                          final semester = controller.semesters[index];
                          return EnhancedSemesterCard(
                            semester: semester,
                            onEdit: () => _showEditDialog(context, semester),
                            onDelete: () =>
                                _showDeleteDialog(context, semester),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, semester) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedEditSemesterDialog(
        semester: semester,
        onSave: (data) {
          // TODO: Implement save logic in controller
          // controller.updateSemester(semester.id, data);
          debugPrint('Save semester data: $data');
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, semester) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa học kỳ "${semester.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSemester(semester.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
