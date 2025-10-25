import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/announcement_controller.dart';
import '../../widgets/announcement_card.dart';

/**
 * Mobile Announcement List View
 * Displays list of announcements with modern UI design
 */
class MobileAnnouncementListView extends StatelessWidget {
  const MobileAnnouncementListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<AnnouncementController>(
      init: AnnouncementController(),
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, controller),
              _buildFilterBar(context, controller),
              _buildAnnouncementsList(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AnnouncementController controller) {
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
          'Thông báo',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: colorScheme.primary),
          onPressed: _navigateToCreateAnnouncement,
          tooltip: 'Tạo thông báo mới',
        ),
        IconButton(
          icon: Icon(Icons.search, color: colorScheme.primary),
          onPressed: () => _showSearchDialog(controller),
          tooltip: 'Tìm kiếm thông báo',
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: colorScheme.primary),
          onPressed: () => _showFilterDialog(controller),
          tooltip: 'Lọc thông báo',
        ),
      ],
    );
  }

  Widget _buildFilterBar(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => DropdownButtonFormField<String>(
                    value: controller.scopeFilter,
                    decoration: InputDecoration(
                      labelText: 'Phạm vi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(
                          value: 'one_group', child: Text('Một nhóm')),
                      DropdownMenuItem(
                          value: 'multiple_groups', child: Text('Nhiều nhóm')),
                      DropdownMenuItem(
                          value: 'all_groups', child: Text('Tất cả nhóm')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.filterByScope(value);
                      }
                    },
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => DropdownButtonFormField<String>(
                    value: controller.sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sắp xếp',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'published_at', child: Text('Ngày đăng')),
                      DropdownMenuItem(value: 'title', child: Text('Tiêu đề')),
                      DropdownMenuItem(
                          value: 'updated_at', child: Text('Cập nhật')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.sortAnnouncements(
                            value, controller.sortOrder);
                      }
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList(
      BuildContext context, AnnouncementController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: Obx(() {
        if (controller.isLoading && controller.announcements.isEmpty) {
          return SliverFillRemaining(
            child: Center(
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
            ),
          );
        }

        if (controller.announcements.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(context),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= controller.announcements.length) {
                return _buildLoadingIndicator();
              }

              final announcement = controller.announcements[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AnnouncementCard(
                  announcement: announcement,
                  onTap: () => _navigateToAnnouncementDetail(announcement),
                  onTrack: () => _navigateToAnnouncementTracking(announcement),
                  onDelete: () =>
                      _showDeleteConfirmation(controller, announcement),
                ),
              );
            },
            childCount:
                controller.announcements.length + (controller.hasMore ? 1 : 0),
          ),
        );
      }),
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
              Icons.campaign,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông báo nào',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo thông báo đầu tiên để bắt đầu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreateAnnouncement,
              icon: const Icon(Icons.add),
              label: const Text('Tạo thông báo'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: _navigateToCreateAnnouncement,
      icon: const Icon(Icons.add),
      label: const Text('Tạo thông báo'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  void _showSearchDialog(AnnouncementController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tìm kiếm thông báo'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa tìm kiếm...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            controller.searchAnnouncements(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAnnouncements(refresh: true);
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(AnnouncementController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Lọc thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String>(
                  title: const Text('Tất cả'),
                  value: 'all',
                  groupValue: controller.scopeFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByScope(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Một nhóm'),
                  value: 'one_group',
                  groupValue: controller.scopeFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByScope(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Nhiều nhóm'),
                  value: 'multiple_groups',
                  groupValue: controller.scopeFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByScope(value);
                  },
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text('Tất cả nhóm'),
                  value: 'all_groups',
                  groupValue: controller.scopeFilter,
                  onChanged: (value) {
                    if (value != null) controller.filterByScope(value);
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.loadAnnouncements(refresh: true);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateAnnouncement() async {
    final result = await Get.toNamed(Routes.ANNOUNCEMENTS_CREATE);
    if (result == true) {
      final controller = Get.find<AnnouncementController>();
      controller.loadAnnouncements(refresh: true);
    }
  }

  void _navigateToAnnouncementDetail(announcement) {
    Get.toNamed(Routes.ANNOUNCEMENTS_DETAIL, arguments: announcement);
  }

  void _navigateToAnnouncementTracking(announcement) {
    Get.toNamed(
      Routes.ANNOUNCEMENTS_TRACKING,
      arguments: {
        'announcementId': announcement.id,
        'announcementTitle': announcement.title,
      },
    );
  }

  void _showDeleteConfirmation(
      AnnouncementController controller, announcement) {
    controller.showDeleteConfirmation(announcement);
  }
}
