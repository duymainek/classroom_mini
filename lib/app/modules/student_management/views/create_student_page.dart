import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../student_management/controllers/student_management_controller.dart';
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

  late final StudentManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<StudentManagementController>();
    _controller.initializeCreateStudentForm();
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
                    child: Obx(() {
                      if (_controller.isCreatingStudent.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (_controller.currentStep.value == 0) {
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
                                        _controller.nextStep();
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
                                final items = _controller.courses
                                    .map((e) =>
                                        (id: e['id']!, label: e['label']!))
                                    .toList();
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDropdown(
                                      context,
                                      label: 'Khoá học',
                                      value: _controller
                                              .selectedCourseId.value.isEmpty
                                          ? null
                                          : _controller.selectedCourseId.value,
                                      items: items,
                                      onChanged: _controller.onCourseChanged,
                                    ),
                                    if (_controller.isLoadingCourses.value)
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
                                final items = _controller.groups
                                    .map((e) =>
                                        (id: e['id']!, label: e['label']!))
                                    .toList();
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDropdown(
                                      context,
                                      label: 'Nhóm',
                                      value: _controller
                                              .selectedGroupId.value.isEmpty
                                          ? null
                                          : _controller.selectedGroupId.value,
                                      items: items,
                                      onChanged: _controller.onGroupChanged,
                                    ),
                                    if (_controller.isLoadingGroups.value)
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
                                  onPressed: _controller.previousStep,
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
    return Obx(() {
      final percent = _controller.currentStep.value == 0 ? 0.5 : 1.0;
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
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              _buildStepChip(context, 1, 'Gán nhóm', Icons.school),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            minHeight: 4,
          ),
        ],
      );
    });
  }

  Widget _buildStepChip(
      BuildContext context, int step, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Obx(() {
      final isActive = _controller.currentStep.value == step;
      final isDone = _controller.currentStep.value > step;
      final bg = isActive
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
      final fg = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
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
    });
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Text(value, style: theme.textTheme.bodyMedium),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final created = await _controller.createStudentWithForm(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      email: _emailCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
    );

    if (created != null && mounted) {
      Navigator.pop(context);
    }
  }
}
