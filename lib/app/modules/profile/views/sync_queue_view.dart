import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/models/sync_operation.dart';
import '../controllers/sync_queue_controller.dart';

class SyncQueueView extends GetView<SyncQueueController> {
  const SyncQueueView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue'),
        centerTitle: true,
        actions: [
          Obx(() {
            final hasOperations = controller.pendingOperations.isNotEmpty ||
                controller.failedOperations.isNotEmpty;
            if (!hasOperations) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Xóa tất cả'),
                    content: const Text(
                        'Bạn có chắc muốn xóa tất cả các thao tác trong hàng đợi?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Get.back();
                          controller.clearAll();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.pendingOperations.isEmpty &&
            controller.failedOperations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pendingOperations.isEmpty &&
            controller.failedOperations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có thao tác nào trong hàng đợi',
                  style: Get.textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tất cả các thay đổi đã được đồng bộ',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadOperations,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (controller.failedOperations.isNotEmpty) ...[
                _buildSectionHeader(
                  'Thất bại (${controller.failedOperations.length})',
                  Icons.error_outline,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                ...controller.failedOperations
                    .map((op) => _buildOperationCard(op, isFailed: true))
                    .toList(),
                const SizedBox(height: 24),
              ],
              if (controller.pendingOperations.isNotEmpty) ...[
                _buildSectionHeader(
                  'Đang chờ (${controller.pendingOperations.length})',
                  Icons.cloud_queue,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                ...controller.pendingOperations
                    .map((op) => _buildOperationCard(op, isFailed: false))
                    .toList(),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationCard(SyncOperation operation,
      {required bool isFailed}) {
    final methodColor = _getMethodColor(operation.method);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFailed ? Colors.red.shade300 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor['color']?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: methodColor['color'] as Color,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    operation.method.toUpperCase(),
                    style: TextStyle(
                      color: methodColor['color'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    operation.path,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.formatDateTime(operation.createdAt),
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (operation.retryCount > 0) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Thử lại: ${operation.retryCount}/3',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ],
            ),
            if (operation.errorMessage != null &&
                operation.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        operation.errorMessage!,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (operation.data != null && operation.data!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Dữ liệu', style: TextStyle(fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatJson(operation.data),
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isFailed) ...[
                  TextButton.icon(
                    onPressed: () => controller.retryOperation(operation),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Thử lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Xóa thao tác'),
                        content: const Text(
                            'Bạn có chắc muốn xóa thao tác này khỏi hàng đợi?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Get.back();
                              controller.removeOperation(operation);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return {'color': Colors.green};
      case 'PUT':
        return {'color': Colors.blue};
      case 'DELETE':
        return {'color': Colors.red};
      default:
        return {'color': Colors.grey};
    }
  }

  String _formatJson(Map<String, dynamic>? data) {
    if (data == null) return '';
    final buffer = StringBuffer();
    for (final entry in data.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}
