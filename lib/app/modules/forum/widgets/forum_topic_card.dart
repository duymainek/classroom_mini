import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/core/utils/timeago.dart';
import 'package:classroom_mini/app/modules/forum/design/forum_design_system.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_attachment_chips.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_controller.dart';

/**
 * Enhanced Forum Topic Card Widget
 * Implements Progressive Disclosure and Visual Hierarchy principles
 */
class ForumTopicCard extends StatefulWidget {
  final ForumTopic topic;
  final VoidCallback? onTap;

  const ForumTopicCard({
    super.key,
    required this.topic,
    this.onTap,
  });

  @override
  State<ForumTopicCard> createState() => _ForumTopicCardState();
}

class _ForumTopicCardState extends State<ForumTopicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ForumDesignSystem.animationFast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ForumAnimations.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: ForumDesignSystem.elevationMD,
      end: ForumDesignSystem.elevationLG,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ForumAnimations.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: EdgeInsets.only(bottom: ForumDesignSystem.spacingSM),
            elevation: _elevationAnimation.value,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              child: Container(
                padding: EdgeInsets.all(ForumDesignSystem.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and status indicators
                    _buildHeader(context),
                    SizedBox(height: ForumDesignSystem.spacingSM),

                    // Content preview with progressive disclosure
                    _buildContentPreview(context),
                    SizedBox(height: ForumDesignSystem.spacingMD),

                    // Footer with author and metadata
                    _buildFooter(context),
                    SizedBox(height: ForumDesignSystem.spacingMD),
                    // Attachment indicator
                    if (widget.topic.attachments != null &&
                        widget.topic.attachments!.isNotEmpty)
                      ForumAttachmentChips(
                        attachments: widget.topic.attachments!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final controller = Get.find<ForumController>();
    final isPending = controller.isTopicPending(widget.topic.id);
    
    return Obx(() {
      final stillPending = controller.isTopicPending(widget.topic.id);
      
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending sync indicator
          if (stillPending) ...[
            _buildStatusChip(
              context,
              icon: Icons.cloud_upload_outlined,
              label: 'Đang chờ đồng bộ',
              color: Colors.orange,
            ),
            SizedBox(width: ForumDesignSystem.spacingSM),
          ],
          
          // Topic status indicators
          if (widget.topic.isPinned) ...[
            _buildStatusChip(
              context,
              icon: Icons.push_pin,
              label: 'Pinned',
              color: ForumDesignSystem.warning,
            ),
            SizedBox(width: ForumDesignSystem.spacingSM),
          ],
          if (widget.topic.isLocked) ...[
            _buildStatusChip(
              context,
              icon: Icons.lock,
              label: 'Locked',
              color: ForumDesignSystem.error,
            ),
            SizedBox(width: ForumDesignSystem.spacingSM),
          ],

          // Title with proper hierarchy
          Expanded(
            child: Text(
              widget.topic.title,
              style: ForumDesignSystem.subheadingStyle.copyWith(
                color: ForumDesignSystem.getTextColor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContentPreview(BuildContext context) {
    return Text(
      widget.topic.content,
      style: ForumDesignSystem.bodyStyle.copyWith(
        color: ForumDesignSystem.getTextColor(context, isSecondary: true),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Author info with enhanced avatar
        _buildAuthorInfo(context),
        SizedBox(width: ForumDesignSystem.spacingMD),

        // Metadata with improved visual hierarchy
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildStatItem(
                context,
                icon: Icons.visibility_outlined,
                count: widget.topic.viewCount,
                label: 'views',
              ),
              SizedBox(width: ForumDesignSystem.spacingMD),
              _buildStatItem(
                context,
                icon: Icons.chat_bubble_outline,
                count: widget.topic.replyCount,
                label: 'replies',
              ),
              SizedBox(width: ForumDesignSystem.spacingMD),
              _buildTimeInfo(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: ForumDesignSystem.avatarSM / 2,
          backgroundColor: ForumDesignSystem.primary.withValues(alpha: 0.1),
          backgroundImage: widget.topic.author.avatarUrl != null
              ? NetworkImage(widget.topic.author.avatarUrl!)
              : null,
          child: widget.topic.author.avatarUrl == null
              ? Text(
                  widget.topic.author.fullName?.substring(0, 1).toUpperCase() ??
                      '',
                  style: ForumDesignSystem.captionStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ForumDesignSystem.primary,
                  ),
                )
              : null,
        ),
        SizedBox(width: ForumDesignSystem.spacingSM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic.author.fullName ?? '',
              style: ForumDesignSystem.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: ForumDesignSystem.getTextColor(context),
              ),
            ),
            Text(
              widget.topic.author.role?.toUpperCase() ?? '',
              style: ForumDesignSystem.captionStyle.copyWith(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ForumDesignSystem.iconSM,
          color: ForumDesignSystem.getTextColor(context, isSecondary: true),
        ),
        SizedBox(width: ForumDesignSystem.spacingXS),
        Text(
          count.toString(),
          style: ForumDesignSystem.captionStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: ForumDesignSystem.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Text(
      TimeAgo.format(widget.topic.createdAt),
      style: ForumDesignSystem.captionStyle.copyWith(
        color: ForumDesignSystem.getTextColor(context, isSecondary: true),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ForumDesignSystem.spacingSM,
        vertical: ForumDesignSystem.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ForumDesignSystem.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ForumDesignSystem.iconSM,
            color: color,
          ),
          SizedBox(width: ForumDesignSystem.spacingXS),
          Text(
            label,
            style: ForumDesignSystem.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
