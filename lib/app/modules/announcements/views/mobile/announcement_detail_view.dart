import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import 'package:classroom_mini/app/data/models/request/announcement_request.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import 'package:classroom_mini/app/core/app_config.dart';
import '../../controllers/announcement_controller.dart';

/**
 * Mobile Announcement Detail View
 * Displays full announcement details with comments and tracking
 */
class MobileAnnouncementDetailView extends StatelessWidget {
  final Announcement announcement;

  const MobileAnnouncementDetailView({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AnnouncementController>(
      init: AnnouncementController(),
      initState: (_) {
        // Track view when opening detail
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<AnnouncementController>().trackView(announcement.id);
          Get.find<AnnouncementController>()
              .loadAnnouncementComments(announcement.id);
        });
      },
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildAssignedGroups(context),
                    const SizedBox(height: 16),
                    _buildContent(context),
                    const SizedBox(height: 16),
                    _buildAttachments(context),
                    const SizedBox(height: 16),
                    _buildMetaInfo(context),
                    const SizedBox(height: 16),
                    _buildTrackingOverview(context, controller),
                    const SizedBox(height: 16),
                    _buildComments(context, controller),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          announcement.title,
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
                colorScheme.secondaryContainer.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (AppConfig.instance.isInstructor)
          Obx(() {
            final connectivityService = Get.find<ConnectivityService>();
            if (!connectivityService.isOnline.value) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(Icons.edit, color: colorScheme.primary),
              onPressed: () => _navigateToEdit(),
            );
          }),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Thông tin thông báo',
      icon: Icons.campaign,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                announcement.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildScopeChip(context),
          ],
        ),
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
            announcement.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          icon: Icons.school,
          label: 'Khóa học',
          value: '${announcement.course.code} - ${announcement.course.name}',
        ),
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
        scopeText = 'Tất cả nhóm';
        scopeColor = colorScheme.tertiary;
        break;
      default:
        scopeText = 'Không xác định';
        scopeColor = colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scopeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scopeColor.withValues(alpha: 0.3),
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

  Widget _buildAssignedGroups(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (announcement.scopeType == 'all_groups') {
      return _buildModernSection(
        context,
        title: 'Nhóm được gán',
        icon: Icons.group,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.all_inclusive,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tất cả các nhóm trong khóa học',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (announcement.groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildModernSection(
      context,
      title: 'Nhóm được gán',
      icon: Icons.group,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: announcement.groups.map((group) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (announcement.groups.length > 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông báo này được gán cho ${announcement.groups.length} nhóm',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Nội dung',
      icon: Icons.description,
      children: [
        Text(
          announcement.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context) {
    if (announcement.files.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildModernSection(
      context,
      title: 'Tài liệu đính kèm',
      icon: Icons.attachment,
      children: announcement.files
          .map((file) => _buildAttachmentTile(context, file))
          .toList(),
    );
  }

  Widget _buildAttachmentTile(BuildContext context, AnnouncementFile file) {
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
            color: _getFileTypeColor(file.fileType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(file.fileType),
            color: _getFileTypeColor(file.fileType),
            size: 20,
          ),
        ),
        title: Text(
          file.fileName,
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
              _formatFileSize(file.fileSize),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (file.fileType != null)
              Text(
                file.fileType!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: colorScheme.primary,
          size: 20,
        ),
        onTap: () => _openFileInBrowser(file.fileUrl),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Thông tin bổ sung',
      icon: Icons.info,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.schedule,
          label: 'Ngày đăng',
          value: _formatDateTime(announcement.publishedAt),
        ),
        if (announcement.updatedAt != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.edit,
            label: 'Cập nhật lần cuối',
            value: _formatDateTime(announcement.updatedAt!),
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          icon: Icons.person,
          label: 'Người đăng',
          value: announcement.instructor.fullName,
        ),
      ],
    );
  }

  Widget _buildTrackingOverview(
      BuildContext context, AnnouncementController controller) {
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
                title: 'Lượt xem',
                value: announcement.viewCount.toString(),
                icon: Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Bình luận',
                value: announcement.commentCount.toString(),
                icon: Icons.comment,
                color: Theme.of(context).colorScheme.secondary,
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
                title: 'Tệp đính kèm',
                value: announcement.files.length.toString(),
                icon: Icons.attach_file,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Phạm vi',
                value: _getScopeDisplayText(),
                icon: Icons.group,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
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
    final colorScheme = theme.colorScheme;

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

  Widget _buildComments(
      BuildContext context, AnnouncementController controller) {
    return _buildModernSection(
      context,
      title: 'Bình luận',
      icon: Icons.comment,
      children: [
        _buildCommentInput(context, controller),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isCommentsLoading && controller.comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.comments.isEmpty) {
            return _buildEmptyComments(context);
          }

          return Column(
            children: controller.comments
                .map((comment) => _buildCommentItem(context, comment))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildCommentInput(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: 'Thêm bình luận...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => commentController.clear(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (commentController.text.trim().isNotEmpty) {
                    controller.addComment(
                      announcement.id,
                      AddCommentRequest(
                          commentText: commentController.text.trim()),
                    );
                    commentController.clear();
                  }
                },
                child: const Text('Bình luận'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments(BuildContext context) {
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
        children: [
          Icon(
            Icons.comment_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bình luận nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy là người đầu tiên bình luận!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, comment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  comment.user.fullName.isNotEmpty
                      ? comment.user.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (comment.user.role == 'instructor')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Giảng viên',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.commentText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
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

  String _formatFileSize(int fileSize) {
    if (fileSize < 1024) return '${fileSize} B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
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

  String _getScopeDisplayText() {
    switch (announcement.scopeType) {
      case 'one_group':
        return '1 nhóm';
      case 'multiple_groups':
        return '${announcement.groups.length} nhóm';
      case 'all_groups':
        return 'Tất cả';
      default:
        return 'Không xác định';
    }
  }

  Future<void> _openFileInBrowser(String fileUrl) async {
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

  void _navigateToTracking() {
    Get.toNamed(
      Routes.ANNOUNCEMENTS_TRACKING,
      arguments: {
        'announcementId': announcement.id,
        'announcementTitle': announcement.title,
      },
    );
  }

  void _navigateToFileTracking() {
    Get.toNamed(
      Routes.ANNOUNCEMENTS_FILE_TRACKING,
      arguments: {
        'announcementId': announcement.id,
        'announcementTitle': announcement.title,
      },
    );
  }

  void _navigateToEdit() async {
    final result =
        await Get.toNamed(Routes.ANNOUNCEMENTS_EDIT, arguments: announcement);
    if (result == true) {
      Get.find<AnnouncementController>().loadAnnouncements(refresh: true);
    }
  }
}
