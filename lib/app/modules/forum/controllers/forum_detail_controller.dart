import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/forum_service.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/data/services/sync_service.dart';
import 'package:classroom_mini/app/data/local/sync_queue_manager.dart';
import 'package:classroom_mini/app/data/network/interceptors/offline_interceptor.dart';
import 'package:classroom_mini/app/core/services/auth_service.dart';

/// Forum Detail Controller
/// Manages forum topic detail and replies
class ForumDetailController extends GetxController {
  final ForumService _forumService = Get.find<ForumService>();
  final SyncService _syncService = Get.find<SyncService>();
  final AuthService _authService = Get.find<AuthService>();

  // State
  final Rxn<ForumTopic> topic = Rxn<ForumTopic>();
  final replies = <ForumReply>[].obs;
  final isLoading = false.obs;
  final isPostingReply = false.obs;

  // Track pending operations: queueId -> replyId mapping
  final pendingReplyQueueIds = <String, String>{}.obs;

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
    _setupSyncListener();
  }

  void _setupSyncListener() {
    ever(_syncService.completedQueueIds, (Set<String> completed) async {
      final completedQueueIds = completed.toSet();

      // Check if any completed queueIds are for replies in current topic
      final shouldReload = pendingReplyQueueIds.keys
          .any((queueId) => completedQueueIds.contains(queueId));

      // Remove completed queueIds from tracking
      pendingReplyQueueIds.removeWhere((queueId, replyId) {
        if (completedQueueIds.contains(queueId)) {
          return true;
        }
        if (!_syncService.isQueueIdPending(queueId)) {
          return true;
        }
        return false;
      });

      // Reload topic detail to get real replies after sync
      // This will automatically replace optimistic replies with real ones
      if (shouldReload && topicId != null) {
        debugPrint('🔄 Reloading topic detail after successful sync');
        Future.delayed(const Duration(milliseconds: 500), () {
          loadTopicDetail();
        });
      }
    });
  }

  bool isReplyPending(String replyId) {
    return pendingReplyQueueIds.values.contains(replyId);
  }

  void _trackViewAsync(String topicId) {
    _forumService.trackTopicView(topicId).then((success) {
      if (success) {
        debugPrint('✅ View tracked successfully');
      } else {
        debugPrint('⚠️ View tracking returned false');
      }
    }, onError: (error, stackTrace) {
      debugPrint('⚠️ Failed to track view: $error');
    });
  }

  /// Load topic with replies
  Future<void> loadTopicDetail() async {
    isLoading.value = true;

    try {
      // Track view async (fire and forget, will be queued if offline)
      _trackViewAsync(topicId!);

      // Get topic detail with replies (should use cache if available)
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

    final replyText = replyContent.value.trim();
    final now = DateTime.now();
    final currentUser = _authService.user.value;

    if (currentUser == null) {
      Get.snackbar('Error', 'User information not available');
      isPostingReply.value = false;
      return;
    }

    // Create optimistic reply immediately
    final optimisticReplyId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticReply = ForumReply(
      id: optimisticReplyId,
      topicId: topicId!,
      parentReplyId: replyingTo.value?.id,
      content: replyText,
      author: ForumAuthor(
        id: currentUser.id,
        fullName: currentUser.fullName,
        avatarUrl: currentUser.avatarUrl,
        role: currentUser.role,
      ),
      likeCount: 0,
      isLiked: false,
      createdAt: now,
      updatedAt: now,
      attachments: null,
      replies: null,
    );

    // Add optimistic reply to UI immediately
    if (replyingTo.value != null) {
      final parentIndex =
          replies.indexWhere((r) => r.id == replyingTo.value!.id);
      if (parentIndex != -1) {
        final updatedParent = replies[parentIndex];
        final updatedReplies =
            List<ForumReply>.from(updatedParent.replies ?? []);
        updatedReplies.add(optimisticReply);

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
      replies.add(optimisticReply);
    }

    // Clear input immediately for better UX
    replyContent.value = '';
    final replyingToParent = replyingTo.value;
    replyingTo.value = null;

    // Update reply count optimistically
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

    isPostingReply.value = false;

    try {
      // Call API (will be queued if offline)
      final response = await _forumService.addReply(
        topicId: topicId!,
        content: replyText,
        parentReplyId: replyingToParent?.id,
      );

      String? queueId;
      try {
        queueId = PendingOperationTracker.getLatestQueueIdForPath(
            '/forum/topics/$topicId/replies');
        if (queueId == null) {
          final pending = SyncQueueManager.getPending();
          final latestPending = pending
              .where((op) =>
                  op.method == 'POST' &&
                  op.path.contains('/forum/topics/$topicId/replies') &&
                  op.data?['content'] == replyText)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (latestPending.isNotEmpty) {
            queueId = latestPending.first.id;
            PendingOperationTracker.setQueueIdForPath(
                '/forum/topics/$topicId/replies', queueId);
          }
        }
        debugPrint('📴 Found pending reply queueId: $queueId');
      } catch (e) {
        debugPrint('⚠️ Error checking pending operations: $e');
      }

      // If response has data (online success), replace optimistic reply
      if (response.success && response.data != null) {
        final realReply = response.data!;

        // Remove optimistic reply
        if (replyingToParent != null) {
          final parentIndex =
              replies.indexWhere((r) => r.id == replyingToParent.id);
          if (parentIndex != -1) {
            final updatedParent = replies[parentIndex];
            final updatedReplies =
                List<ForumReply>.from(updatedParent.replies ?? []);
            updatedReplies.removeWhere((r) => r.id == optimisticReplyId);
            updatedReplies.add(realReply);

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
          replies.removeWhere((r) => r.id == optimisticReplyId);
          replies.add(realReply);
        }

        Get.snackbar('Success', 'Reply posted successfully');
      } else {
        // Offline case - track optimistic reply with queueId
        if (queueId != null) {
          pendingReplyQueueIds[queueId] = optimisticReplyId;
          debugPrint(
              '📴 Tracking pending optimistic reply: $optimisticReplyId -> $queueId');
          Get.snackbar(
              'Đã lưu', 'Phản hồi đã được lưu và sẽ được đồng bộ khi có mạng');
        }
      }
    } catch (e) {
      // Error case - still show optimistic reply but with pending status
      String? queueId;
      try {
        queueId = PendingOperationTracker.getLatestQueueIdForPath(
            '/forum/topics/$topicId/replies');
        if (queueId == null) {
          final pending = SyncQueueManager.getPending();
          final latestPending = pending
              .where((op) =>
                  op.method == 'POST' &&
                  op.path.contains('/forum/topics/$topicId/replies') &&
                  op.data?['content'] == replyText)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (latestPending.isNotEmpty) {
            queueId = latestPending.first.id;
            PendingOperationTracker.setQueueIdForPath(
                '/forum/topics/$topicId/replies', queueId);
          }
        }
      } catch (e2) {
        debugPrint('⚠️ Error checking pending operations: $e2');
      }

      if (queueId != null) {
        pendingReplyQueueIds[queueId] = optimisticReplyId;
        Get.snackbar(
            'Đã lưu', 'Phản hồi đã được lưu và sẽ được đồng bộ khi có mạng');
      } else {
        // If no queueId found, remove optimistic reply since it failed
        if (replyingToParent != null) {
          final parentIndex =
              replies.indexWhere((r) => r.id == replyingToParent.id);
          if (parentIndex != -1) {
            final updatedParent = replies[parentIndex];
            final updatedReplies =
                List<ForumReply>.from(updatedParent.replies ?? []);
            updatedReplies.removeWhere((r) => r.id == optimisticReplyId);

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
          replies.removeWhere((r) => r.id == optimisticReplyId);
        }

        // Revert reply count
        if (topic.value != null) {
          topic.value = ForumTopic(
            id: topic.value!.id,
            title: topic.value!.title,
            content: topic.value!.content,
            author: topic.value!.author,
            replyCount: topic.value!.replyCount - 1,
            viewCount: topic.value!.viewCount,
            isPinned: topic.value!.isPinned,
            isLocked: topic.value!.isLocked,
            createdAt: topic.value!.createdAt,
            updatedAt: topic.value!.updatedAt,
            attachments: topic.value!.attachments,
          );
        }

        Get.snackbar('Error', 'Failed to post reply: $e');
      }
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
