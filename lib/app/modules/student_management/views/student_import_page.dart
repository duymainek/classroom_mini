import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../student_management/controllers/student_management_controller.dart';

class StudentImportPage extends StatefulWidget {
  const StudentImportPage({super.key});

  @override
  State<StudentImportPage> createState() => _StudentImportPageState();
}

class _StudentImportPageState extends State<StudentImportPage> {
  late final StudentManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<StudentManagementController>();
    _controller.loadImportCoursesAndGroups();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Obx(() {
      final stats = _controller.computeImportStats();
      final hasError = stats['errors']! > 0 || _controller.importRows.isEmpty;

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
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Import CSV Sinh viên'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                        colorScheme.secondaryContainer.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // File Selection Section
                  _buildModernSection(
                    context,
                    title: 'Chọn tệp CSV',
                    icon: Icons.file_upload_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _controller.isImporting.value
                                  ? null
                                  : _controller.pickAndPreviewCsv,
                              icon: const Icon(Icons.file_open),
                              label: const Text('Chọn CSV'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_controller.isImporting.value) ...[
                            const SizedBox(width: 16),
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Assignment Settings Section
                  if (_controller.importRows.isNotEmpty) ...[
                    _buildModernSection(
                      context,
                      title: 'Cài đặt phân công',
                      icon: Icons.assignment_outlined,
                      children: [
                        _buildModernSwitchTile(
                          context,
                          title: 'Gán tất cả cho cùng một khóa học/nhóm',
                          subtitle:
                              'Tất cả sinh viên sẽ được gán vào cùng một khóa học và nhóm',
                          value: _controller.useGlobalAssignment.value,
                          onChanged: (value) {
                            _controller.setUseGlobalAssignment(value);
                          },
                          icon: Icons.group_work_outlined,
                        ),
                        if (_controller.useGlobalAssignment.value) ...[
                          const SizedBox(height: 16),
                          _buildModernDropdown<Course>(
                            context,
                            title: 'Chọn khóa học',
                            value: _controller.selectedImportCourse.value,
                            items: _controller.importCourses,
                            onChanged: (course) {
                              _controller.setImportCourse(course);
                            },
                            itemBuilder: (course) =>
                                '${course.code} - ${course.name}',
                            icon: Icons.school_outlined,
                          ),
                          if (_controller.selectedImportCourse.value !=
                              null) ...[
                            const SizedBox(height: 16),
                            _buildModernDropdown<Group>(
                              context,
                              title: 'Chọn nhóm',
                              value: _controller.selectedImportGroup.value,
                              items: _controller.importGroups
                                  .where((g) =>
                                      g.courseId ==
                                      _controller
                                          .selectedImportCourse.value!.id)
                                  .toList(),
                              onChanged: (group) {
                                _controller.setImportGroup(group);
                              },
                              itemBuilder: (group) => group.name,
                              icon: Icons.group_outlined,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: colorScheme.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Gán từng sinh viên riêng lẻ',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bạn có thể gán khóa học và nhóm cho từng sinh viên trong danh sách bên dưới.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Preview Results Section
                  if (_controller.importRows.isNotEmpty) ...[
                    _buildModernSection(
                      context,
                      title: 'Kết quả xem trước',
                      icon: Icons.preview_outlined,
                      children: [
                        if (isWide)
                          _buildWideDataTable(context)
                        else
                          _buildMobileListView(context),
                      ],
                    ),
                  ],

                  // Summary Section
                  if (_controller.importRows.isNotEmpty) ...[
                    _buildModernSection(
                      context,
                      title: 'Tổng kết',
                      icon: Icons.summarize_outlined,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSummaryChip(
                              context,
                              icon: Icons.check_circle_outline,
                              label: 'Sẵn sàng',
                              count: stats['ready']!,
                              color: Colors.green,
                            ),
                            _buildSummaryChip(
                              context,
                              icon: Icons.error_outline,
                              label: 'Lỗi',
                              count: stats['errors']!,
                              color: Colors.red,
                            ),
                            _buildSummaryChip(
                              context,
                              icon: Icons.summarize_outlined,
                              label: 'Tổng',
                              count: stats['total']!,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Action Buttons
                  if (_controller.importRows.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
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
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _controller.isImporting.value || hasError
                                ? null
                                : _controller.confirmImport,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _controller.isImporting.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Xác nhận Import'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Helper methods for Material 3 design
  Widget _buildModernSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
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
        secondary: Icon(icon, color: colorScheme.primary),
        activeThumbColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildModernDropdown<T>(
    BuildContext context, {
    required String title,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
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
        subtitle: value != null
            ? Text(
                itemBuilder(value),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                'Chọn $title',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showDropdownDialog<T>(
          context,
          title: title,
          items: items,
          currentValue: value,
          onChanged: onChanged,
          itemBuilder: itemBuilder,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showDropdownDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T? currentValue,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length + 1, // +1 for "None" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('Không chọn'),
                  leading: const Icon(Icons.clear),
                  selected: currentValue == null,
                  onTap: () {
                    onChanged(null);
                    Navigator.of(context).pop();
                  },
                );
              }
              final item = items[index - 1];
              return ListTile(
                title: Text(itemBuilder(item)),
                selected: currentValue == item,
                onTap: () {
                  onChanged(item);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideDataTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('#')),
          const DataColumn(label: Text('username')),
          const DataColumn(label: Text('email')),
          const DataColumn(label: Text('fullName')),
          const DataColumn(label: Text('isActive')),
          const DataColumn(label: Text('Trạng thái')),
          const DataColumn(label: Text('Lỗi')),
          if (!_controller.useGlobalAssignment.value) ...[
            const DataColumn(label: Text('Khóa học')),
            const DataColumn(label: Text('Nhóm')),
          ],
          const DataColumn(label: Text('')),
        ],
        rows: List<DataRow>.generate(_controller.importRows.length, (i) {
          final r = _controller.importRows[i];
          final original = (r['_rowNumber'] as num?)?.toInt();
          final result =
              original != null ? _controller.rowResultByNumber[original] : null;
          final status = (result?['status'] ?? '').toString();
          final upper = status.toUpperCase();
          final isReady = upper == 'READY' || upper == 'CREATED';
          final isError = !isReady;
          final errors = result?['errors'] as List<dynamic>? ?? [];

          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (states) => isError
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
            ),
            cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text('${r['username'] ?? ''}')),
              DataCell(Text('${r['email'] ?? ''}')),
              DataCell(Text('${r['fullName'] ?? ''}')),
              DataCell(Text('${r['isActive'] ?? ''}')),
              DataCell(
                Text(
                  isError ? (status.isEmpty ? 'Lỗi' : status) : 'Sẵn sàng',
                  style: TextStyle(
                    color: isError ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                errors.isNotEmpty
                    ? Tooltip(
                        message: errors.join('\n'),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (!_controller.useGlobalAssignment.value) ...[
                DataCell(
                  Obx(() => _buildCompactDropdown<Course>(
                        context,
                        title: 'Khóa học',
                        value: _controller.rowCourseAssignments[i],
                        items: _controller.importCourses,
                        onChanged: (course) =>
                            _controller.updateRowCourseAssignment(i, course),
                        itemBuilder: (course) =>
                            '${course.code} - ${course.name}',
                      )),
                ),
                DataCell(
                  Obx(() {
                    final courseId = _controller.rowCourseAssignments[i]?.id;
                    return _buildCompactDropdown<Group>(
                      context,
                      title: 'Nhóm',
                      value: _controller.rowGroupAssignments[i],
                      items: courseId != null
                          ? _controller.importGroups
                              .where((g) => g.courseId == courseId)
                              .toList()
                          : _controller.importGroups,
                      onChanged: (group) =>
                          _controller.updateRowGroupAssignment(i, group),
                      itemBuilder: (group) => group.name,
                    );
                  }),
                ),
              ],
              DataCell(
                IconButton(
                  tooltip: 'Loại bỏ',
                  onPressed: () => _controller.removeImportRow(i),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMobileListView(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (_, i) {
        final r = _controller.importRows[i];
        final original = (r['_rowNumber'] as num?)?.toInt();
        final result =
            original != null ? _controller.rowResultByNumber[original] : null;
        final status = (result?['status'] ?? '').toString();
        final upper = status.toUpperCase();
        final isReady = upper == 'READY' || upper == 'CREATED';
        final isError = !isReady;
        final errors = result?['errors'] as List<dynamic>? ?? [];
        final String label =
            isError ? (status.isEmpty ? 'Lỗi' : status) : 'Sẵn sàng';

        return Dismissible(
          key: ValueKey(r['_rowNumber'] ?? i),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _controller.removeImportRow(i),
          child: Card(
            shape: isError
                ? RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text('${i + 1}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r['fullName'] ?? ''}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text('${r['email'] ?? ''}'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isError
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isError ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 6),
                      Text('username: ${r['username'] ?? ''}'),
                      const SizedBox(width: 12),
                      const Icon(Icons.verified_user, size: 16),
                      const SizedBox(width: 6),
                      Text('active: ${r['isActive'] ?? ''}'),
                    ],
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Lỗi:',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...errors.map((error) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 2),
                                child: Text(
                                  '• $error',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 11,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // Individual assignment controls
                  if (!_controller.useGlobalAssignment.value) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phân công khóa học/nhóm',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => _buildCompactDropdown<Course>(
                                      context,
                                      title: 'Khóa học',
                                      value:
                                          _controller.rowCourseAssignments[i],
                                      items: _controller.importCourses,
                                      onChanged: (course) => _controller
                                          .updateRowCourseAssignment(i, course),
                                      itemBuilder: (course) =>
                                          '${course.code} - ${course.name}',
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() {
                                  final courseId =
                                      _controller.rowCourseAssignments[i]?.id;
                                  return _buildCompactDropdown<Group>(
                                    context,
                                    title: 'Nhóm',
                                    value: _controller.rowGroupAssignments[i],
                                    items: courseId != null
                                        ? _controller.importGroups
                                            .where(
                                                (g) => g.courseId == courseId)
                                            .toList()
                                        : _controller.importGroups,
                                    onChanged: (group) => _controller
                                        .updateRowGroupAssignment(i, group),
                                    itemBuilder: (group) => group.name,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _controller.importRows.length,
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text('$label: $count'),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildCompactDropdown<T>(
    BuildContext context, {
    required String title,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: value != null
            ? Text(
                itemBuilder(value),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                'Chọn $title',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
        trailing: const Icon(Icons.arrow_drop_down, size: 16),
        onTap: () => _showCompactDropdownDialog<T>(
          context,
          title: title,
          items: items,
          currentValue: value,
          onChanged: onChanged,
          itemBuilder: itemBuilder,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  void _showCompactDropdownDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T? currentValue,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length + 1, // +1 for "None" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  dense: true,
                  title: const Text('Không chọn'),
                  leading: const Icon(Icons.clear, size: 16),
                  selected: currentValue == null,
                  onTap: () {
                    onChanged(null);
                    Navigator.of(context).pop();
                  },
                );
              }
              final item = items[index - 1];
              return ListTile(
                dense: true,
                title: Text(itemBuilder(item)),
                selected: currentValue == item,
                onTap: () {
                  onChanged(item);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
