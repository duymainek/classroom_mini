import 'package:classroom_mini/app/shared/models/uploaded_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';

/**
 * File preview widget supporting multiple file types
 * Following Material 3 design guide
 */
class FilePreviewWidget extends StatefulWidget {
  final UploadedAttachment attachment;
  final VoidCallback? onClose;

  const FilePreviewWidget({
    Key? key,
    required this.attachment,
    this.onClose,
  }) : super(key: key);

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  String? _previewContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      setState(() => _isLoading = true);

      final fileCategory = _getCategoryFromMimeType(widget.attachment.fileType);
      switch (fileCategory) {
        case 'images':
          await _loadImagePreview();
          break;
        case 'documents':
          await _loadDocumentPreview();
          break;
        case 'code':
          await _loadCodePreview();
          break;
        case 'archives':
          await _loadArchivePreview();
          break;
        default:
          setState(() {
            _error = 'Không thể xem trước định dạng này';
            _isLoading = false;
          });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải xem trước: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadImagePreview() async {
    // For images, we can show them directly
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDocumentPreview() async {
    // For documents, show basic info and download option
    setState(() {
      _previewContent =
          'Tài liệu: ${widget.attachment.fileName}\nKích thước: ${_formatFileSize(widget.attachment.fileSize)}';
      _isLoading = false;
    });
  }

  Future<void> _loadCodePreview() async {
    try {
      final file = File(widget.attachment.filePath);
      final content = await file.readAsString();

      // Limit preview to first 1000 characters
      final preview = content.length > 1000
          ? '${content.substring(0, 1000)}...\n\n[Hiển thị 1000 ký tự đầu tiên]'
          : content;

      setState(() {
        _previewContent = preview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể đọc file code: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArchivePreview() async {
    setState(() {
      _previewContent =
          'File nén: ${widget.attachment.fileName}\nKích thước: ${_formatFileSize(widget.attachment.fileSize)}\n\nKhông thể xem trước nội dung file nén.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
            child: Icon(
              _getFileTypeIcon(
                  _getCategoryFromMimeType(widget.attachment.fileType)),
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
                  widget.attachment.fileName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatFileSize(widget.attachment.fileSize)} • ${_getCategoryFromMimeType(widget.attachment.fileType).toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface,
            ),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Đang tải xem trước...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _downloadFile,
              icon: Icon(Icons.download),
              label: Text('Tải xuống'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildPreviewContent(context),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fileCategory = _getCategoryFromMimeType(widget.attachment.fileType);
    switch (fileCategory) {
      case 'images':
        return _buildImagePreview(context);
      case 'code':
        return _buildCodePreview(context);
      case 'documents':
      case 'archives':
      default:
        return _buildDocumentPreview(context);
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.attachment.filePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text('Không thể hiển thị hình ảnh'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodePreview(BuildContext context) {
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _previewContent ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileTypeIcon(
                _getCategoryFromMimeType(widget.attachment.fileType)),
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể xem trước',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _previewContent ?? 'Tệp này cần được tải xuống để xem',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _downloadFile,
            icon: Icon(Icons.download),
            label: Text('Tải xuống'),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'documents':
        return Icons.description;
      case 'images':
        return Icons.image;
      case 'archives':
        return Icons.archive;
      case 'videos':
        return Icons.video_file;
      case 'code':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getCategoryFromMimeType(String mimeType) {
    if (mimeType.startsWith('application/pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('presentation') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType == 'text/plain') {
      return 'documents';
    } else if (mimeType.startsWith('image/')) {
      return 'images';
    } else if (mimeType.startsWith('video/')) {
      return 'videos';
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return 'archives';
    } else if (mimeType.startsWith('text/') ||
        mimeType.contains('javascript') ||
        mimeType.contains('typescript')) {
      return 'code';
    }
    return 'other';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _downloadFile() {
    // Implement file download logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang tải xuống ${widget.attachment.fileName}'),
      ),
    );
  }
}
