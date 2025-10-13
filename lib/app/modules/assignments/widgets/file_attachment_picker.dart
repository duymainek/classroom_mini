import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/assignments/models/uploaded_attachment.dart';
import 'package:classroom_mini/app/modules/assignments/controllers/file_attachment_controller.dart';

/**
 * Enhanced file attachment picker with immediate upload functionality
 * Following Material 3 design guide
 */
/// FileAttachmentPicker sử dụng GetX state từ controller
class FileAttachmentPicker extends GetView<FileAttachmentController> {
  final int maxFiles;
  final int maxFileSizeMB;
  final List<String> allowedExtensions;
  final void Function(List<UploadedAttachment>)? onAttachmentsChanged;

  FileAttachmentPicker({
    Key? key,
    this.onAttachmentsChanged,
    this.maxFiles = 5,
    this.maxFileSizeMB = 10,
    this.allowedExtensions = const [],
  }) : super(key: key);

  static const Map<String, List<String>> _supportedExtensions = {
    'documents': ['pdf', 'docx', 'doc', 'pptx', 'ppt', 'xlsx', 'xls', 'txt'],
    'images': ['jpg', 'jpeg', 'png', 'gif'],
    'archives': ['zip', 'rar'],
    'videos': ['mp4', 'mov', 'avi'],
    'code': ['py', 'c', 'cpp', 'java', 'js', 'ts', 'html', 'css'],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Test AssignmentController availability
    try {
      Get.find<FileAttachmentController>();
    } catch (e) {
      print('ERROR: FileAttachmentController not available in build: $e');
    }

    // Ensure controller is registered
    if (!Get.isRegistered<FileAttachmentController>()) {
      Get.put(FileAttachmentController(), permanent: false);
    }

    // Note: tránh đăng ký listener trong build để không tạo subscription lặp

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
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
                  child: Icon(
                    Icons.attach_file,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tệp đính kèm',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Tối đa ${maxFiles} tệp, mỗi tệp ${maxFileSizeMB}MB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.canAddMoreFiles(maxFiles)
                      ? () async {
                          await controller.pickFiles(
                            maxFiles: maxFiles,
                            maxFileSizeMB: maxFileSizeMB,
                            allowedExtensions: allowedExtensions,
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.add,
                    color: controller.canAddMoreFiles(maxFiles)
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  tooltip: controller.canAddMoreFiles(maxFiles)
                      ? 'Thêm tệp'
                      : 'Đã đạt tối đa ${maxFiles} tệp',
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              // Propagate attachments to parent when changed
              if (onAttachmentsChanged != null) {
                onAttachmentsChanged!(controller.attachments.toList());
              }

              return Column(
                children: [
                  // Debug info (remove in production)
                  if (controller.attachments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Debug: ${controller.attachments.length} tệp • ${controller.attachments.where((a) => a.isUploaded).length} đã tải lên',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),

                  if (controller.attachments.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildAttachmentList(context),
                  const SizedBox(height: 16),
                  _buildSupportedFormats(context),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tệp đính kèm',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm tệp hoặc kéo thả tệp vào đây',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentList(BuildContext context) {
    return Column(
      children: controller.attachments.map((attachment) {
        return _buildAttachmentItem(context, attachment);
      }).toList(),
    );
  }

  Widget _buildAttachmentItem(
      BuildContext context, UploadedAttachment attachment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller
                      .getFileTypeColor(controller
                          .getCategoryFromMimeType(attachment.fileType))
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.getFileTypeIcon(
                      controller.getCategoryFromMimeType(attachment.fileType)),
                  color: controller.getFileTypeColor(
                      controller.getCategoryFromMimeType(attachment.fileType)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatFileSize(attachment.fileSize),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Status indicator
                    _buildStatusIndicator(context, attachment),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(context, attachment),
            ],
          ),
          if (attachment.status == AttachmentUploadStatus.uploading)
            Column(
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: attachment.uploadProgress,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đang tải lên...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${((attachment.uploadProgress ?? 0.0) * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (attachment.status == AttachmentUploadStatus.failed &&
              attachment.errorMessage != null)
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attachment.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // Success indicator for uploaded files
          if (attachment.status == AttachmentUploadStatus.uploaded)
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tải lên thành công • ${attachment.attachmentId ?? 'N/A'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
      BuildContext context, UploadedAttachment attachment) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (attachment.status) {
      case AttachmentUploadStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Đang chờ';
        break;
      case AttachmentUploadStatus.uploading:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_upload;
        statusText = 'Đang tải lên';
        break;
      case AttachmentUploadStatus.uploaded:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã tải lên';
        break;
      case AttachmentUploadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Thất bại';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, UploadedAttachment attachment) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (attachment.status) {
      case AttachmentUploadStatus.pending:
        return Icon(
          Icons.schedule,
          color: colorScheme.outline,
          size: 20,
        );
      case AttachmentUploadStatus.uploading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
            value: attachment.uploadProgress,
          ),
        );
      case AttachmentUploadStatus.uploaded:
        return Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
      case AttachmentUploadStatus.failed:
        return Icon(
          Icons.error,
          color: colorScheme.error,
          size: 20,
        );
    }
  }

  Widget _buildActionButton(
      BuildContext context, UploadedAttachment attachment) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (attachment.status) {
      case AttachmentUploadStatus.pending:
      case AttachmentUploadStatus.uploading:
        return IconButton(
          onPressed: () => controller.removeAttachment(attachment),
          icon: Icon(
            Icons.close,
            color: colorScheme.error,
            size: 20,
          ),
          tooltip: 'Hủy',
        );
      case AttachmentUploadStatus.uploaded:
        return IconButton(
          onPressed: () => controller.removeAttachment(attachment),
          icon: Icon(
            Icons.close,
            color: colorScheme.error,
            size: 20,
          ),
          tooltip: 'Xóa tệp',
        );
      case AttachmentUploadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => controller.retryUpload(attachment),
              icon: Icon(
                Icons.refresh,
                color: colorScheme.primary,
                size: 20,
              ),
              tooltip: 'Thử lại',
            ),
            IconButton(
              onPressed: () => controller.removeAttachment(attachment),
              icon: Icon(
                Icons.close,
                color: colorScheme.error,
                size: 20,
              ),
              tooltip: 'Xóa',
            ),
          ],
        );
    }
  }

  Widget _buildSupportedFormats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Định dạng được hỗ trợ:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _supportedExtensions.entries.map((entry) {
              return Chip(
                label: Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
