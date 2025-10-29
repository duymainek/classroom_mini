import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/core/utils/timeago.dart';

/**
 * Forum Reply Widget
 * Shows individual reply with actions
 */
class ForumReplyWidget extends StatelessWidget {
  final ForumReply reply;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;

  const ForumReplyWidget({
    super.key,
    required this.reply,
    this.onReply,
    this.onLike,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author and time
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: reply.author.avatarUrl != null
                      ? NetworkImage(reply.author.avatarUrl!)
                      : null,
                  child: reply.author.avatarUrl == null
                      ? Text(reply.author.fullName
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          '')
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.fullName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        TimeAgo.format(reply.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              reply.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    reply.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: reply.isLiked ? Colors.red : Colors.grey[600],
                  ),
                  label: Text(
                    '${reply.likeCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: reply.isLiked ? Colors.red : Colors.grey[600],
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReply,
                  icon: Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                  label: Text(
                    'Reply',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),

            // Nested replies
            if (reply.replies != null && reply.replies!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(left: 16),
                child: Column(
                  children: reply.replies!.map((nestedReply) {
                    return ForumReplyWidget(
                      reply: nestedReply,
                      onReply: () => onReply?.call(),
                      onLike: () => onLike?.call(),
                      onDelete: () => onDelete?.call(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
