import 'dart:async';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/notification_response.dart';
import 'package:classroom_mini/app/data/services/notification_api_service.dart';
import 'package:classroom_mini/app/data/services/api_service.dart'
    show DioClient;
import 'package:classroom_mini/app/core/utils/logger.dart' show AppLogger;

class NotificationService extends GetxService {
  final NotificationApiService _apiService;
  Timer? _pollingTimer;
  final unreadCount = 0.obs;
  final hasNewNotifications = false.obs;

  NotificationService() : _apiService = NotificationApiService(DioClient.dio);

  @override
  void onInit() {
    super.onInit();
    startPolling();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  void startPolling() {
    stopPolling();
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkNewNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> checkNewNotifications() async {
    try {
      final newCount = await getUnreadCount();
      if (newCount > unreadCount.value) {
        hasNewNotifications.value = true;
      }
      unreadCount.value = newCount;
    } catch (e) {
      AppLogger.error('Error checking new notifications: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _apiService.getNotifications(
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      );

      if (response.success && response.data?.notifications != null) {
        return response.data!.notifications!;
      }
      return [];
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();
      if (response.success && response.data?.unreadCount != null) {
        final count = response.data!.unreadCount!;
        unreadCount.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiService.markAsRead(id);
      if (response.success) {
        await checkNewNotifications();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllAsRead();
      if (response.success) {
        await checkNewNotifications();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiService.deleteNotification(id);
      if (response.success) {
        await checkNewNotifications();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting notification: $e');
      return false;
    }
  }

  Future<bool> deleteAllRead() async {
    try {
      final response = await _apiService.deleteAllRead();
      if (response.success) {
        await checkNewNotifications();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting all read notifications: $e');
      return false;
    }
  }
}
