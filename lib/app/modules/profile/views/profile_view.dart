import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/services/sync_service.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (controller.user.value != null) {
                Get.to(() => EditProfileView(user: controller.user.value!));
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }

        final user = controller.user.value;
        if (user == null) {
          return const Center(child: Text('No user data found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),
            _buildAccountInfoCard(user),
            const SizedBox(height: 16),
            _buildNetworkSimulationCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
            const SizedBox(height: 16),
            _buildCacheManagementCard(),
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (user.avatarUrl != null && user.avatarUrl.isNotEmpty)
                      ? CachedNetworkImageProvider(user.avatarUrl)
                      : null,
              child: (user.avatarUrl == null || user.avatarUrl.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            Material(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: controller.uploadAvatar,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName ?? 'N/A',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.role ?? 'N/A',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard(dynamic user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Information',
                style: Get.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Username'),
              subtitle: Text(user.username ?? 'N/A'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user.email ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red)),
        onTap: () {
          Get.dialog(
            AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Get.find<AuthService>().logout();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkSimulationCard() {
    final connectivityService = Get.find<ConnectivityService>();
    final syncService = Get.find<SyncService>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Network Simulation',
                  style: Get.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Obx(() {
            final isOnline = connectivityService.isOnline.value;
            final isManualOverride = connectivityService.isManualOverride.value;
            final pendingCount = syncService.pendingCount.value;
            final failedCount = syncService.failedCount.value;
            final isSyncing = syncService.isSyncing;

            return Column(
              children: [
                SwitchListTile(
                  title: const Text('Giả lập Offline'),
                  subtitle: Text(
                    isManualOverride
                        ? (isOnline
                            ? 'Đang giả lập Online'
                            : 'Đang giả lập Offline')
                        : 'Đang dùng kết nối thực tế',
                  ),
                  value: !isOnline,
                  secondary: Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    color: isOnline ? Colors.green : Colors.orange,
                  ),
                  onChanged: (bool value) {
                    connectivityService.setManualOverride(!value);
                  },
                ),
                if (isManualOverride) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextButton.icon(
                      onPressed: () {
                        connectivityService.clearManualOverride();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Khôi phục kết nối thực tế'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
                if (!isOnline && (pendingCount > 0 || failedCount > 0)) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              pendingCount > 0
                                  ? Icons.cloud_queue
                                  : Icons.error_outline,
                              size: 16,
                              color:
                                  pendingCount > 0 ? Colors.orange : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sync Queue',
                              style: Get.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pendingCount > 0)
                          Text(
                            '⏳ Đang chờ: $pendingCount thao tác',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        if (failedCount > 0)
                          Text(
                            '❌ Thất bại: $failedCount thao tác',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        if (isSyncing)
                          Text(
                            '🔄 Đang đồng bộ...',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCacheManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.storage, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Cache Management',
                  style: Get.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.orange),
            title: const Text('Clear All Cache'),
            subtitle: const Text('Xóa tất cả dữ liệu đã cache từ các request'),
            onTap: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Clear All Cache'),
                  content: const Text(
                      'Bạn có chắc muốn xóa toàn bộ cache? Ứng dụng sẽ cần tải lại dữ liệu từ server.'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await DioClient.clearAllCache();
                          Get.back();
                          Get.snackbar(
                            'Thành công',
                            'Đã xóa toàn bộ cache',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                            duration: const Duration(seconds: 2),
                          );
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Lỗi',
                            'Không thể xóa cache: $e',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.red.shade800,
                            duration: const Duration(seconds: 3),
                          );
                        }
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
