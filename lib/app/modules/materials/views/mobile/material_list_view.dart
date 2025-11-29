import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'package:classroom_mini/app/modules/materials/controllers/material_controller.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';
import '../../widgets/material_card.dart';
import '../../widgets/material_form.dart';
import 'package:classroom_mini/app/core/widgets/responsive_container.dart';

/**
 * Material List View
 * Displays list of materials with modern UI design following UX best practices
 * Features: Progressive disclosure, visual hierarchy, consistent interactions
 */
class MaterialListView extends StatefulWidget {
  const MaterialListView({Key? key}) : super(key: key);

  @override
  State<MaterialListView> createState() => _MaterialListViewState();
}

class _MaterialListViewState extends State<MaterialListView> {
  final MaterialController controller = Get.find<MaterialController>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      controller.loadMoreMaterials();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Tài liệu',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Enhanced search section
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa để tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          controller.searchMaterials('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  controller.searchMaterials('');
                }
              },
              onSubmitted: (value) {
                controller.searchMaterials(value);
              },
            ),
          ),

          // Materials list
          Expanded(
            child: ResponsiveContainer(
              padding: EdgeInsets.zero,
              child: Obx(() {
              if (controller.isLoading.value && controller.materials.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.materials.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshMaterials,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.materials.length +
                      (controller.hasMorePages.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= controller.materials.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final material = controller.materials[index];
                    return MaterialCard(
                      material: material,
                      onTap: () => _navigateToMaterialDetail(material),
                      onEdit: () => _editMaterial(material),
                      onDelete: () => _deleteMaterial(material),
                    );
                  },
                ),
              );
            }),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final connectivityService = Get.find<ConnectivityService>();
        if (!connectivityService.isOnline.value) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _createMaterial,
            icon: const Icon(Icons.add),
            label: const Text('Tạo tài liệu'),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        iconSize: 20,
        color: colorScheme.onSurfaceVariant,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(40, 40),
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
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có tài liệu nào',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu tạo tài liệu đầu tiên cho khóa học của bạn',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Obx(() {
              final connectivityService = Get.find<ConnectivityService>();
              if (!connectivityService.isOnline.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createMaterial,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo tài liệu đầu tiên'),
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
              );
            }),
          ],
        ),
      ),
    );
  }

  void _createMaterial() async {
    final result = await Get.to(() => const MaterialForm());
    if (result == true) {
      controller.refreshMaterials();
    }
  }

  void _editMaterial(material_resp.Material material) async {
    final result = await Get.to(() => MaterialForm(
          material: material,
          isEditing: true,
        ));
    if (result == true) {
      controller.refreshMaterials();
    }
  }

  void _deleteMaterial(material_resp.Material material) async {
    final success = await controller.deleteMaterial(material.id);
    if (success) {
      Get.snackbar(
        'Thành công',
        'Đã xóa tài liệu "${material.title}"',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Lỗi',
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _navigateToMaterialDetail(material_resp.Material material) async {
    // Navigate to material detail (view tracking is now handled automatically in backend)
    Get.toNamed(Routes.MATERIALS_DETAIL.replaceAll(':id', material.id));
  }

  void _showFilterDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bộ lọc',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: controller.selectedCourseId.value.isEmpty
                  ? null
                  : controller.selectedCourseId.value,
              decoration: const InputDecoration(
                labelText: 'Khóa học',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tất cả khóa học'),
                ),
                ...controller.courses.map((course) => DropdownMenuItem(
                      value: course.id,
                      child: Text('${course.code} - ${course.name}'),
                    )),
              ],
              onChanged: (value) {
                controller.filterByCourse(value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.filterByCourse(null);
              Navigator.of(context).pop();
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sắp xếp',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Ngày tạo (mới nhất)'),
              value: 'created_at_desc',
              groupValue:
                  '${controller.sortBy.value}_${controller.sortOrder.value}',
              onChanged: (value) {
                controller.sortMaterials('created_at', 'desc');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Ngày tạo (cũ nhất)'),
              value: 'created_at_asc',
              groupValue:
                  '${controller.sortBy.value}_${controller.sortOrder.value}',
              onChanged: (value) {
                controller.sortMaterials('created_at', 'asc');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Tiêu đề (A-Z)'),
              value: 'title_asc',
              groupValue:
                  '${controller.sortBy.value}_${controller.sortOrder.value}',
              onChanged: (value) {
                controller.sortMaterials('title', 'asc');
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Tiêu đề (Z-A)'),
              value: 'title_desc',
              groupValue:
                  '${controller.sortBy.value}_${controller.sortOrder.value}',
              onChanged: (value) {
                controller.sortMaterials('title', 'desc');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
