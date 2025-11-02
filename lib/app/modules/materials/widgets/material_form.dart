import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/request/material_request.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'package:classroom_mini/app/shared/widgets/shared_file_attachment_picker.dart';
import '../controllers/material_controller.dart';
import '../views/mobile/material_list_view.dart';

/**
 * Material Form Widget
 * Handles creating and editing materials with modern UI design
 * Features: Progressive disclosure, visual hierarchy, accessibility
 */
class MaterialForm extends StatefulWidget {
  final material_resp.Material? material;
  final bool isEditing;

  const MaterialForm({
    Key? key,
    this.material,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<MaterialForm> {
  final MaterialController controller = Get.find<MaterialController>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCourseId;
  List<String> _selectedAttachmentIds = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadFormData();
  }

  void _initializeForm() {
    controller.initFormState();
  }

  Future<void> _loadFormData() async {
    // Load courses from API
    await controller.loadCourses();

    // Set default course if available
    if (controller.courses.isNotEmpty) {
      controller.updateForm((s) {
        s.courseId = controller.courses.first.id;
      });
    }

    // Pre-fill form if editing
    if (widget.isEditing && widget.material != null) {
      _titleController.text = widget.material!.title;
      _descriptionController.text = widget.material!.description ?? '';
      _selectedCourseId = widget.material!.course.id;
      _selectedAttachmentIds = widget.material!.files.map((f) => f.id).toList();

      controller.updateForm((s) {
        s.title = widget.material!.title;
        s.description = widget.material!.description ?? '';
        s.courseId = widget.material!.course.id;
        s.attachmentIds = widget.material!.files.map((f) => f.id).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Chỉnh sửa tài liệu' : 'Tạo tài liệu mới',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isEditing
                      ? 'Cập nhật thông tin tài liệu'
                      : 'Thêm tài liệu mới cho khóa học',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _saveMaterial,
              icon: Icon(
                widget.isEditing ? Icons.edit : Icons.add,
                color: colorScheme.onPrimary,
                size: 22,
              ),
              tooltip: widget.isEditing ? 'Lưu chỉnh sửa' : 'Tạo tài liệu',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Form sections with enhanced design
            _buildBasicInfoSection(context),
            const SizedBox(height: 24),
            _buildAttachmentsSection(context),
            const SizedBox(height: 24),
            _buildPreviewSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Thông tin cơ bản',
      icon: Icons.info_outline,
      children: [
        _buildEnhancedTextField(
          controller: _titleController,
          label: 'Tiêu đề tài liệu',
          hint: 'Nhập tiêu đề mô tả rõ ràng nội dung tài liệu',
          icon: Icons.title,
          maxLength: 200,
          required: true,
          onChanged: (value) => controller.updateForm((s) => s.title = value),
        ),
        const SizedBox(height: 20),
        _buildEnhancedTextField(
          controller: _descriptionController,
          label: 'Mô tả tài liệu',
          hint:
              'Mô tả chi tiết về nội dung và mục đích của tài liệu (tùy chọn)',
          icon: Icons.description_outlined,
          maxLength: 500,
          maxLines: 4,
          onChanged: (value) =>
              controller.updateForm((s) => s.description = value),
        ),
        const SizedBox(height: 20),
        _buildCourseSelector(context),
      ],
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    int maxLines = 1,
    bool required = false,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
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
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            counterStyle: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCourseSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Khóa học',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingCourses.value) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: InputDecoration(
              hintText: 'Chọn khóa học cho tài liệu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
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
              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              prefixIcon: const Icon(Icons.school_outlined),
            ),
            items: controller.courses
                .map((course) => DropdownMenuItem(
                      value: course.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            course.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourseId = value;
              });
              controller.updateForm((s) => s.courseId = value ?? '');
            },
          );
        }),
      ],
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Tài liệu đính kèm',
      icon: Icons.attachment_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin tệp đính kèm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Tối đa 10 tệp, mỗi tệp không quá 100MB\n'
                '• Định dạng hỗ trợ: PDF, DOC, PPT, XLS, TXT, JPG, PNG, ZIP, RAR\n'
                '• Tệp đính kèm giúp sinh viên dễ dàng tải về và học tập',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SharedFileAttachmentPicker(
          tag: 'material_attachments',
          onAttachmentsChanged: (attachments) {
            print('=== MATERIAL FORM CALLBACK ===');
            print('Received attachments changed callback');
            print('New attachments count: ${attachments.length}');
            print(
                'Uploaded count: ${attachments.where((a) => a.isUploaded).length}');
            print('Attachment details:');
            for (int i = 0; i < attachments.length; i++) {
              final att = attachments[i];
              print(
                  '  [$i] ${att.fileName} - Status: ${att.status} - ID: ${att.attachmentId}');
            }
            print('Updating _selectedAttachmentIds...');
            _selectedAttachmentIds = attachments
                .where((a) => a.isUploaded && a.attachmentId != null)
                .map((a) => a.attachmentId!)
                .toList();
            print(
                'Update completed. Current _selectedAttachmentIds count: ${_selectedAttachmentIds.length}');
            print('=== END MATERIAL FORM CALLBACK ===');
          },
          maxFiles: 10,
          maxFileSizeMB: 100,
          allowedExtensions: const [
            'pdf',
            'docx',
            'doc',
            'pptx',
            'ppt',
            'xlsx',
            'xls',
            'txt',
            'jpg',
            'jpeg',
            'png',
            'zip',
            'rar'
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Xem trước tài liệu',
      icon: Icons.preview_outlined,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem trước tài liệu',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Đây là cách tài liệu sẽ hiển thị cho sinh viên',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preview content
              if (_titleController.text.isNotEmpty) ...[
                Text(
                  _titleController.text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.title,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tiêu đề tài liệu sẽ hiển thị ở đây',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_descriptionController.text.isNotEmpty) ...[
                Text(
                  _descriptionController.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Course info preview
              if (_selectedCourseId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khóa học',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.courses
                                  .firstWhere((c) => c.id == _selectedCourseId)
                                  .name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Attachments preview
              if (_selectedAttachmentIds.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attachment_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedAttachmentIds.length} tệp đính kèm',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
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
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMaterial() async {
    if (!_validateForm()) return;

    print('=== SAVING MATERIAL ===');
    print('Selected attachment IDs: $_selectedAttachmentIds');

    // Hiển thị dialog loading thay vì thay đổi toàn bộ UI
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      final request = CreateMaterialRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        courseId: _selectedCourseId!,
        attachmentIds:
            _selectedAttachmentIds.isNotEmpty ? _selectedAttachmentIds : null,
      );

      if (widget.isEditing && widget.material != null) {
        final updateRequest = UpdateMaterialRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          attachmentIds:
              _selectedAttachmentIds.isNotEmpty ? _selectedAttachmentIds : null,
        );

        final success = await controller.updateMaterial(
          widget.material!.id,
          updateRequest,
        );

        // Đóng dialog loading
        Get.back();

        if (success) {
          // Show success message
          Get.snackbar(
            'Thành công',
            'Đã cập nhật tài liệu "${_titleController.text.trim()}" thành công',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Back to home and reload
          Get.off(() => const MaterialListView());
        } else {
          // Hiển thị lỗi nếu có
          Get.snackbar(
            'Lỗi',
            controller.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final materialId = await controller.createMaterial(request);

        // Đóng dialog loading
        Get.back();

        if (materialId != null) {
          // Finalize attachments if any
          if (_selectedAttachmentIds.isNotEmpty) {
            print('Finalizing attachments for material: $materialId');
            await controller.finalizeAttachments(
                materialId, _selectedAttachmentIds);
          }

          // Show success message
          Get.snackbar(
            'Thành công',
            'Đã tạo tài liệu "${_titleController.text.trim()}" thành công',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Back to home and reload
          Get.off(() => const MaterialListView());
        } else {
          // Hiển thị lỗi nếu có
          Get.snackbar(
            'Lỗi',
            controller.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      Get.back();

      // Hiển thị lỗi
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập tiêu đề tài liệu');
      return false;
    }

    if (_titleController.text.trim().length < 2) {
      Get.snackbar('Lỗi', 'Tiêu đề phải có ít nhất 2 ký tự');
      return false;
    }

    if (_selectedCourseId == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn khóa học');
      return false;
    }

    return true;
  }
}
