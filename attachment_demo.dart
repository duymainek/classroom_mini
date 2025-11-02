import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Demo widget để test tính năng attachment
class AttachmentDemo extends StatelessWidget {
  const AttachmentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attachment Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAttachmentTile(
            context,
            'Sample PDF Document.pdf',
            'https://example.com/sample.pdf',
            1024000, // 1MB
            'application/pdf',
          ),
          const SizedBox(height: 16),
          _buildAttachmentTile(
            context,
            'Word Document.docx',
            'https://example.com/document.docx',
            512000, // 512KB
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
          const SizedBox(height: 16),
          _buildAttachmentTile(
            context,
            'Image File.jpg',
            'https://example.com/image.jpg',
            256000, // 256KB
            'image/jpeg',
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(
    BuildContext context,
    String fileName,
    String fileUrl,
    int fileSize,
    String fileType,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            color: _getFileTypeColor(fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(fileType),
            color: _getFileTypeColor(fileType),
            size: 20,
          ),
        ),
        title: Text(
          fileName,
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
              _formatFileSize(fileSize),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              fileType,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: colorScheme.primary,
          size: 20,
        ),
        onTap: () => _openAttachmentInBrowser(fileUrl),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
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

  IconData _getFileTypeIcon(String fileType) {
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

  String _formatFileSize(int fileSize) {
    if (fileSize < 1024) return '${fileSize} B';
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
        print('Cannot launch URL: $fileUrl');
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
  }
}
