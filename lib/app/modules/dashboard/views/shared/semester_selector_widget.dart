import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../../../core/widgets/semester_selector.dart';

class SemesterSelectorWidget extends StatelessWidget {
  const SemesterSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      if (controller.availableSemesters.isEmpty) {
        return const SizedBox.shrink();
      }

      // Chuyển đổi danh sách semester từ DashboardController sang SemesterOption
      final semesterOptions = controller.availableSemesters.map((semester) {
        return SemesterOption(
          id: semester.id,
          name: semester.name,
          code: semester.code,
        );
      }).toList();

      return Row(
        children: [
          // Semester selector compact
          Expanded(
            child: SemesterSelector(
              semesters: semesterOptions,
              currentSemesterId: controller.currentSemester.value?.id,
              isCompact: true,
              onSemesterChanged: (semesterId, semesterName, semesterCode) {
                // Gọi switchSemester từ DashboardController
                controller.switchSemester(semesterId);
              },
            ),
          ),

          // Loading indicator
          if (controller.isLoading.value) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade600,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}
