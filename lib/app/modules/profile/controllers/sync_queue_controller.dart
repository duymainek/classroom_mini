import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/sync_queue_manager.dart';
import '../../../data/local/models/sync_operation.dart';

class SyncQueueController extends GetxController {
  final pendingOperations = <SyncOperation>[].obs;
  final failedOperations = <SyncOperation>[].obs;
  final isLoading = false.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    loadOperations();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadOperations();
    });
  }

  Future<void> loadOperations() async {
    try {
      pendingOperations.value = SyncQueueManager.getPending();
      failedOperations.value = SyncQueueManager.getFailed();
    } catch (e) {
      debugPrint('Error loading sync operations: $e');
    }
  }

  Future<void> retryOperation(SyncOperation operation) async {
    try {
      isLoading.value = true;
      await SyncQueueManager.add(
        method: operation.method,
        path: operation.path,
        queryParams: operation.queryParams,
        data: operation.data,
      );
      await SyncQueueManager.remove(operation.id);
      await loadOperations();
      Get.snackbar(
        'Thành công',
        'Đã thêm lại vào hàng đợi',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thử lại: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeOperation(SyncOperation operation) async {
    try {
      isLoading.value = true;
      await SyncQueueManager.remove(operation.id);
      await loadOperations();
      Get.snackbar(
        'Thành công',
        'Đã xóa khỏi hàng đợi',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAll() async {
    try {
      isLoading.value = true;
      await SyncQueueManager.clear();
      await loadOperations();
      Get.snackbar(
        'Thành công',
        'Đã xóa tất cả',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return 'POST';
      case 'PUT':
        return 'PUT';
      case 'DELETE':
        return 'DELETE';
      default:
        return method;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
