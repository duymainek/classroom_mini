import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
// import 'package:data_table_2/data_table_2.dart';
import '../../student_management/controllers/student_management_controller.dart';
import '../views/student_import_page.dart';
import '../../../routes/app_routes.dart';

class ResponsiveStudentManagementPage
    extends GetView<StudentManagementController> {
  const ResponsiveStudentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sinh viên'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (ResponsiveBreakpoints.of(context).largerThan(TABLET)) {
            return _DesktopView(controller: controller);
          } else if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
            return _TabletView(controller: controller);
          } else {
            return _MobileView(controller: controller);
          }
        },
      ),
      floatingActionButton: _FabActions(controller: controller),
    );
  }
}

class _DesktopView extends StatelessWidget {
  final StudentManagementController controller;
  const _DesktopView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        );
      }

      final data = controller.filteredStudents;

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search and Filter Section
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: controller.setQuery,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: 'Tìm theo họ tên, email hoặc username...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data Table
            Expanded(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                child: data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy sinh viên phù hợp',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy thử thay đổi từ khóa tìm kiếm hoặc thêm sinh viên mới',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 20,
                          columns: [
                            DataColumn(
                              label: Text(
                                'Sinh viên',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Username',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Email',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Trạng thái',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Hành động',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                          rows: data
                              .map((s) => DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              child: Text(
                                                _initials(s['fullName'] ??
                                                    s['email'] ??
                                                    ''),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    s['fullName'] ?? '',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  Text(
                                                    'ID: ${s['id']}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          s['username'] ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          s['email'] ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                          _statusChip(s['isActive'] ?? true)),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Xem chi tiết',
                                              onPressed: () =>
                                                  _showDetailSheet(context, s),
                                              icon: const Icon(
                                                  Icons.visibility_rounded),
                                              style: IconButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Chỉnh sửa',
                                              onPressed: () =>
                                                  _showEditNameSheet(
                                                      context, controller, s),
                                              icon: const Icon(
                                                  Icons.edit_rounded),
                                              style: IconButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Xoá',
                                              onPressed: () =>
                                                  _showDeleteDialog(
                                                      context, controller, s),
                                              icon: const Icon(
                                                  Icons.delete_rounded),
                                              style: IconButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TabletView extends _DesktopView {
  const _TabletView({required super.controller});
}

class _MobileView extends StatelessWidget {
  final StudentManagementController controller;
  const _MobileView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        );
      }

      final data = controller.filteredStudents;

      return RefreshIndicator(
        onRefresh: controller.refreshStudents,
        child: CustomScrollView(
          slivers: [
            // Search Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: controller.setQuery,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      hintText:
                          'Tìm sinh viên theo tên, email hoặc username...',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),

            // Empty State
            if (data.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Chưa có sinh viên nào',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hãy thêm sinh viên mới hoặc thử thay đổi từ khóa tìm kiếm',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () =>
                              _showAddStudentSheet(context, controller),
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('Thêm sinh viên đầu tiên'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Student Cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 100), // Bottom padding for FAB
                sliver: SliverList.separated(
                  itemBuilder: (_, i) {
                    final s = data[i];
                    return _StudentCard(
                      student: s,
                      controller: controller,
                      onTap: () => Get.toNamed(
                          '${Routes.STUDENT_DETAILS}?id=${s['id']}'),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: data.length,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final StudentManagementController controller;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Info Row: Avatar + Name + Status + Actions
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      _initials(student['fullName'] ?? student['email'] ?? ''),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name only
                        Text(
                          student['fullName'] ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          student['email'] ?? '',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showDetailSheet(context, student);
                          break;
                        case 'edit':
                          _showEditNameSheet(context, controller, student);
                          break;
                        case 'delete':
                          _showDeleteDialog(context, controller, student);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility_rounded),
                          title: Text('Xem chi tiết'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Chỉnh sửa'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_rounded),
                          title: Text('Xoá'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Secondary Info: Username and Status
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    student['username'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  _statusIndicator(student['isActive'] ?? true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabActions extends StatelessWidget {
  final StudentManagementController controller;
  const _FabActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openActions(context),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Thêm sinh viên',
          style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _openActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Thêm sinh viên'),
                        subtitle: const Text('Tạo sinh viên mới'),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddStudentSheet(context, controller);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.refresh_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Tải lại'),
                        subtitle: const Text('Làm mới danh sách sinh viên'),
                        onTap: () {
                          Navigator.pop(context);
                          controller.refreshStudents();
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.file_upload_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: const Text('Import CSV'),
                        subtitle: const Text('Nhập danh sách từ file CSV'),
                        onTap: () {
                          Navigator.pop(context);
                          Get.to(() => const StudentImportPage());
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.file_download_rounded,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        title: const Text('Export CSV'),
                        subtitle: const Text('Xuất danh sách ra file CSV'),
                        onTap: () async {
                          Navigator.pop(context);
                          final ok =
                              await controller.exportStudents(format: 'csv');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Đã yêu cầu xuất CSV (kiểm tra tải xuống)'
                                    : 'Xuất CSV thất bại'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showAddStudentSheet(
    BuildContext context, StudentManagementController controller) {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm sinh viên mới',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: fullNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email không hợp lệ'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu tạm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final created = await controller.createStudent(
                            username: usernameCtrl.text.trim(),
                            password: passwordCtrl.text,
                            email: emailCtrl.text.trim(),
                            fullName: fullNameCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(created != null
                                    ? 'Đã tạo sinh viên mới'
                                    : 'Tạo thất bại'),
                                backgroundColor: created != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Tạo sinh viên'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _statusIndicator(bool isActive) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        isActive ? 'Hoạt động' : 'Không hoạt động',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    ],
  );
}

Widget _statusChip(bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isActive
          ? Colors.green.withOpacity(0.12)
          : Colors.red.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isActive
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isActive ? Colors.green.shade600 : Colors.red.shade600,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Hoạt động' : 'Không hoạt động',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    ),
  );
}

String _initials(String nameOrEmail) {
  final source = nameOrEmail.trim();
  if (source.isEmpty) return '?';
  final parts = source.contains(' ')
      ? source.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList()
      : source.split('@').first.split('.');
  final first = parts.isNotEmpty ? parts.first.characters.first : '';
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}

void _showDetailSheet(BuildContext context, Map<String, dynamic> s) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      _initials(s['fullName'] ?? s['email'] ?? ''),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['fullName'] ?? '',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['email'] ?? '',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _statusIndicator(s['isActive'] ?? true),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Username',
                value: s['username'] ?? '',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'ID',
                value: s['id'] ?? '',
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final controller =
                            Get.find<StudentManagementController>();
                        _showEditNameSheet(context, controller, s);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Chỉnh sửa'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteDialog(context,
                            Get.find<StudentManagementController>(), s);
                      },
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Xoá'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

void _showDeleteDialog(BuildContext context,
    StudentManagementController controller, Map<String, dynamic> s) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
      title: const Text('Xoá sinh viên'),
      content: Text(
        'Bạn có chắc chắn muốn xoá sinh viên "${s['fullName'] ?? s['username']}"?\n\nHành động này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final success =
                await controller.deleteStudentById(s['id'] as String);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã xoá sinh viên' : 'Xoá thất bại'),
                  backgroundColor: success
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
}

void _showEditNameSheet(BuildContext context,
    StudentManagementController controller, Map<String, dynamic> s) {
  final textController = TextEditingController(text: s['fullName'] ?? '');
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉnh sửa họ tên',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final newName = textController.text.trim();
                        if (newName.isEmpty) return;
                        final ok = await controller.updateStudentName(
                            s['id'] as String, newName);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'Đã cập nhật' : 'Cập nhật thất bại'),
                              backgroundColor: ok
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
