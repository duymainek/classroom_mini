import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:get/get.dart';
import 'assignment_list_view.dart';
import '../shared/widgets/assignment_form.dart';
import '../../controllers/assignment_controller.dart';
import 'package:classroom_mini/app/data/models/assignment_request_models.dart';

class AssignmentListPage extends StatelessWidget {
  const AssignmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesktopAssignmentListView();
  }
}

class AssignmentCreatePage extends StatelessWidget {
  const AssignmentCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bài tập (Desktop)')),
      body: const Center(child: Text('Desktop Assignment Create View')),
    );
  }
}

class AssignmentEditPage extends StatelessWidget {
  final Assignment assignment;

  const AssignmentEditPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa bài tập'),
          ),
          body: SafeArea(
            child: AssignmentForm(
              assignment: assignment,
              courses: const [],
              groups: const [],
              isLoading: controller.isLoading,
              onCancel: () => Get.back(),
              onSubmit: (form) async {
                final req = AssignmentUpdateRequest(
                  id: assignment.id,
                  title: form.title,
                  description:
                      form.description.isEmpty ? null : form.description,
                  courseId: form.courseId,
                  startDate: form.startDate,
                  dueDate: form.dueDate,
                  lateDueDate: form.lateDueDate,
                  allowLateSubmission: form.allowLateSubmission,
                  maxAttempts: form.maxAttempts,
                  fileFormats: form.fileFormats,
                  maxFileSize: form.maxFileSize,
                  groupIds: form.groupIds.isEmpty ? null : form.groupIds,
                );
                final ok = await controller.updateAssignment(req);
                if (ok) Get.back(result: true);
              },
            ),
          ),
        );
      },
    );
  }
}

class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: Center(child: Text('Desktop Assignment Detail View')),
    );
  }
}
