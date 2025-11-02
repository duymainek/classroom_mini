import 'package:classroom_mini/app/modules/forum/widgets/forum_attachment_chips.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/core/utils/timeago.dart';

/**
 * Forum Topic Header Widget
 * Shows topic title, content, author, and metadata
 */
class ForumTopicHeader extends StatelessWidget {
  final ForumTopic topic;

  const ForumTopicHeader({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              topic.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Author and time
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: topic.author.avatarUrl != null
                      ? NetworkImage(topic.author.avatarUrl!)
                      : null,
                  child: topic.author.avatarUrl == null
                      ? Text(topic.author.fullName
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
                        topic.author.fullName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        TimeAgo.format(topic.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              topic.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Metadata
            Row(
              children: [
                _buildStatItem(
                  context,
                  Icons.visibility,
                  '${topic.viewCount}',
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context,
                  Icons.comment,
                  '${topic.replyCount}',
                ),
                if (topic.attachments != null &&
                    topic.attachments!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    Icons.attach_file,
                    '${topic.attachments!.length}',
                  ),
                ],
              ],
            ),

            // Attachments (if any)
            if (topic.attachments != null && topic.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ForumAttachmentChips(attachments: topic.attachments!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
