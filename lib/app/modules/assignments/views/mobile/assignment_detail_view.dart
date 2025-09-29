import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:classroom_mini/app/data/models/submission_model.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';

class MobileAssignmentDetailView extends StatelessWidget {
  final Assignment assignment;

  const MobileAssignmentDetailView({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(assignment.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Get.toNamed(Routes.ASSIGNMENTS_EDIT,
                      arguments: assignment);
                  if (result == true) {
                    // Refresh assignment data when returning from edit
                    controller.loadAssignments(refresh: true);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildTimeInfo(context),
              const SizedBox(height: 12),
              _buildSubmissionSettings(context),
              const SizedBox(height: 16),
              _buildSubmissions(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            if (assignment.description != null &&
                assignment.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(assignment.description!),
            ],
            if (assignment.course != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        '${assignment.course!.code} - ${assignment.course!.name}'),
                  ),
                ],
              ),
            ],
            if (assignment.groups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.group, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nhóm: ${assignment.groups.map((g) => g.name).join(', ')}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      label: Text(assignment.status.displayName),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: _statusColor(assignment.status),
    );
  }

  Color _statusColor(AssignmentStatus status) {
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

  Widget _buildTimeInfo(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Ngày bắt đầu'),
            subtitle: Text(_formatDateTime(assignment.startDate)),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Hạn chót'),
            subtitle: Text(_formatDateTime(assignment.dueDate)),
          ),
          if (assignment.lateDueDate != null)
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Hạn nộp trễ'),
              subtitle: Text(_formatDateTime(assignment.lateDueDate!)),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Số lần nộp tối đa'),
            subtitle: Text(assignment.maxAttempts.toString()),
          ),
          if (assignment.fileFormats.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Định dạng file'),
              subtitle: Text(assignment.fileFormats.join(', ')),
            ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Kích thước file tối đa'),
            subtitle: Text('${assignment.maxFileSize} MB'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissions(
      BuildContext context, AssignmentController controller) {
    return Obx(() {
      if (controller.submissions.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Icon(Icons.assignment_turned_in, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Chưa có sinh viên nào nộp bài'),
              ],
            ),
          ),
        );
      }

      return Card(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.submissions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final s = controller.submissions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _submissionColor(s.status),
                child: Icon(_submissionIcon(s.status), color: Colors.white),
              ),
              title: Text(s.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.email),
                  if (s.latestSubmission != null)
                    Text(
                      'Lần ${s.latestSubmission!.attemptNumber} - ${_formatDateTime(s.latestSubmission!.submittedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: Chip(
                label: Text(s.status.displayName),
                backgroundColor: _submissionColor(s.status),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          },
        ),
      );
    });
  }

  Color _submissionColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Colors.red;
      case SubmissionStatus.submitted:
        return Colors.blue;
      case SubmissionStatus.late:
        return Colors.orange;
      case SubmissionStatus.graded:
        return Colors.green;
    }
  }

  IconData _submissionIcon(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Icons.cancel;
      case SubmissionStatus.submitted:
        return Icons.check_circle;
      case SubmissionStatus.late:
        return Icons.warning;
      case SubmissionStatus.graded:
        return Icons.grade;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
