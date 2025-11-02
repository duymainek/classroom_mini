import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'package:classroom_mini/app/modules/materials/controllers/material_detail_controller.dart';
import '../../widgets/material_file_attachment_widget.dart';

/**
 * Material Detail View
 * Displays detailed information about a material with modern UI design
 * Features: Progressive disclosure, visual hierarchy, file attachments display
 */
class MaterialDetailView extends StatefulWidget {
  final String materialId;

  const MaterialDetailView({
    Key? key,
    required this.materialId,
  }) : super(key: key);

  @override
  State<MaterialDetailView> createState() => _MaterialDetailViewState();
}

class _MaterialDetailViewState extends State<MaterialDetailView> {
  late MaterialDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MaterialDetailController());
    controller.loadMaterialDetail(widget.materialId);
  }

  @override
  void dispose() {
    Get.delete<MaterialDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Chi tiết tài liệu',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        actions: [
          Obx(() {
            if (controller.material.value != null) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editMaterial();
                      break;
                    case 'delete':
                      _deleteMaterial();
                      break;
                    case 'share':
                      _shareMaterial();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined),
                        SizedBox(width: 12),
                        Text('Chia sẻ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.material.value == null) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadMaterialDetail(widget.materialId),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMaterialHeader(),
                const SizedBox(height: 24),
                _buildMaterialInfo(),
                const SizedBox(height: 24),
                _buildAttachmentsSection(),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildMetadataSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMaterialHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = controller.material.value!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tài liệu khóa học',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description if available
          if (material.description != null &&
              material.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      material.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = controller.material.value!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thông tin tài liệu',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Course information
          _buildInfoRow(
            icon: Icons.school_outlined,
            label: 'Khóa học',
            value: '${material.course.code} - ${material.course.name}',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Instructor information
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Giảng viên',
            value: material.instructor.fullName,
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // View count
          _buildInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Lượt xem',
            value: '${material.viewCount} lượt',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = controller.material.value!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment_outlined,
                  color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tài liệu đính kèm',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${material.files.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (material.files.isEmpty)
            _buildEmptyAttachments()
          else
            MaterialFileAttachmentWidget(
              files: material.files,
              onFileTap: (file) => _handleFileTap(file),
              onFileDownload: (file) => _handleFileDownload(file),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAttachments() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.attachment_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có tài liệu đính kèm',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tài liệu này chưa có file đính kèm nào',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = controller.material.value!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thống kê cơ bản',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_outlined,
                  label: 'Lượt xem',
                  value: '${material.viewCount}',
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attachment_outlined,
                  label: 'Tệp đính kèm',
                  value: '${material.files.length}',
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = controller.material.value!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_outlined,
                  color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thông tin thời gian',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.add_circle_outline,
            label: 'Ngày tạo',
            value: _formatDate(material.createdAt),
            colorScheme: colorScheme,
            theme: theme,
          ),
          if (material.updatedAt != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.update_outlined,
              label: 'Cập nhật lần cuối',
              value: _formatDate(material.updatedAt!),
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể tải tài liệu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadMaterialDetail(widget.materialId),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy tài liệu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tài liệu này có thể đã bị xóa hoặc không tồn tại',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay lúc ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua lúc ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editMaterial() {
    // TODO: Navigate to edit material
    Get.snackbar(
      'Thông báo',
      'Chức năng chỉnh sửa tài liệu sẽ được triển khai',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _deleteMaterial() {
    // TODO: Show delete confirmation dialog
    Get.snackbar(
      'Thông báo',
      'Chức năng xóa tài liệu sẽ được triển khai',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _shareMaterial() {
    // TODO: Show share options
    Get.snackbar(
      'Thông báo',
      'Chức năng chia sẻ tài liệu sẽ được triển khai',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleFileTap(material_resp.MaterialFile file) async {
    try {
      final Uri url = Uri.parse(file.fileUrl);

      // File view tracking removed - no longer needed

      // Check if URL can be launched
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Mở trong browser
        );

        Get.snackbar(
          'Thành công',
          'Đã mở tệp: ${file.fileName}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể mở tệp: ${file.fileName}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi mở tệp: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleFileDownload(material_resp.MaterialFile file) async {
    try {
      final Uri url = Uri.parse(file.fileUrl);

      // File download tracking removed - no longer needed

      // Check if URL can be launched
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Mở trong browser để download
        );

        Get.snackbar(
          'Thành công',
          'Đang tải xuống: ${file.fileName}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể tải xuống tệp: ${file.fileName}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi tải xuống: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
