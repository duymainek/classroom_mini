import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';

/**
 * Announcement Card Widget
 * Displays announcement information in a modern card format
 */
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showDeleteButton;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    this.onTap,
    this.onTrack,
    this.onDelete,
    this.showActions = true,
    this.showDeleteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              const SizedBox(height: 12),
              _buildMetaInfo(context),
              const SizedBox(height: 12),
              _buildStats(context),
              if (showActions) ...[
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.campaign,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            announcement.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildScopeChip(context),
      ],
    );
  }

  Widget _buildScopeChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String scopeText;
    Color scopeColor;

    switch (announcement.scopeType) {
      case 'one_group':
        scopeText = 'Một nhóm';
        scopeColor = colorScheme.primary;
        break;
      case 'multiple_groups':
        scopeText = 'Nhiều nhóm';
        scopeColor = colorScheme.secondary;
        break;
      case 'all_groups':
        scopeText = 'Tất cả';
        scopeColor = colorScheme.tertiary;
        break;
      default:
        scopeText = 'Không xác định';
        scopeColor = colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scopeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scopeColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        scopeText,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scopeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        announcement.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.school,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${announcement.course.code} - ${announcement.course.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDateTime(announcement.publishedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (announcement.groups.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.groups.map((g) => g.name).join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (announcement.files.isNotEmpty) ...[
          _buildStatChip(
            context,
            icon: Icons.attach_file,
            label: '${announcement.files.length} tệp',
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        _buildStatChip(
          context,
          icon: Icons.visibility,
          label: '${announcement.viewCount} lượt xem',
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          icon: Icons.comment,
          label: '${announcement.commentCount} bình luận',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Spacer(),
        Obx(() {
          final connectivityService = Get.find<ConnectivityService>();
          if (!connectivityService.isOnline.value) {
            return const SizedBox.shrink();
          }
          if (showDeleteButton && onDelete != null) {
            return Row(
              children: [
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete,
                    color: colorScheme.error,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.errorContainer.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  tooltip: 'Xóa thông báo',
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
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
