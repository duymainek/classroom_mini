import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../student_management/controllers/student_management_controller.dart';
import '../student_import_page.dart';
import '../../../../routes/app_routes.dart';

class StudentManagementSection extends StatelessWidget {
  const StudentManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StudentManagementController>()
        ? Get.find<StudentManagementController>()
        : Get.put(StudentManagementController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quản lý Sinh viên',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => const StudentImportPage());
                  },
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import CSV'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(Routes.STUDENTS_LIST),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Xem tất cả'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = controller.filteredStudents.take(5).toList();
              if (data.isEmpty) {
                return const Text(
                    'Chưa có sinh viên nào. Hãy import CSV hoặc tạo mới.');
              }

              if (ResponsiveBreakpoints.of(context).largerThan(TABLET)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: controller.setQuery,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm nhanh trong 5 sinh viên gần đây...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Họ tên')),
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Trạng thái')),
                        ],
                        rows: data
                            .map((s) => DataRow(cells: [
                                  DataCell(Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        child: Text(_initials(
                                            s['fullName'] ?? s['email'] ?? '')),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(s['fullName'] ?? ''),
                                    ],
                                  )),
                                  DataCell(Text(s['username'] ?? '')),
                                  DataCell(Text(s['email'] ?? '')),
                                  DataCell(_statusChip(s['isActive'] ?? true)),
                                ]))
                            .toList(),
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  final s = data[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(_initials(s['fullName'] ?? s['email'] ?? '')),
                    ),
                    title: Text(s['fullName'] ?? ''),
                    subtitle: Text('${s['username']} · ${s['email']}'),
                    trailing: _statusChip(s['isActive'] ?? true),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: data.length,
              );
            }),
          ),
        ),
      ],
    );
  }
}

Widget _statusChip(bool isActive) {
  return Chip(
    label: Text(isActive ? 'Active' : 'Inactive'),
    side: BorderSide(color: isActive ? Colors.green : Colors.red),
    avatar: Icon(
      isActive ? Icons.check_circle : Icons.cancel,
      color: isActive ? Colors.green : Colors.red,
      size: 18,
    ),
    backgroundColor: (isActive ? Colors.green : Colors.red).withOpacity(0.08),
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
