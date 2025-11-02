import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CourseFormWidget extends StatefulWidget {
  final String? initialCode;
  final String? initialName;
  final int? initialSessionCount;
  final String? initialSemesterId;
  final bool? initialIsActive;
  final List<Semester> semesters;
  final String title;
  final String submitText;
  final Function(String code, String name, int sessionCount, String semesterId,
      bool isActive) onSubmit;

  const CourseFormWidget({
    Key? key,
    this.initialCode,
    this.initialName,
    this.initialSessionCount,
    this.initialSemesterId,
    this.initialIsActive,
    required this.semesters,
    required this.title,
    required this.submitText,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CourseFormWidget> createState() => _CourseFormWidgetState();
}

class _CourseFormWidgetState extends State<CourseFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  int _sessionCount = 10;
  String? _selectedSemesterId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.initialCode ?? '';
    _nameController.text = widget.initialName ?? '';
    _sessionCount = widget.initialSessionCount ?? 10;
    _selectedSemesterId = widget.initialSemesterId;
    _isActive = widget.initialIsActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
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
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã khóa học',
                  hintText: 'Nhập mã khóa học',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mã khóa học không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Mã khóa học phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khóa học',
                  hintText: 'Nhập tên khóa học',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên khóa học không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Tên khóa học phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSemesterId,
                decoration: const InputDecoration(
                  labelText: 'Học kỳ',
                  border: OutlineInputBorder(),
                ),
                items: widget.semesters
                    .where((s) => s.isActive)
                    .map((semester) => DropdownMenuItem(
                          value: semester.id,
                          child: Text('${semester.code} - ${semester.name}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemesterId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn học kỳ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _sessionCount,
                decoration: const InputDecoration(
                  labelText: 'Số buổi học',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 buổi')),
                  DropdownMenuItem(value: 15, child: Text('15 buổi')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sessionCount = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                subtitle: const Text('Khóa học có thể sử dụng'),
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
        _codeController.text.trim(),
        _nameController.text.trim(),
        _sessionCount,
        _selectedSemesterId!,
        _isActive,
      );
      Get.back();
    }
  }
}
