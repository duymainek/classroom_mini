import 'package:classroom_mini/app/core/utils/semester_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/assignment_controller.dart';
import 'package:classroom_mini/app/data/models/course_model.dart';
import 'package:classroom_mini/app/data/models/assignment_request_models.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'package:classroom_mini/app/modules/assignments/widgets/assignment_card.dart';
import 'package:classroom_mini/app/data/models/submission_model.dart';
import '../shared/widgets/assignment_form.dart';

class AssignmentListView extends StatelessWidget {
  const AssignmentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Bài tập'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadAssignments(refresh: true),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToCreateAssignment(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filters and search
              _buildFiltersSection(controller),

              // Assignment list
              Expanded(
                child: Obx(() {
                  if (controller.isLoading && controller.assignments.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.assignments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildAssignmentList(controller);
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(AssignmentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(Get.context!).colorScheme.surface,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài tập...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.searchAssignments('');
                        controller.loadAssignments(refresh: true);
                      },
                    )
                  : const SizedBox.shrink()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              controller.searchAssignments(value);
            },
            onSubmitted: (_) => controller.loadAssignments(refresh: true),
          ),

          const SizedBox(height: 16),

          // Filter chips (màu sắc phân biệt trạng thái)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all', controller),
                _buildFilterChip('Sắp mở', 'upcoming', controller),
                _buildFilterChip('Đang mở', 'active', controller),
                _buildFilterChip('Nộp trễ', 'lateSubmission', controller),
                _buildFilterChip('Đã đóng', 'closed', controller),
                _buildFilterChip('Không hoạt động', 'inactive', controller),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sort options
          Row(
            children: [
              const Text('Sắp xếp:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: controller.sortBy,
                items: const [
                  DropdownMenuItem(
                      value: 'created_at', child: Text('Ngày tạo')),
                  DropdownMenuItem(value: 'due_date', child: Text('Hạn chót')),
                  DropdownMenuItem(value: 'title', child: Text('Tiêu đề')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.sortAssignments(value, controller.sortOrder);
                    controller.loadAssignments(refresh: true);
                  }
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: controller.sortOrder,
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Mới nhất')),
                  DropdownMenuItem(value: 'asc', child: Text('Cũ nhất')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.sortAssignments(controller.sortBy, value);
                    controller.loadAssignments(refresh: true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, AssignmentController controller) {
    return Obx(() {
      final isSelected = controller.statusFilter == value;
      final colorScheme = Theme.of(Get.context!).colorScheme;
      final Color chipColor;
      switch (value) {
        case 'upcoming':
          chipColor = colorScheme.primaryContainer;
          break;
        case 'active':
          chipColor = colorScheme.tertiaryContainer;
          break;
        case 'lateSubmission':
          chipColor = colorScheme.errorContainer;
          break;
        case 'closed':
          chipColor = colorScheme.secondaryContainer;
          break;
        case 'inactive':
          chipColor = colorScheme.surfaceVariant;
          break;
        default:
          chipColor = colorScheme.surfaceVariant;
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: chipColor,
          checkmarkColor: colorScheme.onPrimaryContainer,
          onSelected: (selected) {
            controller.filterByStatus(value);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài tập nào',
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo bài tập đầu tiên để bắt đầu',
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateAssignment(Get.context!),
            icon: const Icon(Icons.add),
            label: const Text('Tạo bài tập'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(AssignmentController controller) {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: () => controller.loadAssignments(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount:
              controller.assignments.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.assignments.length) {
              return _buildLoadingIndicator();
            }

            final assignment = controller.assignments[index];
            return AssignmentCard(
              assignment: assignment,
              onTap: () => _navigateToAssignmentDetail(assignment),
              onEdit: () => _navigateToEditAssignment(assignment),
              onDelete: () => _showDeleteDialog(assignment, controller),
              showActions: true,
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _navigateToCreateAssignment(BuildContext context) {
    Get.toNamed(Routes.ASSIGNMENTS_CREATE);
  }

  void _navigateToEditAssignment(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_EDIT, arguments: assignment);
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_DETAIL, arguments: assignment);
  }

  void _showDeleteDialog(
      Assignment assignment, AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa bài tập'),
        content:
            Text('Bạn có chắc chắn muốn xóa bài tập "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAssignment(assignment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class AssignmentCreateView extends StatefulWidget {
  const AssignmentCreateView({Key? key}) : super(key: key);

  @override
  State<AssignmentCreateView> createState() => _AssignmentCreateViewState();
}

class _AssignmentCreateViewState extends State<AssignmentCreateView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _lateDueDate;
  bool _allowLate = false;
  int _maxAttempts = 1;
  int _maxFileSize = 10;
  final Set<String> _fileFormats = <String>{};
  String? _selectedCourseId;
  final Set<String> _selectedGroupIds = <String>{};

  List<Course> _courses = const [];
  List<Map<String, dynamic>> _groups = const [];
  bool _loadingMeta = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loadingMeta = true);
    try {
      final api = DioClient.apiService;
      final courses = await api.getCourses(page: 1, limit: 100);
      setState(() {
        _courses = courses.data.courses;
      });
    } catch (_) {
    } finally {
      setState(() => _loadingMeta = false);
    }
  }

  Future<void> _loadGroups(String courseId) async {
    setState(() => _loadingMeta = true);
    try {
      final api = DioClient.apiService;
      final resp = await api.getGroups(courseId: courseId, page: 1, limit: 200);
      setState(() {
        _groups = resp.data.groups
            .map((g) => {
                  'id': g.id,
                  'name': g.name,
                })
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loadingMeta = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tạo bài tập mới'),
            actions: [
              if (controller.isLoading || _loadingMeta)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final form = _buildForm(theme);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 900 : 600),
                      child: form,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Nhập tiêu đề hợp lệ'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            items: _courses
                .map((c) => DropdownMenuItem(
                    value: c.id, child: Text('${c.code} - ${c.name}')))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedCourseId = val;
                _selectedGroupIds.clear();
              });
              if (val != null) _loadGroups(val);
            },
            decoration: const InputDecoration(
              labelText: 'Khóa học',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'Chọn khóa học' : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
                icon: const Icon(Icons.schedule),
                label: Text('Ngày bắt đầu: ${_fmtDate(_startDate)}'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? (_startDate ?? DateTime.now()),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                icon: const Icon(Icons.flag),
                label: Text('Hạn chót: ${_fmtDate(_dueDate)}'),
              ),
              FilterChip(
                label: const Text('Cho phép nộp trễ'),
                selected: _allowLate,
                onSelected: (v) => setState(() => _allowLate = v),
              ),
              if (_allowLate)
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _lateDueDate ?? (_dueDate ?? DateTime.now()),
                      firstDate: _dueDate ?? DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setState(() => _lateDueDate = date);
                  },
                  icon: const Icon(Icons.warning_amber),
                  label: Text('Hạn nộp trễ: ${_fmtDate(_lateDueDate)}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _maxAttempts.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Số lần nộp',
            ),
            onChanged: (value) {
              final intValue = int.tryParse(value) ?? 1;
              setState(() => _maxAttempts = intValue.clamp(1, 10));
            },
            inputFormatters: [
              // Only allow numbers between 1 and 10
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _maxFileSize.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Dung lượng (MB)',
            ),
            onChanged: (value) {
              final intValue = int.tryParse(value) ?? 10;
              setState(() => _maxFileSize = intValue.clamp(1, 100));
            },
            inputFormatters: [
              // Only allow numbers between 1 and 100
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              'pdf',
              'doc',
              'docx',
              'txt',
              'jpg',
              'jpeg',
              'png',
              'zip',
              'rar'
            ]
                .map((f) => FilterChip(
                      label: Text(f.toUpperCase()),
                      selected: _fileFormats.contains(f),
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _fileFormats.add(f);
                          } else {
                            _fileFormats.remove(f);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (_selectedCourseId != null)
            OutlinedButton.icon(
              onPressed: _pickGroups,
              icon: const Icon(Icons.group_add),
              label: Text(
                _selectedGroupIds.isEmpty
                    ? 'Chọn nhóm phân phối'
                    : 'Đã chọn ${_selectedGroupIds.length} nhóm',
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _onSubmit(Get.find<AssignmentController>()),
            icon: const Icon(Icons.check),
            label: const Text('Tạo bài tập'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickGroups() async {
    if (_selectedCourseId == null) return;
    if (_groups.isEmpty) await _loadGroups(_selectedCourseId!);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final temp = Set<String>.from(_selectedGroupIds);
        return AlertDialog(
          title: const Text('Chọn nhóm'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: _groups.map((g) {
                final id = g['id'] as String;
                final name = g['name'] as String;
                final selected = temp.contains(id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        temp.add(id);
                      } else {
                        temp.remove(id);
                      }
                    });
                  },
                  title: Text(name),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(context, temp),
                child: const Text('Chọn')),
          ],
        );
      },
    );
    if (result != null)
      setState(() => _selectedGroupIds
        ..clear()
        ..addAll(result));
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Chưa chọn';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _onSubmit(AssignmentController controller) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _dueDate == null) {
      Get.snackbar('Thiếu thông tin', 'Chọn ngày bắt đầu và hạn chót');
      return;
    }
    if (_allowLate && _lateDueDate == null) {
      Get.snackbar('Thiếu thông tin', 'Chọn hạn nộp trễ');
      return;
    }
    final req = AssignmentCreateRequest(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      courseId: _selectedCourseId!,
      startDate: _startDate!,
      dueDate: _dueDate!,
      lateDueDate: _allowLate ? _lateDueDate : null,
      allowLateSubmission: _allowLate,
      maxAttempts: _maxAttempts,
      fileFormats: _fileFormats.toList(),
      maxFileSize: _maxFileSize,
      groupIds: _selectedGroupIds.isEmpty ? null : _selectedGroupIds.toList(),
      semesterId: SemesterHelper.getCurrentSemesterId(),
    );

    final ok = await controller.createAssignment(req);
    if (ok) {
      Get.back(result: true);
    }
  }
}

class AssignmentEditView extends StatelessWidget {
  final Assignment assignment;

  const AssignmentEditView({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa bài tập'),
            actions: [
              if (controller.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: _buildAssignmentForm(controller),
        );
      },
    );
  }

  Widget _buildAssignmentForm(AssignmentController controller) {
    return SafeArea(
      child: AssignmentForm(
        assignment: assignment,
        courses: const [],
        groups: const [],
        isLoading: controller.isLoading,
        onCancel: () => Get.back(),
        onSubmit: (form) async {
          final req = AssignmentUpdateRequest(
            id: assignment.id,
            title: form.title,
            description: form.description.isEmpty ? null : form.description,
            courseId: form.courseId,
            startDate: form.startDate,
            dueDate: form.dueDate,
            lateDueDate: form.lateDueDate,
            allowLateSubmission: form.allowLateSubmission,
            maxAttempts: form.maxAttempts,
            fileFormats: form.fileFormats,
            maxFileSize: form.maxFileSize,
            groupIds: form.groupIds.isEmpty ? null : form.groupIds,
          );
          final ok = await controller.updateAssignment(req);
          if (ok) Get.back(result: true);
        },
      ),
    );
  }
}

class AssignmentDetailView extends StatelessWidget {
  final Assignment assignment;

  const AssignmentDetailView({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AssignmentController>(
      init: AssignmentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(assignment.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEdit(assignment),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _exportSubmissions(assignment.id, controller),
              ),
              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleMenuAction(action, assignment, controller),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Sao chép bài tập'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Xóa bài tập',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Thông tin'),
                Tab(icon: Icon(Icons.people), text: 'Nộp bài'),
                Tab(icon: Icon(Icons.analytics), text: 'Thống kê'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildInfoTab(assignment),
              _buildSubmissionsTab(assignment, controller),
              _buildStatisticsTab(assignment, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Assignment assignment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          assignment.title,
                          style: Theme.of(Get.context!)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _buildStatusChip(assignment.status),
                    ],
                  ),

                  if (assignment.description != null &&
                      assignment.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      assignment.description!,
                      style: Theme.of(Get.context!).textTheme.bodyLarge,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Course info
                  if (assignment.course != null)
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text('Khóa học'),
                      subtitle: Text(
                          '${assignment.course!.code} - ${assignment.course!.name}'),
                    ),

                  // Time info
                  _buildTimeInfo(assignment),

                  // Submission settings
                  _buildSubmissionSettings(assignment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(
      Assignment assignment, AssignmentController controller) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color:
                    Theme.of(Get.context!).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sinh viên...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Implement search
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'submitted', child: Text('Đã nộp')),
                  DropdownMenuItem(
                      value: 'not_submitted', child: Text('Chưa nộp')),
                  DropdownMenuItem(value: 'late', child: Text('Nộp trễ')),
                ],
                onChanged: (value) {
                  // Implement filter
                },
              ),
            ],
          ),
        ),

        // Submissions list
        Expanded(
          child: Obx(() {
            if (controller.submissions.isEmpty) {
              return _buildEmptySubmissions();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.submissions.length,
              itemBuilder: (context, index) {
                final submission = controller.submissions[index];
                return _buildSubmissionCard(submission);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(
      Assignment assignment, AssignmentController controller) {
    return Obx(() {
      final totalStudents = controller.submissions.length;
      final submittedCount = controller.submissions
          .where((s) => s.status != SubmissionStatus.notSubmitted)
          .length;
      final notSubmittedCount = totalStudents - submittedCount;
      final lateCount = controller.submissions
          .where((s) => s.status == SubmissionStatus.late)
          .length;
      final gradedCount = controller.submissions
          .where((s) => s.status == SubmissionStatus.graded)
          .length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overview cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng sinh viên',
                    totalStudents.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Đã nộp',
                    submittedCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Chưa nộp',
                    notSubmittedCount.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Nộp trễ',
                    lateCount.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Đã chấm',
                    gradedCount.toString(),
                    Icons.grade,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Tỷ lệ nộp bài',
                    totalStudents > 0
                        ? '${(submittedCount / totalStudents * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.percent,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusChip(AssignmentStatus status) {
    return Chip(
      label: Text(status.displayName),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.upcoming:
        return Colors.blue;
      case AssignmentStatus.open:
        return Colors.green;
      case AssignmentStatus.lateSubmission:
        return Colors.orange;
      case AssignmentStatus.closed:
        return Colors.red;
      case AssignmentStatus.inactive:
        return Colors.grey;
    }
  }

  Widget _buildTimeInfo(Assignment assignment) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Ngày bắt đầu'),
          subtitle: Text(_formatDateTime(assignment.startDate)),
        ),
        ListTile(
          leading: const Icon(Icons.flag),
          title: const Text('Hạn chót'),
          subtitle: Text(_formatDateTime(assignment.dueDate)),
        ),
        if (assignment.lateDueDate != null)
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Hạn nộp trễ'),
            subtitle: Text(_formatDateTime(assignment.lateDueDate!)),
          ),
      ],
    );
  }

  Widget _buildSubmissionSettings(Assignment assignment) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.repeat),
          title: const Text('Số lần nộp tối đa'),
          subtitle: Text(assignment.maxAttempts.toString()),
        ),
        if (assignment.fileFormats.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Định dạng file'),
            subtitle: Text(assignment.fileFormats.join(', ')),
          ),
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Kích thước file tối đa'),
          subtitle: Text('${assignment.maxFileSize} MB'),
        ),
      ],
    );
  }

  Widget _buildEmptySubmissions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 64,
            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sinh viên nào nộp bài',
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(SubmissionTrackingData submission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSubmissionStatusColor(submission.status),
          child: Icon(
            _getSubmissionStatusIcon(submission.status),
            color: Colors.white,
          ),
        ),
        title: Text(submission.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(submission.email),
            if (submission.latestSubmission != null) ...[
              const SizedBox(height: 4),
              Text(
                'Lần ${submission.latestSubmission!.attemptNumber} - ${_formatDateTime(submission.latestSubmission!.submittedAt)}',
                style: Theme.of(Get.context!).textTheme.bodySmall,
              ),
              if (submission.latestSubmission!.grade != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Điểm: ${submission.latestSubmission!.grade!.toStringAsFixed(1)}/100',
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            _getGradeColor(submission.latestSubmission!.grade!),
                      ),
                ),
              ],
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(submission.status.displayName),
              backgroundColor: _getSubmissionStatusColor(submission.status),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleSubmissionAction(value, submission),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Xem chi tiết'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'grade',
                  child: ListTile(
                    leading: Icon(Icons.grade),
                    title: Text('Chấm điểm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubmissionStatusColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Colors.red;
      case SubmissionStatus.submitted:
        return Colors.blue;
      case SubmissionStatus.late:
        return Colors.orange;
      case SubmissionStatus.graded:
        return Colors.green;
    }
  }

  IconData _getSubmissionStatusIcon(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Icons.cancel;
      case SubmissionStatus.submitted:
        return Icons.check_circle;
      case SubmissionStatus.late:
        return Icons.warning;
      case SubmissionStatus.graded:
        return Icons.grade;
    }
  }

  Color _getGradeColor(double grade) {
    if (grade >= 80) return Colors.green;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(Assignment assignment) {
    Get.toNamed(Routes.ASSIGNMENTS_EDIT, arguments: assignment);
  }

  void _exportSubmissions(
      String assignmentId, AssignmentController controller) async {
    final csvData = await controller.exportSubmissions(assignmentId);
    if (csvData != null) {
      Get.snackbar('Thành công', 'Xuất dữ liệu thành công');
    }
  }

  void _handleMenuAction(
      String action, Assignment assignment, AssignmentController controller) {
    switch (action) {
      case 'duplicate':
        // Implement duplicate
        break;
      case 'delete':
        _showDeleteDialog(assignment, controller);
        break;
    }
  }

  void _showDeleteDialog(
      Assignment assignment, AssignmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa bài tập'),
        content:
            Text('Bạn có chắc chắn muốn xóa bài tập "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAssignment(assignment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _handleSubmissionAction(
      String action, SubmissionTrackingData submission) {
    switch (action) {
      case 'view':
        // Navigate to submission detail
        break;
      case 'grade':
        // Navigate to grading
        break;
    }
  }
}
