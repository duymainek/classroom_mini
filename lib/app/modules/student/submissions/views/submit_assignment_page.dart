import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/submit_assignment_controller.dart';

class SubmitAssignmentPage extends GetView<SubmitAssignmentController> {
  const SubmitAssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Nộp bài tập'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Đang tải...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.assignment.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy bài tập',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final shouldShowSubmissionForm = controller.canSubmit ||
            (controller.mySubmissions.isEmpty &&
                controller.remainingAttempts > 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssignmentInfoCard(context),
              const SizedBox(height: 16),
              _buildAttemptInfo(context),
              if (shouldShowSubmissionForm) ...[
                const SizedBox(height: 16),
                _buildSubmissionForm(context),
              ],
              const SizedBox(height: 16),
              _buildPreviousSubmissions(context),
              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() => _buildBottomButtons()),
    );
  }

  Widget _buildAssignmentInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assignment = controller.assignment.value!;
    final now = DateTime.now();
    final dueDate = assignment.dueDate;
    final isOverdue = now.isAfter(dueDate);
    final timeUntilDue = dueDate.difference(now);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
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
          // Header
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
                  child: Icon(Icons.assignment,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thông tin bài tập',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (assignment.description != null &&
                    assignment.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildDeadlineInfo(
                  context,
                  dueDate: dueDate,
                  lateDueDate: assignment.lateDueDate,
                  isOverdue: isOverdue,
                  timeUntilDue: timeUntilDue,
                ),
                if (assignment.fileFormats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFileRequirements(context, assignment),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineInfo(
    BuildContext context, {
    required DateTime dueDate,
    DateTime? lateDueDate,
    required bool isOverdue,
    required Duration timeUntilDue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (controller.isPastDeadline) {
      statusColor = Colors.red;
      statusText = 'Deadline Passed';
      statusIcon = Icons.cancel;
    } else if (controller.isLateSubmission) {
      statusColor = Colors.orange;
      statusText = 'Late Submission';
      statusIcon = Icons.warning;
    } else if (timeUntilDue.inHours < 24) {
      statusColor = Colors.orange;
      statusText = 'Due Soon';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = 'On Time';
      statusIcon = Icons.check_circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Due: ${DateFormat('MMM dd, yyyy HH:mm').format(dueDate)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        if (lateDueDate != null) ...[
          Text(
            'Late Due: ${DateFormat('MMM dd, yyyy HH:mm').format(lateDueDate)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
        if (!isOverdue && timeUntilDue.inDays > 0) ...[
          Text(
            '${timeUntilDue.inDays} days remaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileRequirements(BuildContext context, assignment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'File Requirements',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Allowed formats: ${assignment.fileFormats.join(', ')}',
            style: TextStyle(color: Colors.grey[800], fontSize: 13),
          ),
          Text(
            'Max size: ${assignment.maxFileSize}MB per file',
            style: TextStyle(color: Colors.grey[800], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final canSubmit = controller.canSubmit;
    final bgColor = canSubmit
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
        : colorScheme.errorContainer.withValues(alpha: 0.3);
    final iconColor = canSubmit ? colorScheme.tertiary : colorScheme.error;
    final borderColor = canSubmit
        ? colorScheme.tertiary.withValues(alpha: 0.3)
        : colorScheme.error.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              canSubmit ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canSubmit
                      ? 'Lần ${controller.currentAttempts + 1}/${controller.maxAttempts}'
                      : 'Lần ${controller.currentAttempts}/${controller.maxAttempts}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canSubmit
                      ? '${controller.remainingAttempts} lượt nộp còn lại'
                      : controller.isPastDeadline
                          ? 'Đã hết hạn nộp bài'
                          : 'Đã hết lượt nộp',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
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
          // Header
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
                  child: Icon(Icons.edit_document,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bài nộp của bạn',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội dung bài làm',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.submissionTextController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung bài làm hoặc ghi chú (tùy chọn)',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildFileUploadSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  controller.isSubmitting.value ? null : controller.pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Files'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.selectedFiles.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No files selected',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              ...controller.selectedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return _buildFileItem(file, index);
              }),
              if (controller.isUploading.value) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.uploadProgress.value,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(controller.uploadProgress.value * 100).toInt()}% uploaded',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFileItem(file, int index) {
    final fileName = file.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFileIcon(fileName),
          color: Colors.blue,
        ),
        title: Text(fileName),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => controller.removeFile(index),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildPreviousSubmissions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Obx(() {
      if (controller.mySubmissions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Card(
        elevation: 2,
        child: ExpansionTile(
          title: Text(
            'Previous Submissions (${controller.mySubmissions.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: controller.mySubmissions.map((submission) {
            return ListTile(
              leading: Icon(
                _getSubmissionIcon(submission.status),
                color: _getSubmissionColor(submission.status),
              ),
              title: Text('Attempt ${submission.attemptNumber}'),
              subtitle: submission.submittedAt != null
                  ? Text(
                      '${DateFormat('MMM dd, yyyy HH:mm').format(submission.submittedAt!)}\n'
                      '${submission.status.displayName}${submission.isGraded ? ' - ${submission.gradeDisplay}' : ''}',
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => controller.viewSubmission(submission),
            );
          }).toList(),
        ),
      );
    });
  }

  IconData _getSubmissionIcon(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.graded:
        return Icons.grade;
      case SubmissionStatus.late:
        return Icons.schedule;
      case SubmissionStatus.submitted:
        return Icons.check_circle;
      case SubmissionStatus.notSubmitted:
        return Icons.cancel;
    }
  }

  Color _getSubmissionColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.graded:
        return Colors.green;
      case SubmissionStatus.late:
        return Colors.orange;
      case SubmissionStatus.submitted:
        return Colors.blue;
      case SubmissionStatus.notSubmitted:
        return Colors.red;
    }
  }

  Widget _buildBottomButtons() {
    final theme = Theme.of(Get.context!);
    final colorScheme = theme.colorScheme;

    // Determine button state and message
    final bool isDisabled =
        !controller.canSubmit || controller.isSubmitting.value;
    String buttonText = 'Nộp bài';
    String? disabledReason;

    if (controller.isPastDeadline) {
      buttonText = 'Hết hạn nộp';
      disabledReason = 'Đã quá hạn nộp bài';
    } else if (controller.remainingAttempts <= 0) {
      buttonText = 'Hết lượt nộp';
      disabledReason = 'Bạn đã sử dụng hết số lần nộp bài';
    } else if (controller.isLateSubmission) {
      buttonText = 'Nộp bài (Trễ)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show disabled reason if any
            if (disabledReason != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        disabledReason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        controller.isSubmitting.value ? null : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: isDisabled ? null : controller.submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          controller.isLateSubmission && !isDisabled
                              ? Colors.orange
                              : null,
                      disabledBackgroundColor:
                          colorScheme.surfaceContainerHighest,
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDisabled ? Icons.block : Icons.upload_file,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(buttonText),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
