import 'package:classroom_mini/app/data/models/course_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialCourseId;
  final bool? initialIsActive;
  final List<Course> courses;
  final String title;
  final String submitText;
  final Function(String name, String courseId, bool isActive) onSubmit;

  const GroupFormWidget({
    Key? key,
    this.initialName,
    this.initialCourseId,
    this.initialIsActive,
    required this.courses,
    required this.title,
    required this.submitText,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<GroupFormWidget> createState() => _GroupFormWidgetState();
}

class _GroupFormWidgetState extends State<GroupFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedCourseId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedCourseId = widget.initialCourseId;
    _isActive = widget.initialIsActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhóm',
                  hintText: 'Nhập tên nhóm',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên nhóm không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Tên nhóm phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Khóa học',
                  border: OutlineInputBorder(),
                ),
                items: widget.courses
                    .where((c) => c.isActive)
                    .map((course) => DropdownMenuItem(
                          value: course.id,
                          child: Text('${course.code} - ${course.name}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn khóa học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                subtitle: const Text('Nhóm có thể sử dụng'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.submitText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text.trim(),
        _selectedCourseId!,
        _isActive,
      );
      Get.back();
    }
  }
}
