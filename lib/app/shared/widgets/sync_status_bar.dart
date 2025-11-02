import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/sync_service.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    final syncService = Get.find<SyncService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;
      final pendingCount = syncService.pendingCount.value;
      final failedCount = syncService.failedCount.value;
      final isSyncing = syncService.isSyncing;

      if (isOnline && pendingCount == 0 && failedCount == 0 && !isSyncing) {
        return const SizedBox.shrink();
      }

      Color backgroundColor;
      IconData iconData;
      String message;

      if (!isOnline) {
        if (pendingCount > 0) {
          backgroundColor = Colors.orange;
          iconData = Icons.cloud_off;
          message = '📴 Offline: $pendingCount thay đổi đang chờ';
        } else {
          backgroundColor = Colors.grey;
          iconData = Icons.cloud_off;
          message = '📴 Offline';
        }
      } else if (isSyncing) {
        backgroundColor = Colors.blue;
        iconData = Icons.sync;
        message = '🔄 Đang đồng bộ...';
      } else if (failedCount > 0) {
        backgroundColor = Colors.red;
        iconData = Icons.error_outline;
        message = '⚠️ Đồng bộ thất bại: $failedCount mục';
      } else if (pendingCount > 0) {
        backgroundColor = Colors.orange;
        iconData = Icons.cloud_queue;
        message = '⏳ $pendingCount thay đổi đang chờ đồng bộ';
      } else {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(iconData, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (failedCount > 0) ...[
              const Spacer(),
              TextButton(
                onPressed: () => syncService.retryFailed(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

