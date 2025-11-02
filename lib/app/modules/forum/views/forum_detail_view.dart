import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_detail_controller.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_reply_widget.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_reply_form.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_topic_header.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_attachment_chips.dart';

/**
 * Forum Detail View
 * Shows topic detail with replies
 */
class ForumDetailView extends GetView<ForumDetailController> {
  const ForumDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          Obx(() {
            final connectivityService = Get.find<ConnectivityService>();
            if (!connectivityService.isOnline.value) {
              return const SizedBox.shrink();
            }
            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context);
                    break;
                  case 'delete':
                    _showDeleteDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Topic'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete Topic'),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final topic = controller.topic.value;
        if (topic == null) {
          return const Center(child: Text('Topic not found'));
        }

        return Column(
          children: [
            // Topic header
            ForumTopicHeader(topic: topic),

            // Replies list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.replies.length,
                itemBuilder: (context, index) {
                  final reply = controller.replies[index];
                  return ForumReplyWidget(
                    reply: reply,
                    onReply: () => controller.setReplyingTo(reply),
                    onLike: () => controller.toggleLike(reply.id),
                    onDelete: () => controller.deleteReply(reply.id),
                  );
                },
              ),
            ),

            // Reply form
            ForumReplyForm(
              content: controller.replyContent.value,
              replyingTo: controller.replyingTo.value,
              isPosting: controller.isPostingReply.value,
              onContentChanged: (value) =>
                  controller.replyContent.value = value,
              onPost: controller.postReply,
              onCancelReply: controller.cancelReplyingTo,
            ),
          ],
        );
      }),
    );
  }

  void _showEditDialog(BuildContext context) {
    final topic = controller.topic.value!;
    final titleController = TextEditingController(text: topic.title);
    final contentController = TextEditingController(text: topic.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.updateTopic(
                titleController.text.trim(),
                contentController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: const Text(
            'Are you sure you want to delete this topic? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteTopic();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
