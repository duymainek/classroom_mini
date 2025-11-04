import 'package:classroom_mini/app/core/utils/semester_helper.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/request/assignment_request.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import 'assignment_list_view.dart';
import 'assignment_detail_view.dart';
import 'package:get/get.dart';
import '../../widgets/assignment_form.dart';
import '../../controllers/assignment_controller.dart';

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
                pinned: false, // Fixed: Set to false to allow scrolling
                snap: false,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Tạo bài tập',
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
              ),
              SliverFillRemaining(
                child: SafeArea(
                  child: AssignmentForm(
                    courses: const [],
                    groups: const [],
                    isLoading: controller.isLoading,
                    onCancel: () => Navigator.pop(context),
                    onSubmit: (form) async {
                      // Debug: Log attachment information
                      print('=== ASSIGNMENT SUBMIT DEBUG ===');
                      print(
                          'Total uploadedAttachments: ${form.uploadedAttachments.length}');
                      for (int i = 0;
                          i < form.uploadedAttachments.length;
                          i++) {
                        final att = form.uploadedAttachments[i];
                        print(
                            'Attachment $i: ${att.fileName} - Status: ${att.status} - ID: ${att.attachmentId} - isUploaded: ${att.isUploaded}');
                      }

                      // Get attachment IDs from uploaded files
                      final attachmentIds = form.uploadedAttachments
                          .where((attachment) => attachment.isUploaded)
                          .map((attachment) => attachment.attachmentId!)
                          .toList();

                      print('Filtered attachmentIds: $attachmentIds');
                      print('=== END ASSIGNMENT SUBMIT DEBUG ===');

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
                        attachmentIds:
                            attachmentIds.isEmpty ? null : attachmentIds,
                      );

                      // Create assignment with attachment IDs
                      // Navigation is handled in controller via Get.offAllNamed
                      await controller.createAssignment(req);
                    },
                  ),
                ),
              ),
            ],
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
      courses = controller.formState.value.courses
          .map((c) => CourseInfo(id: c.id, code: c.code, name: c.name))
          .toList();

      // Load groups for the assignment's course
      if (widget.assignment.courseId.isNotEmpty) {
        await controller.loadGroupsForForm(widget.assignment.courseId);
        groups = controller.formState.value.groups
            .map((g) => GroupInfo(id: g.id, name: g.name))
            .toList();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AssignmentController>(
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: false,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Chỉnh sửa bài tập',
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
              ),
              SliverFillRemaining(
                child: SafeArea(
                  child: isLoadingMeta
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: colorScheme.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'Đang tải dữ liệu...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : AssignmentForm(
                          assignment: widget.assignment,
                          courses: courses,
                          groups: groups,
                          isLoading: controller.isLoading,
                          onCancel: () => Navigator.pop(context),
                          onSubmit: (form) async {
                            final req = AssignmentUpdateRequest(
                              id: widget.assignment.id,
                              title: form.title,
                              description: form.description.isEmpty
                                  ? null
                                  : form.description,
                              courseId: form.courseId,
                              startDate: form.startDate,
                              dueDate: form.dueDate,
                              lateDueDate: form.lateDueDate,
                              allowLateSubmission: form.allowLateSubmission,
                              maxAttempts: form.maxAttempts,
                              fileFormats: form.fileFormats,
                              maxFileSize: form.maxFileSize,
                              groupIds:
                                  form.groupIds.isEmpty ? null : form.groupIds,
                            );
                            final ok = await controller.updateAssignment(req);
                            if (ok) {
                              Navigator.pop(context, true);
                              Get.snackbar(
                                'Thành công',
                                'Đã cập nhật bài tập "${form.title}" thành công',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: colorScheme.primary,
                                colorText: colorScheme.onPrimary,
                                duration: const Duration(seconds: 3),
                                icon: Icon(Icons.check_circle,
                                    color: colorScheme.onPrimary),
                              );
                            }
                          },
                        ),
                ),
              ),
            ],
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
