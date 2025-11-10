import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/request/announcement_request.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import 'package:classroom_mini/app/shared/widgets/shared_file_attachment_picker.dart';
import '../controllers/announcement_controller.dart';

/**
 * Announcement Form Widget
 * Handles creating and editing announcements with modern UI
 */
class AnnouncementForm extends StatefulWidget {
  final Announcement? announcement;
  final bool isEditing;

  const AnnouncementForm({
    Key? key,
    this.announcement,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  final AnnouncementController controller = Get.find<AnnouncementController>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _selectedCourseId;
  String? _selectedScopeType;
  List<String> _selectedGroupIds = [];
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
    if (widget.isEditing && widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _contentController.text = widget.announcement!.content;
      _selectedCourseId = widget.announcement!.course.id;
      _selectedScopeType = widget.announcement!.scopeType;
      _selectedGroupIds = widget.announcement!.groups.map((g) => g.id).toList();
      _selectedAttachmentIds =
          widget.announcement!.files.map((f) => f.id).toList();

      controller.updateForm((s) {
        s.title = widget.announcement!.title;
        s.content = widget.announcement!.content;
        s.courseId = widget.announcement!.course.id;
        s.scopeType = widget.announcement!.scopeType;
        s.groupIds = widget.announcement!.groups.map((g) => g.id).toList();
        s.attachmentIds = widget.announcement!.files.map((f) => f.id).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditing ? 'Chỉnh sửa thông báo' : 'Tạo thông báo mới'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          TextButton(
            onPressed: _saveAnnouncement,
            child: Text(
              widget.isEditing ? 'Cập nhật' : 'Tạo',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isFormLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(context),
              const SizedBox(height: 24),
              _buildScopeSection(context),
              const SizedBox(height: 24),
              _buildAttachmentsSection(context),
              const SizedBox(height: 24),
              _buildPreviewSection(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Thông tin cơ bản',
      icon: Icons.info,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Tiêu đề *',
            hintText: 'Nhập tiêu đề thông báo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.title),
            counterText: '${_titleController.text.length}/200',
          ),
          maxLength: 200,
          onChanged: (value) {
            controller.updateForm((s) => s.title = value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contentController,
          decoration: InputDecoration(
            labelText: 'Nội dung *',
            hintText: 'Nhập nội dung thông báo (tối thiểu 10 ký tự)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.description),
            counterText: '${_contentController.text.length}/10+ ký tự',
            helperText: 'Nội dung phải có ít nhất 10 ký tự',
          ),
          maxLines: 6,
          onChanged: (value) {
            controller.updateForm((s) => s.content = value);
          },
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoadingCourses) {
            return const Center(child: CircularProgressIndicator());
          }

          return DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: InputDecoration(
              labelText: 'Khóa học *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.school),
            ),
            items: controller.courses
                .map((course) => DropdownMenuItem(
                      value: course.id,
                      child: Text('${course.code} - ${course.name}'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourseId = value;
              });
              controller.updateForm((s) => s.courseId = value);
              _loadGroupsForCourse(value);
            },
          );
        }),
      ],
    );
  }

  Widget _buildScopeSection(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Phạm vi gửi',
      icon: Icons.group,
      children: [
        Column(
          children: [
            RadioListTile<String>(
              title: const Text('Một nhóm'),
              subtitle: const Text('Gửi đến một nhóm cụ thể'),
              value: 'one_group',
              groupValue: _selectedScopeType,
              onChanged: (value) {
                setState(() {
                  _selectedScopeType = value;
                  _selectedGroupIds.clear();
                });
                controller.updateForm((s) {
                  s.scopeType = value;
                  s.groupIds = [];
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Nhiều nhóm'),
              subtitle: const Text('Gửi đến nhiều nhóm được chọn'),
              value: 'multiple_groups',
              groupValue: _selectedScopeType,
              onChanged: (value) {
                setState(() {
                  _selectedScopeType = value;
                  _selectedGroupIds.clear();
                });
                controller.updateForm((s) {
                  s.scopeType = value;
                  s.groupIds = [];
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Tất cả nhóm'),
              subtitle: const Text('Gửi đến tất cả nhóm trong khóa học'),
              value: 'all_groups',
              groupValue: _selectedScopeType,
              onChanged: (value) {
                setState(() {
                  _selectedScopeType = value;
                  _selectedGroupIds.clear();
                });
                controller.updateForm((s) {
                  s.scopeType = value;
                  s.groupIds = [];
                });
              },
            ),
          ],
        ),
        if (_selectedScopeType != null &&
            _selectedScopeType != 'all_groups') ...[
          const SizedBox(height: 16),
          _buildGroupSelection(context),
        ],
      ],
    );
  }

  Widget _buildGroupSelection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (controller.isLoadingGroups) {
        return const Center(child: CircularProgressIndicator());
      }

      final groups = controller.groups;

      if (groups.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vui lòng chọn khóa học để xem danh sách nhóm',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn nhóm (${_selectedGroupIds.length}/${groups.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_selectedScopeType == 'multiple_groups') ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedGroupIds.length == groups.length) {
                            _selectedGroupIds.clear();
                          } else {
                            _selectedGroupIds =
                                groups.map((g) => g.id).toList();
                          }
                        });
                        controller
                            .updateForm((s) => s.groupIds = _selectedGroupIds);
                      },
                      child: Text(
                        _selectedGroupIds.length == groups.length
                            ? 'Bỏ chọn tất cả'
                            : 'Chọn tất cả',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...groups.map((group) {
              final isSelected = _selectedGroupIds.contains(group.id);
              return CheckboxListTile(
                title: Text(group.name),
                subtitle: Text('Nhóm ${group.name}'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      if (_selectedScopeType == 'one_group') {
                        _selectedGroupIds = [group.id];
                      } else {
                        _selectedGroupIds.add(group.id);
                      }
                    } else {
                      _selectedGroupIds.remove(group.id);
                    }
                  });
                  controller.updateForm((s) => s.groupIds = _selectedGroupIds);
                },
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Tài liệu đính kèm',
      icon: Icons.attachment,
      children: [
        SharedFileAttachmentPicker(
          tag: 'announcement_attachments',
          onAttachmentsChanged: (attachments) {
            debugPrint('=== ANNOUNCEMENT FORM CALLBACK ===');
            debugPrint('Received attachments changed callback');
            debugPrint('New attachments count: ${attachments.length}');
            debugPrint(
                'Uploaded count: ${attachments.where((a) => a.isUploaded).length}');
            debugPrint('Attachment details:');
            for (int i = 0; i < attachments.length; i++) {
              final att = attachments[i];
              debugPrint(
                  '  [$i] ${att.fileName} - Status: ${att.status} - ID: ${att.attachmentId}');
            }
            debugPrint('Updating _selectedAttachmentIds...');
            _selectedAttachmentIds = attachments
                .where((a) => a.isUploaded && a.attachmentId != null)
                .map((a) => a.attachmentId!)
                .toList();
            debugPrint(
                'Update completed. Current _selectedAttachmentIds count: ${_selectedAttachmentIds.length}');
            debugPrint('=== END ANNOUNCEMENT FORM CALLBACK ===');
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
      title: 'Xem trước',
      icon: Icons.preview,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_titleController.text.isNotEmpty) ...[
                Text(
                  _titleController.text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_contentController.text.isNotEmpty) ...[
                Text(
                  _contentController.text,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              if (_selectedCourseId != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.courses
                          .firstWhere((c) => c.id == _selectedCourseId)
                          .name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedScopeType != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getScopeDisplayText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                    color: colorScheme.primary.withValues(alpha: 0.1),
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

  Future<void> _loadGroupsForCourse(String? courseId) async {
    if (courseId == null) return;

    try {
      await controller.loadGroupsByCourse(courseId);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách nhóm: $e');
    }
  }

  String _getScopeDisplayText() {
    switch (_selectedScopeType) {
      case 'one_group':
        return 'Một nhóm';
      case 'multiple_groups':
        return '${_selectedGroupIds.length} nhóm được chọn';
      case 'all_groups':
        return 'Tất cả nhóm';
      default:
        return 'Chưa chọn phạm vi';
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_validateForm()) return;

    debugPrint('=== SAVING ANNOUNCEMENT ===');
    debugPrint('Selected attachment IDs: $_selectedAttachmentIds');

    final request = CreateAnnouncementRequest(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      courseId: _selectedCourseId!,
      scopeType: _selectedScopeType!,
      groupIds: _selectedScopeType == 'all_groups' ? null : _selectedGroupIds,
      attachmentIds:
          _selectedAttachmentIds.isNotEmpty ? _selectedAttachmentIds : null,
    );

    if (widget.isEditing && widget.announcement != null) {
      final updateRequest = UpdateAnnouncementRequest(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        attachmentIds:
            _selectedAttachmentIds.isNotEmpty ? _selectedAttachmentIds : null,
      );

      final success = await controller.updateAnnouncement(
        widget.announcement!.id,
        updateRequest,
      );

      if (success) {
        Get.back(result: true);
      }
    } else {
      final announcementId = await controller.createAnnouncement(request);
      if (announcementId != null) {
        // Finalize attachments if any
        if (_selectedAttachmentIds.isNotEmpty) {
          debugPrint('Finalizing attachments for announcement: $announcementId');
          await controller.finalizeAttachments(
              announcementId, _selectedAttachmentIds);
        }
        Get.back(result: true);
      }
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập tiêu đề thông báo');
      return false;
    }

    if (_titleController.text.trim().length < 2) {
      Get.snackbar('Lỗi', 'Tiêu đề phải có ít nhất 2 ký tự');
      return false;
    }

    if (_contentController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập nội dung thông báo');
      return false;
    }

    if (_contentController.text.trim().length < 10) {
      Get.snackbar('Lỗi', 'Nội dung phải có ít nhất 10 ký tự');
      return false;
    }

    if (_selectedCourseId == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn khóa học');
      return false;
    }

    if (_selectedScopeType == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn phạm vi gửi');
      return false;
    }

    if (_selectedScopeType != 'all_groups' && _selectedGroupIds.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn ít nhất một nhóm');
      return false;
    }

    return true;
  }
}
