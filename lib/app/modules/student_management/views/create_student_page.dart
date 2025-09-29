import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../student_management/controllers/student_management_controller.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/semester_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../core/app_config.dart';

class CreateStudentPage extends StatefulWidget {
  const CreateStudentPage({super.key});

  @override
  State<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<CreateStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _submitting = false;
  int _currentStep = 0;
  bool _isLoadingCourses = false;
  bool _isLoadingGroups = false;

  // Reactive mirrors to ensure UI updates instantly via Obx
  final RxList<Map<String, String>> _coursesRx = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> _groupsRx = <Map<String, String>>[].obs;
  final RxBool _isLoadingCoursesRx = false.obs;
  final RxBool _isLoadingGroupsRx = false.obs;

  void _log(String msg) {
    // Simple namespaced logger for this page
    // ignore: avoid_print
    print('[CreateStudent] ' + msg);
  }

  String? _selectedSemesterId;
  String? _selectedCourseId;
  String? _selectedGroupId;

  List<({String id, String label})> _courses = [];
  List<({String id, String label})> _groups = [];

  late final SemesterRepository _semesterRepo;
  late final CourseRepository _courseRepo;
  late final GroupRepository _groupRepo;

  @override
  void initState() {
    super.initState();
    final api = Get.find<ApiService>();
    _semesterRepo = SemesterRepository(api);
    _courseRepo = CourseRepository(api);
    _groupRepo = GroupRepository(api);
    _ensureSemesterContext();
  }

  Future<void> _ensureSemesterContext() async {
    final cfg = AppConfig.instance;
    if (cfg.hasSelectedSemester()) {
      _log('AppConfig semester: id=' +
          cfg.selectedSemesterId +
          ' name=' +
          cfg.selectedSemesterName);
      _selectedSemesterId = cfg.selectedSemesterId;
      await _loadCourses(cfg.selectedSemesterId);
      return;
    }
    try {
      // Fallback: fetch current semester and set AppConfig
      _log('No semester in AppConfig. Fetching current semester...');
      final current = await Get.find<ApiService>().getCurrentSemester();
      if (current.success && current.data?.currentSemester != null) {
        final s = current.data!.currentSemester!;
        _log('Fetched current semester: id=' + s.id + ' name=' + s.name);
        AppConfig.instance.setSelectedSemester(
          semesterId: s.id,
          semesterName: s.name,
          semesterCode: s.code,
        );
        setState(() {
          _selectedSemesterId = s.id;
        });
        await _loadCourses(s.id);
      }
    } catch (_) {
      // ignore, UI will show fallback text
    }
  }

  Future<void> _loadCourses(String semesterId) async {
    try {
      setState(() => _isLoadingCourses = true);
      _isLoadingCoursesRx.value = true;
      _log('Loading courses for semester=' +
          semesterId +
          ' (via /courses?semesterId=...) ...');
      // Use generic /courses?semesterId= to ensure semester_id is present for parsing
      final res = await _courseRepo.getCourses(
        page: 1,
        limit: 100,
        search: '',
        status: 'active',
        semesterId: semesterId,
      );
      setState(() {
        _courses =
            (res.data.courses).map((c) => (id: c.id, label: c.name)).toList();
        _coursesRx.assignAll(
          res.data.courses.map((c) => {'id': c.id, 'label': c.name}).toList(),
        );
        if (_selectedCourseId == null && _coursesRx.length == 1) {
          _selectedCourseId = _coursesRx.first['id'];
          _log('Auto-selected single course: ' + (_selectedCourseId ?? 'null'));
          // ignore: discarded_futures
          _loadGroups(_selectedCourseId!);
        }
      });
      _log('Courses loaded: count=' +
          _coursesRx.length.toString() +
          ' ids=[' +
          _coursesRx.map((e) => e['id']).join(',') +
          ']');
    } catch (_) {
      _log('Error loading courses');
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
      _isLoadingCoursesRx.value = false;
    }
  }

  Future<void> _loadGroups(String courseId) async {
    try {
      setState(() => _isLoadingGroups = true);
      _isLoadingGroupsRx.value = true;
      _log('Loading groups for course=' + courseId + ' ...');
      final res = await _groupRepo.getGroupsByCourse(courseId,
          limit: 100, status: 'active');
      setState(() {
        _groups =
            (res.data.groups).map((g) => (id: g.id, label: g.name)).toList();
        _groupsRx.assignAll(
          res.data.groups.map((g) => {'id': g.id, 'label': g.name}).toList(),
        );
      });
      _log('Groups loaded: count=' +
          _groupsRx.length.toString() +
          ' ids=[' +
          _groupsRx.map((e) => e['id']).join(',') +
          ']');
    } catch (_) {
      _log('Error loading groups');
    } finally {
      if (mounted) setState(() => _isLoadingGroups = false);
      _isLoadingGroupsRx.value = false;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cfg = AppConfig.instance;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            elevation: 0,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Tạo sinh viên mới'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressHeader(context),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Builder(builder: (context) {
                      if (_submitting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (_currentStep == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSection(
                              context,
                              title: 'Thông tin tài khoản',
                              icon: Icons.person_add_rounded,
                              children: [
                                _buildTextField(
                                  controller: _fullNameCtrl,
                                  label: 'Họ tên',
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nhập họ tên'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? 'Email không hợp lệ'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _usernameCtrl,
                                  label: 'Username',
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nhập username'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _passwordCtrl,
                                  label: 'Mật khẩu',
                                  keyboardType: TextInputType.visiblePassword,
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Ít nhất 6 ký tự'
                                      : null,
                                  obscure: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Huỷ'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _currentStep = 1);
                                        if (_courses.isEmpty &&
                                            _selectedSemesterId != null) {
                                          // Ensure courses are loaded when moving to step 2
                                          // ignore: discarded_futures
                                          _loadCourses(_selectedSemesterId!);
                                        }
                                      }
                                    },
                                    child: const Text('Tiếp theo'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSection(
                            context,
                            title: 'Gán vào khoá và nhóm',
                            icon: Icons.school_rounded,
                            children: [
                              _buildReadOnlyField(
                                context,
                                label: 'Học kỳ',
                                value: cfg.hasSelectedSemester()
                                    ? '${cfg.selectedSemesterName} (${cfg.selectedSemesterCode})'
                                    : 'Chưa có học kỳ',
                              ),
                              const SizedBox(height: 12),
                              Obx(() {
                                final items = _coursesRx.isNotEmpty
                                    ? _coursesRx
                                        .map((e) =>
                                            (id: e['id']!, label: e['label']!))
                                        .toList()
                                    : _courses;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDropdown(
                                      context,
                                      label: 'Khoá học',
                                      value: _selectedCourseId,
                                      items: items,
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedCourseId = v;
                                          _selectedGroupId = null;
                                          _groups = [];
                                          _groupsRx.clear();
                                        });
                                        if (v != null) _loadGroups(v);
                                      },
                                    ),
                                    if (_isLoadingCoursesRx.value)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: LinearProgressIndicator(
                                            minHeight: 2),
                                      ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              Obx(() {
                                final items = _groupsRx.isNotEmpty
                                    ? _groupsRx
                                        .map((e) =>
                                            (id: e['id']!, label: e['label']!))
                                        .toList()
                                    : _groups;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDropdown(
                                      context,
                                      label: 'Nhóm',
                                      value: _selectedGroupId,
                                      items: items,
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedGroupId = v;
                                        });
                                      },
                                    ),
                                    if (_isLoadingGroupsRx.value)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: LinearProgressIndicator(
                                            minHeight: 2),
                                      ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 4),
                              Text(
                                'Luồng: Tạo tài khoản → Khoá học → Nhóm',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _currentStep = 0),
                                  child: const Text('Quay lại'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: _handleSubmit,
                                  child: const Text('Hoàn tất'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = _currentStep == 0 ? 0.5 : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildStepChip(context, 0, 'Thông tin', Icons.person),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            _buildStepChip(context, 1, 'Gán nhóm', Icons.school),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          color: colorScheme.primary,
          backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildStepChip(
      BuildContext context, int step, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    final bg = isActive
        ? colorScheme.primary.withOpacity(0.12)
        : colorScheme.surfaceVariant.withOpacity(0.4);
    final fg = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDone ? Icons.check_circle : icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<({String id, String label})> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e.id,
                child: Text(e.label),
              ))
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: items.isEmpty ? 'Không có dữ liệu' : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      icon: const Icon(Icons.arrow_drop_down_rounded),
      isExpanded: true,
    );
  }

  Widget _buildReadOnlyField(BuildContext context,
      {required String label, required String value}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Text(value, style: theme.textTheme.bodyMedium),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final controller = Get.find<StudentManagementController>();
      // Require course and group selection before creating, so we can attach during creation
      if (_selectedCourseId == null || _selectedGroupId == null) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn khoá và nhóm để gán')),
        );
        return;
      }

      // Create student with selected course/group
      final created = await controller.createStudent(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        email: _emailCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
        groupId: _selectedGroupId,
        courseId: _selectedCourseId,
      );

      if (!mounted) return;
      if (created == null) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo tài khoản thất bại')),
        );
        return;
      }

      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo sinh viên và gán nhóm/khoá.')),
        );
        Get.back();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra')));
    }
  }
}
