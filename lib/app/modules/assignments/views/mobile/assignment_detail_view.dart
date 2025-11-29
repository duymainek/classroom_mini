import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';
import 'package:classroom_mini/app/core/app_config.dart';
import 'package:classroom_mini/app/core/widgets/responsive_container.dart';

class MobileAssignmentDetailView extends StatelessWidget {
  final Assignment assignment;

  const MobileAssignmentDetailView({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInstructor = AppConfig.instance.isInstructor;

    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      initState: (_) {
        // Chỉ load submissions khi user là instructor
        if (isInstructor) {
          // Sử dụng WidgetsBinding để đảm bảo gọi sau khi build hoàn tất
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.find<AssignmentController>()
                .loadAssignmentSubmissions(assignment.id);
          });
        }
      },
      builder: (controller) {
        return Scaffold(
          body: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: CustomScrollView(
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
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                            colorScheme.secondaryContainer
                                .withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (isInstructor) ...[
                      IconButton(
                        icon: Icon(Icons.track_changes,
                            color: colorScheme.primary),
                        onPressed: () {
                          Get.toNamed(
                            Routes.ASSIGNMENTS_TRACKING,
                            arguments: {
                              'assignmentId': assignment.id,
                              'assignmentTitle': assignment.title,
                            },
                          );
                        },
                        tooltip: 'Theo dõi nộp bài',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary),
                        onPressed: () async {
                          final result = await Get.toNamed(
                              Routes.ASSIGNMENTS_EDIT,
                              arguments: assignment);
                          if (result == true) {
                            controller.loadAssignments(refresh: true);
                          }
                        },
                      ),
                    ],
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
                      // Chỉ hiển thị tracking và submissions cho instructor
                      if (isInstructor) ...[
                        const SizedBox(height: 16),
                        _buildGroupFilter(context, controller),
                        const SizedBox(height: 16),
                        _buildTrackingOverview(context, controller),
                        const SizedBox(height: 16),
                        _buildSubmissions(context, controller),
                      ],
                      // Thêm khoảng trống cho nút nộp bài của student
                      if (!isInstructor) const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Thêm nút nộp bài cho student
          floatingActionButton: !isInstructor
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Get.toNamed(
                      Routes.ASSIGNMENTS_SUBMIT,
                      arguments: {'assignment': assignment},
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Nộp bài'),
                  backgroundColor: colorScheme.primary,
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
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
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
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
            color:
                _statusColor(context, assignment.status).withValues(alpha: 0.3),
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
        return colorScheme.surfaceContainerHighest;
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

  Widget _buildTrackingOverview(
      BuildContext context, AssignmentController controller) {
    return _buildModernSection(
      context,
      title: 'Tổng quan theo dõi',
      icon: Icons.analytics,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Tổng số SV',
                value: controller.submissions.length.toString(),
                icon: Icons.people,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Đã nộp',
                value: controller.submissions
                    .where((s) => s.status != SubmissionStatus.notSubmitted)
                    .length
                    .toString(),
                icon: Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Chưa nộp',
                value: controller.submissions
                    .where((s) => s.status == SubmissionStatus.notSubmitted)
                    .length
                    .toString(),
                icon: Icons.pending,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
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
                        .withValues(alpha: 0.6),
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
                              .withValues(alpha: 0.8),
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
          ...controller.submissions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
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
                          'Lần ${s.latestSubmission!.attemptNumber} - ${_formatDateTime(s.latestSubmission!.submittedAt!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.8),
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
                  onTap: () => _navigateToSubmissionDetail(s),
                ),
              )),
        ],
      );
    });
  }

  void _navigateToSubmissionDetail(SubmissionTrackingData submissionData) {
    if (submissionData.latestSubmission == null) {
      Get.snackbar(
        'Thông báo',
        'Sinh viên này chưa có bài nộp',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final submission = submissionData.latestSubmission!;

    Get.toNamed(
      Routes.SUBMISSION_DETAIL,
      arguments: {
        'submission': submission,
        'studentName': submissionData.fullName,
        'studentEmail': submissionData.email,
      },
    );
  }

  Widget _buildAttachments(BuildContext context) {
    if (assignment.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildModernSection(
      context,
      title: 'Tài liệu đính kèm',
      icon: Icons.attachment,
      children: assignment.attachments
          .map((att) => _buildAttachmentTile(context, att))
          .toList(),
    );
  }

  Widget _buildAttachmentTile(
      BuildContext context, AssignmentAttachment attachment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _getFileTypeColor(attachment.fileType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(attachment.fileType),
            color: _getFileTypeColor(attachment.fileType),
            size: 20,
          ),
        ),
        title: Text(
          attachment.fileName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatFileSize(attachment.fileSize),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (attachment.fileType != null)
              Text(
                attachment.fileType!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
        trailing: AppConfig.instance.isInstructor
            ? Icon(
                Icons.open_in_new,
                color: colorScheme.primary,
                size: 20,
              )
            : null,
        onTap: AppConfig.instance.isInstructor
            ? () => _openAttachmentInBrowser(attachment.fileUrl)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getFileTypeColor(String? fileType) {
    if (fileType == null) return Colors.grey;

    if (fileType.contains('pdf')) return Colors.red;
    if (fileType.contains('doc') || fileType.contains('word'))
      return Colors.blue;
    if (fileType.contains('image') ||
        fileType.contains('jpg') ||
        fileType.contains('png')) return Colors.green;
    if (fileType.contains('zip') || fileType.contains('rar'))
      return Colors.orange;
    if (fileType.contains('text') || fileType.contains('txt'))
      return Colors.purple;

    return Colors.grey;
  }

  IconData _getFileTypeIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;

    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('doc') || fileType.contains('word'))
      return Icons.description;
    if (fileType.contains('image') ||
        fileType.contains('jpg') ||
        fileType.contains('png')) return Icons.image;
    if (fileType.contains('zip') || fileType.contains('rar'))
      return Icons.archive;
    if (fileType.contains('text') || fileType.contains('txt'))
      return Icons.text_snippet;

    return Icons.insert_drive_file;
  }

  String _formatFileSize(int? fileSize) {
    if (fileSize == null) return 'Unknown size';

    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openAttachmentInBrowser(String fileUrl) async {
    try {
      final Uri url = Uri.parse(fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Lỗi', 'Không thể mở file. Vui lòng thử lại.');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể mở file: $e');
    }
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
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
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                    color: colorScheme.primary.withValues(alpha: 0.1),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
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

  void _showFilterDialog(
      BuildContext context, AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Filter Submissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
          children: const [
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

  Widget _buildGroupFilter(
      BuildContext context, AssignmentController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = assignment.groups;

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildModernSection(
      context,
      title: 'Lọc theo nhóm',
      icon: Icons.filter_list,
      children: [
        Obx(() {
          return DropdownButtonFormField<String?>(
            initialValue: controller.selectedGroupIdForSubmissions.isEmpty
                ? null
                : controller.selectedGroupIdForSubmissions,
            decoration: InputDecoration(
              labelText: 'Chọn nhóm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tất cả nhóm'),
              ),
              ...groups.map((group) => DropdownMenuItem<String?>(
                    value: group.id,
                    child: Text(group.name),
                  )),
            ],
            onChanged: (value) {
              controller.updateSelectedGroupIdForSubmissions(value);
              controller.loadAssignmentSubmissions(
                assignment.id,
                groupId: value ?? '',
              );
            },
          );
        }),
      ],
    );
  }
}
