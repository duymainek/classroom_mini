import 'dart:async';
import 'package:classroom_mini/app/shared/widgets/shared_file_attachment_picker.dart';
import 'package:classroom_mini/app/shared/models/uploaded_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AssignmentForm extends StatefulWidget {
  final Assignment? assignment;
  final List<CourseInfo> courses;
  final List<GroupInfo> groups;
  final Function(AssignmentFormData) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const AssignmentForm({
    Key? key,
    this.assignment,
    required this.courses,
    required this.groups,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController =
      TextEditingController(); // Controller for Gemini prompt
  bool _isPreview = false;

  // Add a flag to track disposal state
  bool _isDisposed = false;

  // Store subscription for proper cleanup
  StreamSubscription? _formStateSubscription;

  // Add a safer method to get controller
  AssignmentController? _getController() {
    if (_isDisposed) return null;
    try {
      return Get.find<AssignmentController>();
    } catch (e) {
      return null;
    }
  }

  String? _selectedCourseId;
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _lateDueDate;
  bool _allowLateSubmission = false;
  int _maxAttempts = 1;
  List<String> _fileFormats = [];
  int _maxFileSize = 10;
  List<String> _selectedGroupIds = [];
  final RxList<UploadedAttachment> _uploadedAttachments =
      <UploadedAttachment>[].obs;

  final List<String> _availableFileFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'jpg',
    'jpeg',
    'png',
    'zip',
    'rar'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();

    // Use try-catch to safely get or create controller
    try {
      // Try to get existing controller first
      final controller = Get.find<AssignmentController>();
      _initializeControllerState(controller);
    } catch (e) {
      // If controller doesn't exist, create it
      final controller = Get.put(AssignmentController(), permanent: false);
      _initializeControllerState(controller);
    }
  }

  void _initializeControllerState(AssignmentController controller) {
    // Initialize controller form state
    controller.initFormState(courses: const [], groups: const []);

    // Always refresh courses on entering the form to ensure latest data
    controller.loadCoursesForForm();

    // If editing existing assignment with a course, load groups for that course
    if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
      controller.loadGroupsForForm(_selectedCourseId!);
    }

    // Listen to description changes from controller (e.g., Gemini API)
    // Add safety checks for disposal state
    _formStateSubscription = controller.formState.listen((state) {
      if (_isDisposed) return; // Skip if widget is disposed

      if (state.description != null &&
          state.description != _descriptionController.text) {
        // Safely update the TextEditingController after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed && mounted) {
            _descriptionController.text = state.description!;
          }
        });
      }
    });
  }

  void _initializeForm() {
    if (widget.assignment != null) {
      final assignment = widget.assignment!;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description ?? '';
      _selectedCourseId = assignment.courseId;
      _startDate = assignment.startDate;
      _dueDate = assignment.dueDate;
      _lateDueDate = assignment.lateDueDate;
      _allowLateSubmission = assignment.allowLateSubmission;
      _maxAttempts = assignment.maxAttempts;
      _fileFormats = List.from(assignment.fileFormats);
      _maxFileSize = assignment.maxFileSize;
      _selectedGroupIds = assignment.groups.map((g) => g.id).toList();

      // Sync with controller state - use try-catch for safety
      try {
        final controller = Get.find<AssignmentController>();
        controller.setSelectedGroupsForForm(_selectedGroupIds);
        controller.updateForm((s) => s.description = assignment.description);
      } catch (e) {
        // Controller not ready yet, will be synced in initializeControllerState
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed
    _formStateSubscription?.cancel(); // Cancel subscription
    _titleController.dispose();
    _descriptionController.dispose();
    _promptController.dispose(); // Dispose prompt controller
    super.dispose();
  }

  Future<void> _showGeminiPromptDialog() async {
    final controller = _getController();
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi hệ thống, vui lòng thử lại')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tạo mô tả với Gemini'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  hintText: 'Nhập gợi ý cho AI',
                  border: OutlineInputBorder(),
                  labelText: 'Gợi ý',
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Text(
                'AI sẽ tạo một mô tả chi tiết dựa trên gợi ý của bạn.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            Obx(() => FilledButton.icon(
                  onPressed: () {
                    final controller = _getController();
                    if (controller == null ||
                        controller.isGeneratingDescription) return;
                    final prompt = _promptController.text.trim();
                    if (prompt.isEmpty) return;
                    _descriptionController.clear();
                    controller.generateDescriptionFromGemini(prompt);
                    Navigator.of(ctx).pop();
                  },
                  icon: () {
                    final controller = _getController();
                    if (controller?.isGeneratingDescription == true) {
                      return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      );
                    }
                    return const Icon(Icons.auto_awesome);
                  }(),
                  label: const Text('Tạo'),
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildModernTextField(
              controller: _titleController,
              label: 'Tiêu đề bài tập *',
              hint: 'Nhập tiêu đề bài tập',
              prefixIcon: Icons.title,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề bài tập';
                }
                if (value.trim().length < 2) {
                  return 'Tiêu đề phải có ít nhất 2 ký tự';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description + Gemini + Preview
            _buildModernSection(
              context,
              title: 'Mô tả bài tập',
              icon: Icons.description,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mô tả bài tập',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(children: [
                      Tooltip(
                        message: _isPreview
                            ? 'Chuyển sang Soạn thảo'
                            : 'Xem Preview',
                        child: IconButton(
                          icon: Icon(
                              _isPreview ? Icons.edit : Icons.remove_red_eye),
                          onPressed: () =>
                              setState(() => _isPreview = !_isPreview),
                        ),
                      ),
                      Tooltip(
                        message: 'Tạo bằng Gemini',
                        child: Obx(() {
                          final controller = _getController();
                          if (controller == null)
                            return const SizedBox.shrink();
                          return IconButton(
                            icon: controller.isGeneratingDescription
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            onPressed: controller.isGeneratingDescription
                                ? null
                                : _showGeminiPromptDialog,
                          );
                        }),
                      ),
                    ])
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isPreview)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Hỗ trợ Markdown, tối đa 5000 ký tự',
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
                      alignLabelWithHint: true,
                    ),
                    minLines: 8,
                    maxLines: 20,
                    maxLength: 5000,
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minHeight: 200),
                    child: MarkdownBody(
                      data: _descriptionController.text,
                      shrinkWrap: true,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Course selection
            _buildModernTextField(
              controller: null,
              label: 'Khóa học *',
              hint: 'Chọn khóa học',
              prefixIcon: Icons.school,
              child: DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: InputDecoration(
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
                ),
                items: _getController()
                        ?.formState
                        .value
                        .courses
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.code} - ${c.name}'),
                            ))
                        .toList() ??
                    [],
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                    _selectedGroupIds
                        .clear(); // Clear groups when course changes
                  });
                  final controller = _getController();
                  if (controller != null) {
                    controller.updateForm((s) => s.courseId = value);
                    controller.clearSelectedGroupsForForm();
                    if (value != null) {
                      // Always load groups when course changes, even in edit mode
                      controller.loadGroupsForForm(value);
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn khóa học';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Date and time section
            _buildDateTimeSection(context, theme),

            const SizedBox(height: 20),

            // Submission settings
            _buildSubmissionSettings(context, theme),

            const SizedBox(height: 20),

            // File settings
            _buildFileSettings(context, theme),

            const SizedBox(height: 20),

            // File Attachments
            _buildFileAttachmentsSection(context, theme),

            const SizedBox(height: 20),

            // Group selection
            _buildGroupSelection(context, theme),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context, ThemeData theme) {
    return _buildModernSection(
      context,
      title: 'Thời gian',
      icon: Icons.schedule,
      children: [
        // Start date
        _buildModernDateTile(
          context,
          title: 'Ngày bắt đầu *',
          subtitle: _startDate != null
              ? _formatDateTime(_startDate!)
              : 'Chọn ngày bắt đầu',
          value: _startDate,
          icon: Icons.play_arrow,
          onTap: () => _selectDate(context, (date) {
            setState(() => _startDate = date);
          }),
        ),
        const SizedBox(height: 12),

        // Due date
        _buildModernDateTile(
          context,
          title: 'Hạn chót *',
          subtitle:
              _dueDate != null ? _formatDateTime(_dueDate!) : 'Chọn hạn chót',
          value: _dueDate,
          icon: Icons.flag,
          onTap: () => _selectDate(context, (date) {
            setState(() => _dueDate = date);
          }),
        ),
        const SizedBox(height: 12),

        // Late submission toggle
        _buildModernSwitchTile(
          context,
          title: 'Cho phép nộp trễ',
          subtitle: 'Sinh viên có thể nộp bài sau hạn chót',
          value: _allowLateSubmission,
          onChanged: (value) {
            setState(() {
              _allowLateSubmission = value;
              if (!value) _lateDueDate = null;
            });
          },
          icon: Icons.warning,
        ),

        // Late due date
        if (_allowLateSubmission) ...[
          const SizedBox(height: 12),
          _buildModernDateTile(
            context,
            title: 'Hạn nộp trễ',
            subtitle: _lateDueDate != null
                ? _formatDateTime(_lateDueDate!)
                : 'Chọn hạn nộp trễ',
            value: _lateDueDate,
            icon: Icons.warning,
            onTap: () => _selectDate(context, (date) {
              setState(() => _lateDueDate = date);
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelectionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      Color? iconColor,
      required VoidCallback onTap}) {
    return ListTile(
      leading:
          Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
    );
  }

  Widget _buildSubmissionSettings(BuildContext context, ThemeData theme) {
    return _buildModernSection(
      context,
      title: 'Cài đặt nộp bài',
      icon: Icons.settings,
      children: [
        _buildModernTextField(
          controller: null,
          initialValue: _maxAttempts.toString(),
          label: 'Số lần nộp tối đa',
          hint: 'Nhập số lần nộp tối đa',
          prefixIcon: Icons.repeat,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _maxAttempts = int.tryParse(value) ?? 1;
          },
          validator: (value) {
            final attempts = int.tryParse(value ?? '');
            if (attempts == null || attempts < 1 || attempts > 10) {
              return 'Số lần nộp phải từ 1 đến 10';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFileSettings(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Cài đặt file',
      icon: Icons.attach_file,
      children: [
        // File formats
        Text(
          'Định dạng file cho phép:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableFileFormats.map((format) {
            final isSelected = _fileFormats.contains(format);
            return FilterChip(
              label: Text(format.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _fileFormats.add(format);
                  } else {
                    _fileFormats.remove(format);
                  }
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Max file size
        _buildModernTextField(
          controller: null,
          initialValue: _maxFileSize.toString(),
          label: 'Kích thước file tối đa (MB)',
          hint: 'Nhập kích thước file tối đa',
          prefixIcon: Icons.storage,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _maxFileSize = int.tryParse(value) ?? 10;
          },
          validator: (value) {
            final size = int.tryParse(value ?? '');
            if (size == null || size < 1 || size > 100) {
              return 'Kích thước file phải từ 1 đến 100 MB';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGroupSelection(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Phân phối đến nhóm',
      icon: Icons.group,
      children: [
        Text(
          'Chọn các nhóm sẽ nhận bài tập này',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final controller = _getController();
          if (controller == null) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Đang khởi tạo...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          if (controller.isGroupsLoading) {
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
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải nhóm...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (_selectedCourseId == null) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Vui lòng chọn khóa học trước',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final availableGroups = controller.formState.value.groups
              .where((_) => _selectedCourseId != null)
              .toList();
          if (availableGroups.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Không có nhóm nào trong khóa học đã chọn',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  controller.selectedGroupIdsForFormRx.isEmpty
                      ? 'Chưa chọn nhóm nào'
                      : 'Đã chọn ${controller.selectedGroupIdsForFormRx.length} nhóm',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableGroups.map((g) {
                  final isSelected =
                      controller.selectedGroupIdsForFormRx.contains(g.id);
                  return FilterChip(
                    label: Text(g.name),
                    selected: isSelected,
                    onSelected: (sel) => controller
                        .toggleGroupSelectionForForm(g.id, selected: sel),
                    selectedColor: colorScheme.tertiaryContainer,
                    checkmarkColor: colorScheme.onTertiaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Dialog chọn nhóm đã loại bỏ theo góp ý UX; sử dụng inline chips ở trên

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          if (widget.onCancel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSubmitEnabled() ? _handleSubmit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      widget.assignment != null ? 'Cập nhật' : 'Tạo bài tập'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSubmitEnabled() {
    if (widget.isLoading) return false;
    if (_titleController.text.trim().length < 2) return false;
    if (_selectedCourseId == null || _selectedCourseId!.isEmpty) return false;
    if (_startDate == null || _dueDate == null) return false;
    if (_allowLateSubmission &&
        _lateDueDate != null &&
        _dueDate != null &&
        _dueDate!.isAfter(_lateDueDate!)) return false;

    // Check if any attachments are still uploading
    if (_uploadedAttachments.any((attachment) => attachment.isUploading))
      return false;

    return true;
  }

  Future<void> _selectDate(
      BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        onDateSelected(dateTime);
      }
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_startDate == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và hạn chót')),
      );
      return;
    }

    if (_startDate!.isAfter(_dueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày bắt đầu phải trước hạn chót')),
      );
      return;
    }

    if (_allowLateSubmission &&
        _lateDueDate != null &&
        _dueDate!.isAfter(_lateDueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn nộp trễ phải sau hạn chót')),
      );
      return;
    }

    // Ensure at least one group selected (backend requires)
    final controller = _getController();
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi hệ thống, vui lòng thử lại')),
      );
      return;
    }

    final selectedGroupIds = controller.selectedGroupIdsForForm.toList();
    if (selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một nhóm')),
      );
      return;
    }

    final formData = AssignmentFormData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      courseId: _selectedCourseId!,
      startDate: _startDate!,
      dueDate: _dueDate!,
      lateDueDate: _lateDueDate,
      allowLateSubmission: _allowLateSubmission,
      maxAttempts: _maxAttempts,
      fileFormats: _fileFormats,
      maxFileSize: _maxFileSize,
      groupIds: selectedGroupIds,
      uploadedAttachments: _uploadedAttachments.toList(),
    );

    widget.onSubmit(formData);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  Widget _buildModernTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? prefixIcon,
    Widget? child,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (child != null)
              child
            else
              TextFormField(
                controller: controller,
                initialValue: initialValue,
                keyboardType: keyboardType,
                maxLines: maxLines,
                validator: validator,
                onChanged: onChanged,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing:
            Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildModernSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        activeColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildFileAttachmentsSection(BuildContext context, ThemeData theme) {
    print('=== BUILDING FILE ATTACHMENTS SECTION ===');
    print('Current _uploadedAttachments count: ${_uploadedAttachments.length}');
    print('Attachment details:');
    for (int i = 0; i < _uploadedAttachments.length; i++) {
      final att = _uploadedAttachments[i];
      print(
          '  [$i] ${att.fileName} - Status: ${att.status} - ID: ${att.attachmentId}');
    }

    return _buildModernSection(
      context,
      title: 'Tệp đính kèm',
      icon: Icons.attach_file,
      children: [
        SharedFileAttachmentPicker(
          tag: 'assignment_attachments',
          onAttachmentsChanged: (attachments) {
            print('=== ASSIGNMENT FORM CALLBACK ===');
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
            print('Updating _uploadedAttachments...');
            _uploadedAttachments.assignAll(attachments);
            print(
                'Update completed. Current _uploadedAttachments count: ${_uploadedAttachments.length}');
            print('=== END ASSIGNMENT FORM CALLBACK ===');
          },
          maxFiles: 10,
          maxFileSizeMB: _maxFileSize,
          allowedExtensions: _fileFormats.isEmpty ? [] : _fileFormats,
        ),
      ],
    );
  }
}

class AssignmentFormData {
  final String title;
  final String description;
  final String courseId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final List<String> fileFormats;
  final int maxFileSize;
  final List<String> groupIds;
  final List<UploadedAttachment> uploadedAttachments;

  AssignmentFormData({
    required this.title,
    required this.description,
    required this.courseId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    required this.fileFormats,
    required this.maxFileSize,
    required this.groupIds,
    required this.uploadedAttachments,
  });
}
