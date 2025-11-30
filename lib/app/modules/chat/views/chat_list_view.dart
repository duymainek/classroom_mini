import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/chat_list_controller.dart';
import '../../../data/models/response/chat_response.dart';
import '../../../data/services/connectivity_service.dart';
import 'package:classroom_mini/app/core/widgets/responsive_container.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatListController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (controller.totalUnreadCount.value > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${controller.totalUnreadCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child: Obx(() {
        if (controller.isLoading.value && controller.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No conversations yet'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => controller.openNewChat(),
                  child: const Text('Start a new conversation'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadConversations(refresh: true),
          child: ListView.builder(
            itemCount: controller.conversations.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AiChatBotTile(
                  onTap: () => Get.toNamed(Routes.CHAT_AI),
                );
              }
              final conversation = controller.conversations[index - 1];
              return _ConversationTile(
                conversation: conversation,
                onTap: () => controller.openChatRoom(conversation),
                onLongPress: () =>
                    controller.hideConversation(conversation.roomId),
              );
            },
          ),
        );
        }),
      ),
      floatingActionButton: Obx(() {
        final connectivityService = Get.find<ConnectivityService>();
        if (!connectivityService.isOnline.value) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          heroTag: 'chat_fab',
          onPressed: () => controller.openNewChat(),
          child: const Icon(Icons.chat),
        );
      }),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationResponse conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.displayAvatar != null
            ? CachedNetworkImageProvider(conversation.displayAvatar!)
            : null,
        child: conversation.displayAvatar == null
            ? Text(conversation.displayName[0].toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.otherUser?.isOnline == true)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Text(
        conversation.lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? Colors.black87 : Colors.grey,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!.displayTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _AiChatBotTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AiChatBotTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.smart_toy, color: Colors.white),
      ),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'AI Chat bot',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      subtitle: const Text(
        'Hỗ trợ học tập với AI',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
