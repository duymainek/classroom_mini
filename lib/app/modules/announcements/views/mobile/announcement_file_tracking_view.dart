import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import '../../controllers/announcement_controller.dart';

/**
 * Mobile Announcement File Tracking View
 * Displays file download tracking data for announcements
 */
class MobileAnnouncementFileTrackingView extends StatelessWidget {
  final String announcementId;
  final String announcementTitle;

  const MobileAnnouncementFileTrackingView({
    Key? key,
    required this.announcementId,
    required this.announcementTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AnnouncementController>(
      init: AnnouncementController(),
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<AnnouncementController>()
              .loadAnnouncementFileTracking(announcementId);
        });
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Theo dõi file',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: colorScheme.primary),
                onPressed: () =>
                    controller.loadAnnouncementFileTracking(announcementId),
                tooltip: 'Làm mới',
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isFileTrackingLoading &&
                controller.fileTrackingData.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildSummaryCard(context, controller),
                const SizedBox(height: 16),
                _buildFilterBar(context, controller),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildFileTrackingList(context, controller),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.file_download,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tổng quan tải file',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Tổng file',
                  value: controller.fileTrackingData.length.toString(),
                  icon: Icons.attach_file,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Đã tải',
                  value: controller.fileTrackingData
                      .where((t) => t.downloads.isNotEmpty)
                      .length
                      .toString(),
                  icon: Icons.download,
                  color: colorScheme.secondary,
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
                  title: 'Chưa tải',
                  value: controller.fileTrackingData
                      .where((t) => t.downloads.isEmpty)
                      .length
                      .toString(),
                  icon: Icons.download_for_offline,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Tỷ lệ tải',
                  value: controller.fileTrackingData.isNotEmpty
                      ? '${((controller.fileTrackingData.where((t) => t.downloads.isNotEmpty).length / controller.fileTrackingData.length) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  icon: Icons.trending_up,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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

  Widget _buildFilterBar(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bộ lọc',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showFilterDialog(controller),
            icon: const Icon(Icons.tune),
            label: const Text('Tùy chỉnh'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTrackingList(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (controller.fileTrackingData.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.fileTrackingData.length,
      itemBuilder: (context, index) {
        final tracking = controller.fileTrackingData[index];
        return _buildFileTrackingItem(context, tracking);
      },
    );
  }

  Widget _buildFileTrackingItem(
      BuildContext context, FileTrackingData tracking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getFileTypeColor(tracking.file.fileName)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(tracking.file.fileName),
                  color: _getFileTypeColor(tracking.file.fileName),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.file.fileName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatFileSize(tracking.file.fileSize)} • ${tracking.file.fileType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tracking.downloads.isNotEmpty
                      ? colorScheme.secondary.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tracking.downloads.isNotEmpty ? 'Đã tải' : 'Chưa tải',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tracking.downloads.isNotEmpty
                        ? colorScheme.secondary
                        : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${tracking.totalDownloads} lượt tải',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              if (tracking.downloads.isNotEmpty) ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Lần cuối: ${_formatDateTime(tracking.downloads.first.downloadedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có file đính kèm',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thông báo này chưa có file đính kèm để theo dõi',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(AnnouncementController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Bộ lọc theo dõi file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Tính năng lọc sẽ được phát triển trong phiên bản tiếp theo'),
            const SizedBox(height: 16),
            const Text('Hiện tại có thể xem tất cả dữ liệu theo dõi file'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  Color _getFileTypeColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
        return Colors.teal;
      case 'zip':
      case 'rar':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
