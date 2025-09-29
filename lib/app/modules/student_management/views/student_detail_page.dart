import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../student_management/controllers/student_management_controller.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late TextEditingController nameController;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<StudentManagementController>();
    final student = controller.findById(widget.studentId);
    if (student != null) {
      nameController = TextEditingController(text: student['fullName'] ?? '');
      isActive = (student['isActive'] ?? true) as bool;
    } else {
      nameController = TextEditingController();
      isActive = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentManagementController>();
    final student = controller.findById(widget.studentId);
    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sinh viên')),
        body: const Center(child: Text('Không tìm thấy sinh viên')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sinh viên')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 28,
                    child: Text(_initials(
                        student['fullName'] ?? student['email'] ?? ''))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(student['email'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium)),
                _statusChip(isActive),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Họ tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đang hoạt động'),
              value: isActive,
              onChanged: (v) {
                setState(() {
                  isActive = v;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                // Update both name and active status
                final nameOk = await controller.updateStudentName(
                    widget.studentId, nameController.text.trim());
                final statusOk = await controller.updateStudentActive(
                    widget.studentId, isActive);

                if (context.mounted) {
                  if (nameOk && statusOk) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu thay đổi')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lưu thất bại')));
                  }
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _statusChip(bool isActive) {
  return Chip(
    label: Text(isActive ? 'Active' : 'Deactive'),
    side: BorderSide(color: isActive ? Colors.green : Colors.red),
    avatar: Icon(isActive ? Icons.check_circle : Icons.cancel,
        color: isActive ? Colors.green : Colors.red, size: 18),
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
