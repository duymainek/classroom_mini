import 'package:classroom_mini/app/core/utils/semester_helper.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'assignment_list_view.dart';
import 'assignment_detail_view.dart';
import 'package:get/get.dart';
import '../shared/widgets/assignment_form.dart';
import '../../controllers/assignment_controller.dart';
import 'package:classroom_mini/app/data/models/assignment_request_models.dart';

class AssignmentListPage extends StatelessWidget {
  const AssignmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobileAssignmentListView();
  }
}

class AssignmentCreatePage extends StatelessWidget {
  const AssignmentCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tạo bài tập'),
          ),
          body: SafeArea(
            child: AssignmentForm(
              courses: const [],
              groups: const [],
              isLoading: controller.isLoading,
              onCancel: () => Get.back(),
              onSubmit: (form) async {
                final req = AssignmentCreateRequest(
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
                  semesterId: SemesterHelper.getCurrentSemesterId(),
                );
                final ok = await controller.createAssignment(req);
                if (ok) {
                  Navigator.pop(context, true);
                  Get.snackbar(
                    'Thành công',
                    'Đã tạo bài tập "${form.title}" thành công',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class AssignmentEditPage extends StatefulWidget {
  final Assignment assignment;

  const AssignmentEditPage({super.key, required this.assignment});

  @override
  State<AssignmentEditPage> createState() => _AssignmentEditPageState();
}

class _AssignmentEditPageState extends State<AssignmentEditPage> {
  late AssignmentController controller;
  List<CourseInfo> courses = [];
  List<GroupInfo> groups = [];
  bool isLoadingMeta = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AssignmentController());
    _loadMetaData();
  }

  Future<void> _loadMetaData() async {
    setState(() => isLoadingMeta = true);

    try {
      // Load courses
      await controller.loadCoursesForForm();
      courses = controller.formState.value.courses;

      // Load groups for the assignment's course
      if (widget.assignment.courseId.isNotEmpty) {
        await controller.loadGroupsForForm(widget.assignment.courseId);
        groups = controller.formState.value.groups;
      }

      // Set selected groups for the form after groups are loaded
      final selectedGroupIds =
          widget.assignment.groups.map((g) => g.id).toList();
      print(
          'Assignment groups: ${widget.assignment.groups.map((g) => '${g.id}:${g.name}').toList()}');
      print('Selected group IDs: $selectedGroupIds');
      if (selectedGroupIds.isNotEmpty) {
        controller.setSelectedGroupsForForm(selectedGroupIds);
        print(
            'Set selected groups in controller: ${controller.selectedGroupIdsForForm}');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: $e');
    } finally {
      setState(() => isLoadingMeta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa bài tập'),
          ),
          body: SafeArea(
            child: isLoadingMeta
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải dữ liệu...'),
                      ],
                    ),
                  )
                : AssignmentForm(
                    assignment: widget.assignment,
                    courses: courses,
                    groups: groups,
                    isLoading: controller.isLoading,
                    onCancel: () => Get.back(),
                    onSubmit: (form) async {
                      final req = AssignmentUpdateRequest(
                        id: widget.assignment.id,
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
                      if (ok) {
                        Get.back(result: true);
                        Get.snackbar(
                          'Thành công',
                          'Đã cập nhật bài tập "${form.title}" thành công',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                        );
                      }
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
    return MobileAssignmentDetailView(assignment: assignment);
  }
}
