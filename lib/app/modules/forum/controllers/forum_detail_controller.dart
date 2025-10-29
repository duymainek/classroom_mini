import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/forum_service.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';

/**
 * Forum Detail Controller
 * Manages forum topic detail and replies
 */
class ForumDetailController extends GetxController {
  final ForumService _forumService = Get.find<ForumService>();

  // State
  final Rxn<ForumTopic> topic = Rxn<ForumTopic>();
  final replies = <ForumReply>[].obs;
  final isLoading = false.obs;
  final isPostingReply = false.obs;

  // Reply input
  final replyContent = ''.obs;
  final replyingTo = Rxn<ForumReply>(); // For nested replies

  String? topicId;

  @override
  void onInit() {
    super.onInit();
    topicId = Get.parameters['id'] ?? Get.arguments?['topicId'];
    if (topicId != null) {
      loadTopicDetail();
    }
  }

  /// Load topic with replies
  Future<void> loadTopicDetail() async {
    isLoading.value = true;

    try {
      // Track view
      await _forumService.trackTopicView(topicId!);

      // Get topic detail with replies
      final response = await _forumService.getTopicById(topicId!);

      if (response.success && response.data != null) {
        topic.value = response.data!.topic;
        replies.value = response.data!.replies;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load topic: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Post reply
  Future<void> postReply() async {
    if (replyContent.value.trim().isEmpty) {
      Get.snackbar('Error', 'Reply cannot be empty');
      return;
    }

    if (replyContent.value.length > 500) {
      Get.snackbar('Error', 'Reply must be 500 characters or less');
      return;
    }

    isPostingReply.value = true;

    try {
      final response = await _forumService.addReply(
        topicId: topicId!,
        content: replyContent.value.trim(),
        parentReplyId: replyingTo.value?.id,
      );

      if (response.success && response.data != null) {
        // Add reply to list
        if (replyingTo.value != null) {
          // Nested reply - find parent and add to its replies
          final parentIndex =
              replies.indexWhere((r) => r.id == replyingTo.value!.id);
          if (parentIndex != -1) {
            final updatedParent = replies[parentIndex];
            final updatedReplies =
                List<ForumReply>.from(updatedParent.replies ?? []);
            updatedReplies.add(response.data!);

            // Update parent with new nested reply
            replies[parentIndex] = ForumReply(
              id: updatedParent.id,
              topicId: updatedParent.topicId,
              parentReplyId: updatedParent.parentReplyId,
              content: updatedParent.content,
              author: updatedParent.author,
              likeCount: updatedParent.likeCount,
              isLiked: updatedParent.isLiked,
              createdAt: updatedParent.createdAt,
              updatedAt: updatedParent.updatedAt,
              attachments: updatedParent.attachments,
              replies: updatedReplies,
            );
          }
        } else {
          // Top-level reply
          replies.add(response.data!);
        }

        // Clear input
        replyContent.value = '';
        replyingTo.value = null;

        // Update reply count
        if (topic.value != null) {
          topic.value = ForumTopic(
            id: topic.value!.id,
            title: topic.value!.title,
            content: topic.value!.content,
            author: topic.value!.author,
            replyCount: topic.value!.replyCount + 1,
            viewCount: topic.value!.viewCount,
            isPinned: topic.value!.isPinned,
            isLocked: topic.value!.isLocked,
            createdAt: topic.value!.createdAt,
            updatedAt: topic.value!.updatedAt,
            attachments: topic.value!.attachments,
          );
        }

        Get.snackbar('Success', 'Reply posted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to post reply: $e');
    } finally {
      isPostingReply.value = false;
    }
  }

  /// Set replying to (for nested replies)
  void setReplyingTo(ForumReply reply) {
    replyingTo.value = reply;
  }

  /// Cancel replying to
  void cancelReplyingTo() {
    replyingTo.value = null;
    replyContent.value = '';
  }

  /// Toggle like on reply
  Future<void> toggleLike(String replyId) async {
    try {
      final response = await _forumService.toggleLike(replyId);

      if (response.success && response.data != null) {
        // Update reply in list
        final index = replies.indexWhere((r) => r.id == replyId);
        if (index != -1) {
          final reply = replies[index];
          final newLikeCount = response.data!.isLiked
              ? reply.likeCount + 1
              : reply.likeCount - 1;

          replies[index] = ForumReply(
            id: reply.id,
            topicId: reply.topicId,
            parentReplyId: reply.parentReplyId,
            content: reply.content,
            author: reply.author,
            likeCount: newLikeCount,
            isLiked: response.data!.isLiked,
            createdAt: reply.createdAt,
            updatedAt: reply.updatedAt,
            attachments: reply.attachments,
            replies: reply.replies,
          );
        } else {
          // Check nested replies
          for (var i = 0; i < replies.length; i++) {
            final nestedIndex =
                replies[i].replies?.indexWhere((r) => r.id == replyId) ?? -1;
            if (nestedIndex != -1) {
              final parent = replies[i];
              final nested = parent.replies![nestedIndex];
              final newLikeCount = response.data!.isLiked
                  ? nested.likeCount + 1
                  : nested.likeCount - 1;

              final updatedNested = ForumReply(
                id: nested.id,
                topicId: nested.topicId,
                parentReplyId: nested.parentReplyId,
                content: nested.content,
                author: nested.author,
                likeCount: newLikeCount,
                isLiked: response.data!.isLiked,
                createdAt: nested.createdAt,
                updatedAt: nested.updatedAt,
                attachments: nested.attachments,
                replies: nested.replies,
              );

              final updatedRepliesList = List<ForumReply>.from(parent.replies!);
              updatedRepliesList[nestedIndex] = updatedNested;

              replies[i] = ForumReply(
                id: parent.id,
                topicId: parent.topicId,
                parentReplyId: parent.parentReplyId,
                content: parent.content,
                author: parent.author,
                likeCount: parent.likeCount,
                isLiked: parent.isLiked,
                createdAt: parent.createdAt,
                updatedAt: parent.updatedAt,
                attachments: parent.attachments,
                replies: updatedRepliesList,
              );
              break;
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to like reply: $e');
    }
  }

  /// Delete reply
  Future<void> deleteReply(String replyId) async {
    try {
      final success = await _forumService.deleteReply(replyId);

      if (success) {
        // Remove from list
        replies.removeWhere((r) => r.id == replyId);

        // Also check nested replies
        for (var i = 0; i < replies.length; i++) {
          if (replies[i].replies != null) {
            replies[i].replies!.removeWhere((r) => r.id == replyId);
          }
        }

        Get.snackbar('Success', 'Reply deleted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete reply: $e');
    }
  }

  /// Update topic
  Future<void> updateTopic(String newTitle, String newContent) async {
    try {
      final response = await _forumService.updateTopic(
        topicId: topicId!,
        title: newTitle,
        content: newContent,
      );

      if (response.success && response.data != null) {
        topic.value = response.data!;
        Get.snackbar('Success', 'Topic updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update topic: $e');
    }
  }

  /// Delete topic
  Future<void> deleteTopic() async {
    try {
      final success = await _forumService.deleteTopic(topicId!);
      if (success) {
        Get.back(); // Go back to forum feed
        Get.snackbar('Success', 'Topic deleted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete topic: $e');
    }
  }
}
