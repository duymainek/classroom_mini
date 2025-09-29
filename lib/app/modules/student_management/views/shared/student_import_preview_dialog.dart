import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../student_management/controllers/student_management_controller.dart';

class StudentImportPreviewDialog extends StatefulWidget {
  const StudentImportPreviewDialog({super.key});

  @override
  State<StudentImportPreviewDialog> createState() =>
      _StudentImportPreviewDialogState();
}

class _StudentImportPreviewDialogState
    extends State<StudentImportPreviewDialog> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _results = [];

  Future<void> _pickAndPreview() async {
    try {
      setState(() => _isLoading = true);
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _isLoading = false);
        return;
      }
      final content = utf8.decode(bytes);
      final csvRows = const CsvToListConverter(eol: '\n').convert(content);
      if (csvRows.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final headers = csvRows.first.map((e) => e.toString()).toList();
      final requiredHeaders = {'username', 'email', 'fullName', 'isActive'};
      final headerSet = headers.map((e) => e.trim()).toSet();
      if (!headerSet.containsAll(requiredHeaders)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'CSV thiếu cột bắt buộc: username, email, fullName, isActive')));
        }
        setState(() => _isLoading = false);
        return;
      }

      final List<Map<String, dynamic>> records = [];
      for (int i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        if (row.isEmpty ||
            row.every((c) => (c?.toString().trim().isEmpty ?? true))) {
          continue;
        }
        final map = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j].toString()] = row[j];
        }
        // Normalize types
        map['username'] = map['username']?.toString().trim();
        map['email'] = map['email']?.toString().trim();
        map['fullName'] = map['fullName']?.toString().trim();
        final isActiveStr = map['isActive']?.toString().toLowerCase();
        map['isActive'] = (isActiveStr == 'true' ||
            isActiveStr == '1' ||
            isActiveStr == 'yes');
        records.add(map);
      }

      final controller = Get.find<StudentManagementController>();
      final detailed = await controller.previewImportDetailed(records);
      if (!mounted) return;
      if (detailed == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Xem trước thất bại')));
        return;
      }
      setState(() {
        _rows = records;
        _summary = (detailed['summary'] as Map<String, dynamic>?) ?? {};
        _results = List<Map<String, dynamic>>.from(detailed['results'] as List);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đọc được tệp CSV')));
    }
  }

  Future<void> _confirmImport() async {
    final controller = Get.find<StudentManagementController>();
    setState(() => _isLoading = true);
    final detailed = await controller.confirmImportDetailed(_rows);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (detailed == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import thất bại')));
      return;
    }
    final summary = detailed['summary'] as Map<String, dynamic>?;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Hoàn tất import: thêm ${summary?['created'] ?? 0}, bỏ qua ${summary?['skipped'] ?? 0}'),
    ));
    // Reload list (fire-and-forget)
    // ignore: discarded_futures
    controller.refreshStudents();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import CSV sinh viên'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yêu cầu cột: username, email, fullName, isActive'),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickAndPreview,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Chọn CSV'),
                ),
                const SizedBox(width: 8),
                if (_rows.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _confirmImport,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Xác nhận import'),
                  ),
                if (_isLoading) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 12),
            if (_results.isNotEmpty) ...[
              Text('Kết quả xem trước',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('username')),
                      DataColumn(label: Text('email')),
                      DataColumn(label: Text('fullName')),
                      DataColumn(label: Text('isActive')),
                      DataColumn(label: Text('Trạng thái')),
                    ],
                    rows: List<DataRow>.generate(_results.length, (i) {
                      final r = _results[i];
                      final status = (r['status'] ?? '').toString();
                      final isNew = status.toLowerCase() == 'new';
                      final exists = status.toLowerCase() == 'exists';
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text('${r['username'] ?? ''}')),
                        DataCell(Text('${r['email'] ?? ''}')),
                        DataCell(Text('${r['fullName'] ?? ''}')),
                        DataCell(Text('${r['isActive'] ?? ''}')),
                        DataCell(Chip(
                          label: Text(isNew
                              ? 'Sẽ thêm'
                              : exists
                                  ? 'Đã tồn tại'
                                  : (status.isEmpty ? 'Không rõ' : status)),
                          backgroundColor: isNew
                              ? Colors.green.withOpacity(0.08)
                              : exists
                                  ? Colors.orange.withOpacity(0.08)
                                  : Colors.grey.withOpacity(0.08),
                          side: BorderSide(
                              color: isNew
                                  ? Colors.green
                                  : exists
                                      ? Colors.orange
                                      : Colors.grey),
                        )),
                      ]);
                    }),
                  ),
                ),
              ),
            ],
            if (_summary != null) ...[
              const SizedBox(height: 12),
              Text('Tổng kết xem trước',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.add_circle, color: Colors.green),
                    label: Text(
                        'Sẽ thêm: ${_summary?['toCreate'] ?? _summary?['created'] ?? 0}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.copy, color: Colors.orange),
                    label: Text(
                        'Đã tồn tại: ${_summary?['existing'] ?? _summary?['skipped'] ?? 0}'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        if (_rows.isNotEmpty)
          FilledButton.icon(
            onPressed: _isLoading ? null : _confirmImport,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Xác nhận import'),
          ),
      ],
    );
  }
}
