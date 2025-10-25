import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import '../../controllers/announcement_controller.dart';

/**
 * Mobile Announcement Tracking View
 * Displays tracking data for announcement views
 */
class MobileAnnouncementTrackingView extends StatelessWidget {
  final String announcementId;
  final String announcementTitle;

  const MobileAnnouncementTrackingView({
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
              .loadAnnouncementTracking(announcementId);
        });
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Theo dõi thông báo',
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
                    controller.loadAnnouncementTracking(announcementId),
                tooltip: 'Làm mới',
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isTrackingLoading &&
                controller.trackingData.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildSummaryCard(context, controller),
                const SizedBox(height: 16),
                _buildFilterBar(context, controller),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildTrackingList(context, controller),
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
                  Icons.analytics,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tổng quan theo dõi',
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
                  title: 'Tổng số sinh viên',
                  value: controller.trackingData.length.toString(),
                  icon: Icons.people,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Đã xem',
                  value: controller.trackingData
                      .where((t) => t.viewed)
                      .length
                      .toString(),
                  icon: Icons.visibility,
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
                  title: 'Chưa xem',
                  value: controller.trackingData
                      .where((t) => !t.viewed)
                      .length
                      .toString(),
                  icon: Icons.visibility_off,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Tỷ lệ xem',
                  value: controller.trackingData.isNotEmpty
                      ? '${((controller.trackingData.where((t) => t.viewed).length / controller.trackingData.length) * 100).toStringAsFixed(1)}%'
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

  Widget _buildTrackingList(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (controller.trackingData.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.trackingData.length,
      itemBuilder: (context, index) {
        final tracking = controller.trackingData[index];
        return _buildTrackingItem(context, tracking);
      },
    );
  }

  Widget _buildTrackingItem(BuildContext context, StudentTracking tracking) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: tracking.viewed
                ? colorScheme.secondary.withOpacity(0.1)
                : colorScheme.error.withOpacity(0.1),
            child: Icon(
              tracking.viewed ? Icons.visibility : Icons.visibility_off,
              color:
                  tracking.viewed ? colorScheme.secondary : colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracking.student.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tracking.student.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tracking.group.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tracking.viewed
                      ? colorScheme.secondary.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tracking.viewed ? 'Đã xem' : 'Chưa xem',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tracking.viewed
                        ? colorScheme.secondary
                        : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (tracking.viewed && tracking.viewedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(tracking.viewedAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (tracking.viewCount > 1) ...[
                const SizedBox(height: 4),
                Text(
                  '${tracking.viewCount} lần',
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
              Icons.analytics_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu theo dõi',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dữ liệu theo dõi sẽ xuất hiện khi sinh viên xem thông báo',
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
        title: const Text('Bộ lọc theo dõi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Tính năng lọc sẽ được phát triển trong phiên bản tiếp theo'),
            const SizedBox(height: 16),
            const Text('Hiện tại có thể xem tất cả dữ liệu theo dõi'),
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
