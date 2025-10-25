import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/shared/controllers/shared_file_attachment_controller.dart';
import 'package:classroom_mini/app/shared/models/uploaded_attachment.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';

/**
 * Shared File Attachment Picker Widget
 * Reusable widget for file attachment picker across different modules
 */
class SharedFileAttachmentPicker extends StatefulWidget {
  final Function(List<UploadedAttachment>) onAttachmentsChanged;
  final int maxFiles;
  final int maxFileSizeMB;
  final List<String> allowedExtensions;
  final String tag; // Unique tag for GetX controller instance

  const SharedFileAttachmentPicker({
    Key? key,
    required this.onAttachmentsChanged,
    required this.tag,
    this.maxFiles = 10,
    this.maxFileSizeMB = 100,
    this.allowedExtensions = const [],
  }) : super(key: key);

  @override
  State<SharedFileAttachmentPicker> createState() =>
      _SharedFileAttachmentPickerState();
}

class _SharedFileAttachmentPickerState
    extends State<SharedFileAttachmentPicker> {
  late SharedFileAttachmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SharedFileAttachmentController(), tag: widget.tag);

    // Auto-configure based on tag
    if (widget.tag.contains('assignment')) {
      _controller.configureForAssignment();
    } else if (widget.tag.contains('announcement')) {
      _controller.configureForAnnouncement();
    } else if (widget.tag.contains('material')) {
      _controller.configureForMaterial();
    }

    // Set up callbacks
    _controller.setOnAttachmentUploaded(_onAttachmentUploaded);
    _controller.setOnAttachmentFailed(_onAttachmentFailed);

    // Listen to attachments changes
    _controller.attachments.listen((_) {
      widget.onAttachmentsChanged(_controller.attachments);
    });
  }

  @override
  void dispose() {
    Get.delete<SharedFileAttachmentController>(tag: widget.tag);
    super.dispose();
  }

  void _onAttachmentUploaded(SubmissionAttachment attachment) {
    // Handle successful upload
    print('Attachment uploaded: ${attachment.fileName}');
  }

  void _onAttachmentFailed(String error) {
    // Handle upload failure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final attachments = _controller.attachments;
      final canAddMore = _controller.canAddMoreFiles(widget.maxFiles);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tệp đính kèm',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (canAddMore)
                IconButton(
                  onPressed: () => _controller.pickFiles(
                    maxFiles: widget.maxFiles,
                    maxFileSizeMB: widget.maxFileSizeMB,
                    allowedExtensions: widget.allowedExtensions.isEmpty
                        ? null
                        : widget.allowedExtensions,
                  ),
                  icon: Icon(Icons.add, color: colorScheme.primary),
                  tooltip: 'Thêm tệp đính kèm',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // File list
          if (attachments.isEmpty)
            Container(
              width: double.infinity,
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
                    Icons.attach_file,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có tệp đính kèm nào',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để thêm tệp',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: attachments
                  .map((attachment) => _buildAttachmentCard(attachment))
                  .toList(),
            ),

          // Add more button if can add more files
          if (canAddMore && attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _controller.pickFiles(
                    maxFiles: widget.maxFiles,
                    maxFileSizeMB: widget.maxFileSizeMB,
                    allowedExtensions: widget.allowedExtensions.isEmpty
                        ? null
                        : widget.allowedExtensions,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm tệp khác'),
                ),
              ),
            ),

          // File size and format info
          if (widget.allowedExtensions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Định dạng cho phép: ${widget.allowedExtensions.join(', ').toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          Text(
            'Kích thước tối đa: ${widget.maxFileSizeMB}MB',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAttachmentCard(UploadedAttachment attachment) {
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
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _controller
                  .getFileTypeColor(
                    _controller.getCategoryFromMimeType(attachment.fileType),
                  )
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _controller.getFileTypeIcon(
                _controller.getCategoryFromMimeType(attachment.fileType),
              ),
              color: _controller.getFileTypeColor(
                _controller.getCategoryFromMimeType(attachment.fileType),
              ),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatFileSize(attachment.fileSize),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(attachment),
                  ],
                ),
                if (attachment.status == AttachmentUploadStatus.uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: attachment.uploadProgress ?? 0.0,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                if (attachment.hasFailed && attachment.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
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

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachment.hasFailed)
                IconButton(
                  onPressed: () => _controller.retryUpload(attachment),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Thử lại',
                ),
              IconButton(
                onPressed: () => _controller.removeAttachment(attachment),
                icon: const Icon(Icons.close),
                tooltip: 'Xóa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(UploadedAttachment attachment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color chipColor;
    Color textColor;
    String text;
    IconData? icon;

    switch (attachment.status) {
      case AttachmentUploadStatus.pending:
        chipColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        text = 'Chờ tải lên';
        icon = Icons.schedule;
        break;
      case AttachmentUploadStatus.uploading:
        chipColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        text = 'Đang tải lên';
        icon = Icons.upload;
        break;
      case AttachmentUploadStatus.uploaded:
        chipColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        text = 'Hoàn thành';
        icon = Icons.check;
        break;
      case AttachmentUploadStatus.failed:
        chipColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        text = 'Thất bại';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
