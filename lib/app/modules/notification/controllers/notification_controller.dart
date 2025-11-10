import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/notification_service.dart';
import 'package:classroom_mini/app/data/models/response/notification_response.dart'
    show NotificationModel;
import 'package:classroom_mini/app/routes/app_routes.dart' show Routes;

class NotificationController extends GetxController {
  final NotificationService _notificationService = Get.find<NotificationService>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool unreadOnly = false.obs;
  final RxInt unreadCount = 0.obs;

  int _currentOffset = 0;
  final int _limit = 50;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
    _listenToUnreadCount();
  }

  void _listenToUnreadCount() {
    ever(_notificationService.unreadCount, (int count) {
      unreadCount.value = count;
    });
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (isLoading.value) return;

    isLoading.value = true;
    error.value = '';

    if (refresh) {
      _currentOffset = 0;
      notifications.clear();
      _hasMore = true;
    }

    try {
      final result = await _notificationService.getNotifications(
        limit: _limit,
        offset: _currentOffset,
        unreadOnly: unreadOnly.value,
      );

      if (refresh) {
        notifications.value = result;
      } else {
        notifications.addAll(result);
      }

      _currentOffset += result.length;
      _hasMore = result.length >= _limit;
    } catch (e) {
      error.value = 'Failed to load notifications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
    await loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      error.value = 'Failed to load unread count: $e';
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final success = await _notificationService.markAsRead(id);
      if (success) {
        final index = notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final notification = notifications[index];
          notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            data: notification.data,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = 'Failed to mark notification as read: $e';
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success) {
        notifications.value = notifications.map((n) {
          if (!n.isRead) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = 'Failed to mark all notifications as read: $e';
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final success = await _notificationService.deleteNotification(id);
      if (success) {
        notifications.removeWhere((n) => n.id == id);
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = 'Failed to delete notification: $e';
    }
  }

  Future<void> deleteAllRead() async {
    try {
      final success = await _notificationService.deleteAllRead();
      if (success) {
        notifications.removeWhere((n) => n.isRead);
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = 'Failed to delete all read notifications: $e';
    }
  }

  void toggleUnreadOnly() {
    unreadOnly.value = !unreadOnly.value;
    loadNotifications(refresh: true);
  }

  Future<void> handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }

    final actionUrl = notification.actionUrl;
    if (actionUrl != null && actionUrl.isNotEmpty) {
      if (actionUrl.contains('/student/assignments/')) {
        final parts = actionUrl.split('/');
        final assignmentId = parts.last.split('/').first;
        final data = notification.data;
        if (data != null && data.containsKey('assignment_id')) {
          Get.toNamed(Routes.ASSIGNMENTS_DETAIL, arguments: {'id': assignmentId});
        }
      } else if (actionUrl.contains('/student/quizzes/')) {
        // Handle URL format: /student/quizzes/{quizId}/submissions/{submissionId}
        final data = notification.data;
        String? submissionId;
        
        // Try to get submissionId from URL first
        if (actionUrl.contains('/submissions/')) {
          final parts = actionUrl.split('/submissions/');
          if (parts.length > 1) {
            submissionId = parts.last.split('?').first.split('#').first;
          }
        }
        
        // Fallback to data if URL parsing fails
        if (submissionId == null || submissionId.isEmpty) {
          submissionId = data?['submission_id'] as String?;
        }
        
        // Navigate to submission detail if we have submissionId
        if (submissionId != null && submissionId.isNotEmpty) {
          Get.toNamed(Routes.QUIZ_SUBMISSION_DETAIL, arguments: {'submissionId': submissionId});
        } else if (data != null && data.containsKey('quiz_id')) {
          // Fallback to quiz detail if no submissionId
          final quizId = data['quiz_id'] as String;
          Get.toNamed(Routes.QUIZZES_DETAIL, arguments: {'id': quizId});
        }
      } else if (actionUrl.contains('/student/announcements/')) {
        final parts = actionUrl.split('/');
        final announcementId = parts.last.split('?').first.split('#').first;
        if (announcementId.isNotEmpty) {
          Get.toNamed(Routes.ANNOUNCEMENTS_DETAIL, arguments: {'id': announcementId});
        }
      } else if (actionUrl.contains('/student/materials/')) {
        final parts = actionUrl.split('/');
        final materialId = parts.last;
        Get.toNamed(Routes.MATERIALS_DETAIL.replaceAll(':id', materialId));
      } else if (actionUrl.contains('/forum/topics/')) {
        final parts = actionUrl.split('/');
        final topicId = parts.last.split('#').first;
        Get.toNamed(Routes.FORUM_DETAIL.replaceAll(':id', topicId));
      }
    }
  }

  void loadMore() {
    if (!isLoading.value && _hasMore) {
      loadNotifications();
    }
  }
}
