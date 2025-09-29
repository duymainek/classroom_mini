import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SemesterFormWidget extends StatefulWidget {
  final String? initialCode;
  final String? initialName;
  final bool? initialIsActive;
  final String title;
  final String submitText;
  final Function(String code, String name, bool isActive) onSubmit;

  const SemesterFormWidget({
    Key? key,
    this.initialCode,
    this.initialName,
    this.initialIsActive,
    required this.title,
    required this.submitText,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<SemesterFormWidget> createState() => _SemesterFormWidgetState();
}

class _SemesterFormWidgetState extends State<SemesterFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.initialCode ?? '';
    _nameController.text = widget.initialName ?? '';
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
                  labelText: 'Mã học kỳ',
                  hintText: 'Nhập mã học kỳ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mã học kỳ không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Mã học kỳ phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên học kỳ',
                  hintText: 'Nhập tên học kỳ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên học kỳ không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Tên học kỳ phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                subtitle: const Text('Học kỳ có thể sử dụng'),
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
        _isActive,
      );
      Get.back();
    }
  }
}
