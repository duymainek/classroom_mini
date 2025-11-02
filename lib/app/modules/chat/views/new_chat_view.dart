import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/new_chat_controller.dart';
import '../../../data/models/response/chat_response.dart';

class NewChatView extends StatelessWidget {
  const NewChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: controller.onSearchChanged,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.users.isEmpty) {
                return const Center(
                  child: Text('No users found'),
                );
              }

              return ListView.builder(
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  final user = controller.users[index];
                  return _UserTile(
                    user: user,
                    onTap: () => controller.startChat(user),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final SearchUserResponse user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.fullName[0].toUpperCase())
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text(user.role),
      trailing: user.existingRoomId != null
          ? const Icon(Icons.chat_bubble_outline, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

