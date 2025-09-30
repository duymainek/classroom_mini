import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';

class MobileAssignmentDetailView extends StatelessWidget {
  final Assignment assignment;

  const MobileAssignmentDetailView({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      initState: (_) => Get.find<AssignmentController>().loadAssignmentSubmissions(assignment.id),
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    assignment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.primary),
                    onPressed: () async {
                      final result = await Get.toNamed(Routes.ASSIGNMENTS_EDIT,
                          arguments: assignment);
                      if (result == true) {
                        controller.loadAssignments(refresh: true);
                      }
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildAttachments(context),
                    const SizedBox(height: 16),
                    _buildTimeInfo(context),
                    const SizedBox(height: 16),
                    _buildSubmissionSettings(context),
                    const SizedBox(height: 16),
                    _buildSubmissions(context, controller),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Thông tin bài tập',
      icon: Icons.assignment,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusChip(context),
          ],
        ),
        if (assignment.description != null &&
            assignment.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              assignment.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (assignment.course != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.school,
            label: 'Khóa học',
            value: '${assignment.course!.code} - ${assignment.course!.name}',
          ),
        ],
        if (assignment.groups.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.group,
            label: 'Nhóm',
            value: assignment.groups.map((g) => g.name).join(', '),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(context, assignment.status),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _statusColor(context, assignment.status).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        assignment.status.displayName,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, AssignmentStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case AssignmentStatus.upcoming:
        return colorScheme.primary;
      case AssignmentStatus.open:
        return colorScheme.tertiary;
      case AssignmentStatus.lateSubmission:
        return colorScheme.error;
      case AssignmentStatus.closed:
        return colorScheme.outline;
      case AssignmentStatus.inactive:
        return colorScheme.surfaceVariant;
    }
  }

  Widget _buildTimeInfo(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Thời gian',
      icon: Icons.schedule,
      children: [
        _buildModernDateTile(
          context,
          title: 'Ngày bắt đầu',
          subtitle: _formatDateTime(assignment.startDate),
          value: assignment.startDate,
          icon: Icons.play_arrow,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _buildModernDateTile(
          context,
          title: 'Hạn chót',
          subtitle: _formatDateTime(assignment.dueDate),
          value: assignment.dueDate,
          icon: Icons.flag,
          onTap: () {},
        ),
        if (assignment.lateDueDate != null) ...[
          const SizedBox(height: 8),
          _buildModernDateTile(
            context,
            title: 'Hạn nộp trễ',
            subtitle: _formatDateTime(assignment.lateDueDate!),
            value: assignment.lateDueDate!,
            icon: Icons.warning,
            onTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildSubmissionSettings(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Cài đặt nộp bài',
      icon: Icons.settings,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.repeat,
          label: 'Số lần nộp tối đa',
          value: assignment.maxAttempts.toString(),
        ),
        if (assignment.fileFormats.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.attach_file,
            label: 'Định dạng file',
            value: assignment.fileFormats.join(', '),
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          icon: Icons.storage,
          label: 'Kích thước file tối đa',
          value: '${assignment.maxFileSize} MB',
        ),
      ],
    );
  }

  Widget _buildSubmissions(
      BuildContext context, AssignmentController controller) {
    return Obx(() {
      if (controller.submissions.isEmpty) {
        return _buildModernSection(
          context,
          title: 'Danh sách nộp bài',
          icon: Icons.assignment_turned_in,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có sinh viên nào nộp bài',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Danh sách nộp bài sẽ xuất hiện ở đây',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return _buildModernSection(
        context,
        title: 'Danh sách nộp bài',
        icon: Icons.assignment_turned_in,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search submissions...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    controller.loadAssignmentSubmissions(
                      assignment.id,
                      search: value,
                    );
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog(context, controller);
                },
              ),
              IconButton(
                icon: Icon(Icons.sort),
                onPressed: () {
                  _showSortDialog(context, controller);
                },
              ),
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {
                  controller.exportSubmissions(assignment.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.submissions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _submissionColor(context, s.status),
                    child: Icon(_submissionIcon(s.status), color: Colors.white),
                  ),
                  title: Text(
                    s.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (s.latestSubmission != null)
                        Text(
                          'Lần ${s.latestSubmission!.attemptNumber} - ${_formatDateTime(s.latestSubmission!.submittedAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.8),
                                  ),
                        ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(s.status.displayName),
                    backgroundColor: _submissionColor(context, s.status),
                    labelStyle:
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              )),
        ],
      );
    });
  }

  Widget _buildAttachments(BuildContext context) {
    if (assignment.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildModernSection(
      context,
      title: 'Attachments',
      icon: Icons.attachment,
      children: assignment.attachments
          .map((att) => ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text(att.fileName),
                subtitle: Text('${(att.fileSize ?? 0) / 1024} KB'),
                onTap: () {
                  // TODO: Implement file download/opening
                },
              ))
          .toList(),
    );
  }

  Color _submissionColor(BuildContext context, SubmissionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return colorScheme.error;
      case SubmissionStatus.submitted:
        return colorScheme.primary;
      case SubmissionStatus.late:
        return colorScheme.tertiary;
      case SubmissionStatus.graded:
        return colorScheme.secondary;
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

  Widget _buildModernSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing:
            Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Filter Submissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add filter options here
            Text('Filter options to be implemented'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context, AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sort Submissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add sort options here
            Text('Sort options to be implemented'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
