import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'models/sync_operation.dart';

class SyncQueueManager {
  static const String _boxName = 'sync_queue';
  static Box<SyncOperation>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    _box = await Hive.openBox<SyncOperation>(_boxName);
    debugPrint('SyncQueueManager initialized. Pending operations: ${getPendingCount()}');
  }

  static Box<SyncOperation> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
          'SyncQueueManager not initialized. Call SyncQueueManager.init() first');
    }
    return _box!;
  }

  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final combined = '$timestamp-$random';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16);
  }

  static Future<String> add({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? data,
  }) async {
    try {
      final id = generateId();
      final operation = SyncOperation(
        id: id,
        method: method,
        path: path,
        queryParams: queryParams,
        data: data,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await box.put(id, operation);
      debugPrint('📥 Added to sync queue: $method $path (ID: $id)');
      return id;
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
      rethrow;
    }
  }

  static List<SyncOperation> getPending() {
    try {
      return box.values
          .where((op) => op.isPending)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error getting pending operations: $e');
      return [];
    }
  }

  static List<SyncOperation> getFailed() {
    try {
      return box.values
          .where((op) => op.isFailed)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error getting failed operations: $e');
      return [];
    }
  }

  static Future<void> markCompleted(String id) async {
    try {
      final operation = box.get(id);
      if (operation != null) {
        await box.put(
            id,
            operation.copyWith(
              status: 'completed',
            ));
        await box.delete(id);
        debugPrint('✅ Marked as completed: $id');
      }
    } catch (e) {
      debugPrint('Error marking as completed: $e');
    }
  }

  static Future<void> markFailed(String id, String errorMessage) async {
    try {
      final operation = box.get(id);
      if (operation != null) {
        final newRetryCount = operation.retryCount + 1;
        final status = newRetryCount >= 3 ? 'failed' : 'pending';

        await box.put(
            id,
            operation.copyWith(
              status: status,
              retryCount: newRetryCount,
              errorMessage: errorMessage,
              lastRetryAt: DateTime.now(),
            ));

        if (status == 'failed') {
          debugPrint('❌ Marked as failed (max retries): $id');
        } else {
          debugPrint('⚠️ Retry $newRetryCount/3 for: $id');
        }
      }
    } catch (e) {
      debugPrint('Error marking as failed: $e');
    }
  }

  static Future<void> remove(String id) async {
    try {
      await box.delete(id);
      debugPrint('🗑️ Removed from sync queue: $id');
    } catch (e) {
      debugPrint('Error removing from sync queue: $e');
    }
  }

  static Future<void> clear() async {
    try {
      await box.clear();
      debugPrint('🗑️ Cleared all sync queue');
    } catch (e) {
      debugPrint('Error clearing sync queue: $e');
    }
  }

  static Future<void> clearCompleted() async {
    try {
      final completedIds = box.values
          .where((op) => op.isCompleted)
          .map((op) => op.id)
          .toList();

      if (completedIds.isNotEmpty) {
        await box.deleteAll(completedIds);
        debugPrint('🗑️ Cleared ${completedIds.length} completed operations');
      }
    } catch (e) {
      debugPrint('Error clearing completed operations: $e');
    }
  }

  static int getPendingCount() {
    try {
      return box.values.where((op) => op.isPending).length;
    } catch (e) {
      return 0;
    }
  }

  static int getFailedCount() {
    try {
      return box.values.where((op) => op.isFailed).length;
    } catch (e) {
      return 0;
    }
  }

  static Map<String, dynamic> getStats() {
    final pending = getPendingCount();
    final failed = getFailedCount();
    final total = box.length;

    return {
      'total': total,
      'pending': pending,
      'failed': failed,
    };
  }
}

