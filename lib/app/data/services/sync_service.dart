import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:dio/dio.dart' as dio_pkg show Response;
import 'package:flutter/material.dart';
import '../local/sync_queue_manager.dart';
import '../local/models/sync_operation.dart';
import '../services/connectivity_service.dart';
import '../services/api_service.dart';
import '../../core/utils/logger.dart';

class SyncService extends GetxService {
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  Dio get _dioClient => DioClient.dio;
  
  bool _isSyncing = false;
  Timer? _retryTimer;
  
  final syncStatus = 'idle'.obs;
  final pendingCount = 0.obs;
  final failedCount = 0.obs;
  final completedQueueIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _updateCounts();
    _startListening();
  }


  void _updateCounts() {
    pendingCount.value = SyncQueueManager.getPendingCount();
    failedCount.value = SyncQueueManager.getFailedCount();
  }
  
  bool isQueueIdPending(String queueId) {
    final pending = SyncQueueManager.getPending();
    return pending.any((op) => op.id == queueId);
  }
  
  bool isQueueIdCompleted(String queueId) {
    return completedQueueIds.contains(queueId);
  }

  void _startListening() {
    ever(_connectivityService.isOnline, (bool isOnline) {
      if (isOnline) {
        debugPrint('📡 Network online - triggering sync');
        Future.delayed(const Duration(milliseconds: 500), () {
          syncQueue();
        });
      }
    });
  }

  Future<void> syncQueue() async {
    if (_isSyncing) {
      debugPrint('⏸️ Sync already in progress, skipping');
      return;
    }

    if (!_connectivityService.isOnline.value) {
      debugPrint('📴 Offline - cannot sync');
      return;
    }

    final pending = SyncQueueManager.getPending();
    if (pending.isEmpty) {
      debugPrint('✅ No pending operations to sync');
      _updateCounts();
      return;
    }

    _isSyncing = true;
    syncStatus.value = 'syncing';
    debugPrint('🔄 Starting sync: ${pending.length} operations');

    int successCount = 0;
    int failCount = 0;

    for (final operation in pending) {
      try {
        if (!_connectivityService.isOnline.value) {
          debugPrint('📴 Lost connection during sync');
          break;
        }

        await _syncOperation(operation);
        successCount++;
      } catch (e) {
        failCount++;
        AppLogger.error('Failed to sync operation ${operation.id}', error: e);
      }
    }

    _isSyncing = false;
    syncStatus.value = 'idle';
    _updateCounts();

    debugPrint('✅ Sync completed: $successCount succeeded, $failCount failed');
    
    if (successCount > 0) {
      Get.snackbar(
        'Đồng bộ thành công',
        'Đã đồng bộ $successCount thay đổi',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }

    if (failCount > 0) {
      Get.snackbar(
        'Đồng bộ thất bại',
        '$failCount thay đổi không thể đồng bộ',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _syncOperation(SyncOperation operation) async {
    try {
      debugPrint('🔄 Syncing: ${operation.method} ${operation.path} (ID: ${operation.id})');

      dio_pkg.Response response;

      switch (operation.method.toUpperCase()) {
        case 'POST':
          response = await _dioClient.post(
            operation.path,
            data: operation.data,
            queryParameters: operation.queryParams,
          );
          break;

        case 'PUT':
          response = await _dioClient.put(
            operation.path,
            data: operation.data,
            queryParameters: operation.queryParams,
          );
          break;

        case 'DELETE':
          response = await _dioClient.delete(
            operation.path,
            data: operation.data,
            queryParameters: operation.queryParams,
          );
          break;

        default:
          throw Exception('Unsupported method: ${operation.method}');
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        await SyncQueueManager.markCompleted(operation.id);
        completedQueueIds.add(operation.id);
        debugPrint('✅ Synced successfully: ${operation.id}');
        
        Future.delayed(const Duration(seconds: 2), () {
          completedQueueIds.remove(operation.id);
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          debugPrint('⚠️ Conflict (409) - Server wins: ${operation.id}');
          await SyncQueueManager.markCompleted(operation.id);
          completedQueueIds.add(operation.id);
          Future.delayed(const Duration(seconds: 2), () {
            completedQueueIds.remove(operation.id);
          });
          return;
        }
      }

      final errorMessage = e.toString();
      await SyncQueueManager.markFailed(operation.id, errorMessage);

      if (operation.retryCount < 2) {
        final delay = _getRetryDelay(operation.retryCount);
        debugPrint('⏳ Retrying in ${delay.inSeconds}s: ${operation.id}');
        Future.delayed(delay, () => _syncOperation(operation));
      } else {
        debugPrint('❌ Max retries reached: ${operation.id}');
      }
    }
  }

  Duration _getRetryDelay(int retryCount) {
    switch (retryCount) {
      case 0:
        return const Duration(seconds: 5);
      case 1:
        return const Duration(seconds: 15);
      case 2:
        return const Duration(seconds: 30);
      default:
        return const Duration(seconds: 30);
    }
  }

  Future<void> retryFailed() async {
    final failed = SyncQueueManager.getFailed()
        .where((op) => op.canRetry)
        .toList();

    if (failed.isEmpty) {
      Get.snackbar('Thông báo', 'Không có thao tác nào cần thử lại');
      return;
    }

    for (final operation in failed) {
      await SyncQueueManager.add(
        method: operation.method,
        path: operation.path,
        queryParams: operation.queryParams,
        data: operation.data,
      );
      await SyncQueueManager.remove(operation.id);
    }

    await syncQueue();
  }

  Future<void> clearFailed() async {
    final failed = SyncQueueManager.getFailed();
    for (final operation in failed) {
      await SyncQueueManager.remove(operation.id);
    }
    _updateCounts();
  }

  bool get hasPending => pendingCount.value > 0;
  bool get hasFailed => failedCount.value > 0;
  bool get isSyncing => _isSyncing;

  @override
  void onClose() {
    _retryTimer?.cancel();
    super.onClose();
  }
}

