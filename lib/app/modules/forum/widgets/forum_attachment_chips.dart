import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom_mini/app/modules/forum/design/forum_design_system.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';

class ForumAttachmentChips extends StatelessWidget {
  final List<ForumAttachment> attachments;

  const ForumAttachmentChips({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: ForumDesignSystem.spacingXS,
      runSpacing: ForumDesignSystem.spacingXS,
      children: attachments
          .map((attachment) => _AttachmentChip(attachment: attachment))
          .toList(),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final ForumAttachment attachment;

  const _AttachmentChip({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAttachment(context, attachment),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ForumDesignSystem.spacingSM,
          vertical: ForumDesignSystem.spacingXS,
        ),
        decoration: BoxDecoration(
          color: ForumDesignSystem.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ForumDesignSystem.radiusPill),
          border: Border.all(color: ForumDesignSystem.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(attachment.fileType),
              size: ForumDesignSystem.iconSM,
              color: ForumDesignSystem.primary,
            ),
            SizedBox(width: ForumDesignSystem.spacingXS),
            Flexible(
              child: Text(
                attachment.fileName,
                style: ForumDesignSystem.captionStyle.copyWith(
                  color: ForumDesignSystem.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: ForumDesignSystem.spacingXS),
            Text(
              attachment.fileSizeFormatted,
              style: ForumDesignSystem.captionStyle.copyWith(
                color: ForumDesignSystem.primary.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAttachment(BuildContext context, ForumAttachment attachment) async {
    try {
      final url = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở file: ${attachment.fileName}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'application/pdf':
        return Icons.picture_as_pdf;
      case 'application/msword':
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return Icons.description;
      case 'application/vnd.ms-excel':
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return Icons.table_chart;
      case 'application/vnd.ms-powerpoint':
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return Icons.slideshow;
      case 'image/jpeg':
      case 'image/png':
      case 'image/gif':
      case 'image/webp':
        return Icons.image;
      case 'video/mp4':
      case 'video/avi':
      case 'video/mov':
        return Icons.videocam;
      case 'audio/mp3':
      case 'audio/wav':
        return Icons.audiotrack;
      case 'application/zip':
      case 'application/x-rar-compressed':
        return Icons.archive;
      case 'text/plain':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }
}
