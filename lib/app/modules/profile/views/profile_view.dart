import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
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
            _buildActionsCard(),
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
              backgroundImage: (user.avatarUrl != null && user.avatarUrl.isNotEmpty)
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.role ?? 'N/A',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
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
            Text('Account Information', style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
}
