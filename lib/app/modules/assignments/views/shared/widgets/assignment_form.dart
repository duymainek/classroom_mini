import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Removed unused import of course_model

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

  String? _selectedCourseId;
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _lateDueDate;
  bool _allowLateSubmission = false;
  int _maxAttempts = 1;
  List<String> _fileFormats = [];
  int _maxFileSize = 10;
  List<String> _selectedGroupIds = [];

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
    // Initialize controller form state (courses/groups supplied by parent)
    final controller = Get.put(AssignmentController(), permanent: false);
    controller.initFormState(courses: widget.courses, groups: widget.groups);
    // Always refresh courses on entering the form to ensure latest data
    controller.loadCoursesForForm();
    // If editing existing assignment with a course, load groups for that course
    if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
      controller.loadGroupsForForm(_selectedCourseId!);
    }
    // Listen to description changes from controller (e.g., Gemini API)
    // We need to listen to the Rx<AssignmentFormState> directly from the controller
    // and then access its value.
    controller.formState.listen((state) {
      if (state.description != null &&
          state.description != _descriptionController.text) {
        // Safely update the TextEditingController after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _descriptionController.text = state.description!;
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

      // Sync with controller state
      final controller = Get.find<AssignmentController>();
      controller.setSelectedGroupsForForm(_selectedGroupIds);
      controller.updateForm((s) => s.description = assignment.description);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _promptController.dispose(); // Dispose prompt controller
    super.dispose();
  }

  Future<void> _showGeminiPromptDialog() async {
    final controller = Get.find<AssignmentController>();
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
                  onPressed: controller.isGeneratingDescription
                      ? null
                      : () {
                          final prompt = _promptController.text.trim();
                          if (prompt.isEmpty) return;
                          _descriptionController.clear();
                          controller.generateDescriptionFromGemini(prompt);
                          Navigator.of(ctx).pop();
                        },
                  icon: controller.isGeneratingDescription
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài tập 1*',
                hintText: 'Nhập tiêu đề bài tập',
                border: OutlineInputBorder(),
              ),
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

            const SizedBox(height: 16),

            // Description + Gemini + Preview
            Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mô tả bài tập',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(children: [
                          Tooltip(
                            message: _isPreview
                                ? 'Chuyển sang Soạn thảo'
                                : 'Xem Preview',
                            child: IconButton(
                              icon: Icon(_isPreview
                                  ? Icons.edit
                                  : Icons.remove_red_eye),
                              onPressed: () =>
                                  setState(() => _isPreview = !_isPreview),
                            ),
                          ),
                          Tooltip(
                            message: 'Tạo bằng Gemini',
                            child: Obx(() {
                              final controller =
                                  Get.find<AssignmentController>();
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
                        decoration: const InputDecoration(
                          hintText: 'Hỗ trợ Markdown, tối đa 5000 ký tự',
                          border: OutlineInputBorder(),
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
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minHeight: 200),
                        child: MarkdownBody(
                          data: _descriptionController.text,
                          shrinkWrap: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course selection
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Khóa học *',
                border: OutlineInputBorder(),
              ),
              items: Get.find<AssignmentController>()
                  .formState
                  .value
                  .courses
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.code} - ${c.name}'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                  _selectedGroupIds.clear(); // Clear groups when course changes
                });
                final controller = Get.find<AssignmentController>();
                controller.updateForm((s) => s.courseId = value);
                controller.clearSelectedGroupsForForm();
                if (value != null) {
                  // Always load groups when course changes, even in edit mode
                  controller.loadGroupsForForm(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn khóa học';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Date and time section
            _buildDateTimeSection(theme),

            const SizedBox(height: 16),

            // Submission settings
            _buildSubmissionSettings(theme),

            const SizedBox(height: 16),

            // File settings
            _buildFileSettings(theme),

            const SizedBox(height: 16),

            // Group selection
            _buildGroupSelection(theme),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thời gian',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Start date
            _buildDateSelectionTile(
              context,
              icon: Icons.play_arrow,
              title: 'Ngày bắt đầu *',
              subtitle: _startDate != null
                  ? _formatDateTime(_startDate!)
                  : 'Chọn ngày bắt đầu',
              onTap: () => _selectDate(context, (date) {
                setState(() => _startDate = date);
              }),
            ),
            const SizedBox(height: 8),

            // Due date
            _buildDateSelectionTile(
              context,
              icon: Icons.flag,
              title: 'Hạn chót *',
              subtitle: _dueDate != null
                  ? _formatDateTime(_dueDate!)
                  : 'Chọn hạn chót',
              onTap: () => _selectDate(context, (date) {
                setState(() => _dueDate = date);
              }),
            ),
            const SizedBox(height: 8),

            // Late submission toggle
            SwitchListTile(
              title: const Text('Cho phép nộp trễ'),
              subtitle: const Text('Sinh viên có thể nộp bài sau hạn chót'),
              value: _allowLateSubmission,
              onChanged: (value) {
                setState(() {
                  _allowLateSubmission = value;
                  if (!value) _lateDueDate = null;
                });
              },
            ),

            // Late due date
            if (_allowLateSubmission)
              _buildDateSelectionTile(
                context,
                icon: Icons.warning,
                title: 'Hạn nộp trễ',
                subtitle: _lateDueDate != null
                    ? _formatDateTime(_lateDueDate!)
                    : 'Chọn hạn nộp trễ',
                iconColor: Colors.orange,
                onTap: () => _selectDate(context, (date) {
                  setState(() => _lateDueDate = date);
                }),
              ),
          ],
        ),
      ),
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

  Widget _buildSubmissionSettings(ThemeData theme) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt nộp bài',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Max attempts
            TextFormField(
              initialValue: _maxAttempts.toString(),
              decoration: const InputDecoration(
                labelText: 'Số lần nộp tối đa',
                hintText: 'Nhập số lần nộp tối đa',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        ),
      ),
    );
  }

  Widget _buildFileSettings(ThemeData theme) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt file',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // File formats
            Text(
              'Định dạng file cho phép:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
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
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Max file size
            TextFormField(
              initialValue: _maxFileSize.toString(),
              decoration: const InputDecoration(
                labelText: 'Kích thước file tối đa (MB)',
                hintText: 'Nhập kích thước file tối đa',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        ),
      ),
    );
  }

  Widget _buildGroupSelection(ThemeData theme) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân phối đến nhóm',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn các nhóm sẽ nhận bài tập này',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final controller = Get.find<AssignmentController>();
                if (controller.isGroupsLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (_selectedCourseId == null) {
                  return const Text('Vui lòng chọn khóa học trước');
                }
                final availableGroups = controller.formState.value.groups
                    .where((_) => _selectedCourseId != null)
                    .toList();
                if (availableGroups.isEmpty) {
                  return const Text('Không có nhóm nào trong khóa học đã chọn');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        controller.selectedGroupIdsForFormRx.isEmpty
                            ? 'Chưa chọn nhóm nào'
                            : 'Đã chọn ${controller.selectedGroupIdsForFormRx.length} nhóm',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
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
                          selectedColor: theme.colorScheme.tertiaryContainer,
                          checkmarkColor: theme.colorScheme.onTertiaryContainer,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onSurface),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog chọn nhóm đã loại bỏ theo góp ý UX; sử dụng inline chips ở trên

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onCancel != null)
          OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onCancel,
            child: const Text('Hủy'),
          ),
        const SizedBox(width: 16),
        FilledButton(
          onPressed: _isSubmitEnabled() ? _handleSubmit : null,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.assignment != null ? 'Cập nhật' : 'Tạo bài tập'),
        ),
      ],
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
    final controller = Get.find<AssignmentController>();
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
    );

    widget.onSubmit(formData);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
  });
}
