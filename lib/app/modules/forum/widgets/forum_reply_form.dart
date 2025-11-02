import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';

/**
 * Forum Reply Form Widget
 * Input form for posting replies
 */
class ForumReplyForm extends StatelessWidget {
  final String content;
  final ForumReply? replyingTo;
  final bool isPosting;
  final ValueChanged<String> onContentChanged;
  final VoidCallback onPost;
  final VoidCallback onCancelReply;

  const ForumReplyForm({
    super.key,
    required this.content,
    this.replyingTo,
    required this.isPosting,
    required this.onContentChanged,
    required this.onPost,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replying to indicator
          if (replyingTo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${replyingTo!.author.fullName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCancelReply,
                    icon: Icon(Icons.close, size: 16, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Input field
          TextField(
            key: ValueKey(content.isEmpty),
            onChanged: onContentChanged,
            decoration: InputDecoration(
              hintText:
                  replyingTo != null ? 'Write a reply...' : 'Write a reply...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),

          // Post button
          Obx(() {
            final connectivityService = Get.find<ConnectivityService>();
            if (!connectivityService.isOnline.value) {
              return const SizedBox.shrink();
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (replyingTo != null) ...[
                  TextButton(
                    onPressed: onCancelReply,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed:
                      content.trim().isNotEmpty && !isPosting ? onPost : null,
                  child: isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
