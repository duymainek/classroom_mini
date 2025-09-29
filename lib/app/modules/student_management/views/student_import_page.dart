import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../student_management/controllers/student_management_controller.dart';

class StudentImportPage extends StatefulWidget {
  const StudentImportPage({super.key});

  @override
  State<StudentImportPage> createState() => _StudentImportPageState();
}

class _StudentImportPageState extends State<StudentImportPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _results = [];
  Map<int, Map<String, dynamic>> _rowResultByNumber = {};

  void _removeAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    setState(() {
      _rows.removeAt(index);
    });
  }

  Map<String, int> _computeStats() {
    int ready = 0;
    int errors = 0;
    for (final r in _rows) {
      final original = (r['_rowNumber'] as num?)?.toInt();
      final res = original != null ? _rowResultByNumber[original] : null;
      final status = (res?['status'] ?? '').toString().toUpperCase();
      if (status == 'READY' || status == 'CREATED') {
        ready++;
      } else {
        errors++;
      }
    }
    return {
      'ready': ready,
      'errors': errors,
      'total': _rows.length,
    };
  }

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
        map['username'] = map['username']?.toString().trim();
        map['email'] = map['email']?.toString().trim();
        map['fullName'] = map['fullName']?.toString().trim();
        final isActiveStr = map['isActive']?.toString().toLowerCase();
        map['isActive'] = (isActiveStr == 'true' ||
            isActiveStr == '1' ||
            isActiveStr == 'yes');
        map['_rowNumber'] = i; // track original row number
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
        _rowResultByNumber = {
          for (final r in _results)
            if (r['rowNumber'] != null) (r['rowNumber'] as num).toInt(): r
        };
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Hoàn tất import: thêm ${summary?['created'] ?? 0}, bỏ qua ${summary?['skipped'] ?? 0}'),
    ));
    // ignore: discarded_futures
    controller.refreshStudents();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final maxWidth = isWide ? 960.0 : 720.0;
    final stats = _computeStats();
    final hasError = stats['errors']! > 0 || _rows.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV sinh viên')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Yêu cầu cột: username, email, fullName, isActive'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _pickAndPreview,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Chọn CSV'),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _isLoading || hasError ? null : _confirmImport,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Xác nhận import'),
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_rows.isNotEmpty) ...[
                      Text('Kết quả xem trước',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (isWide)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('username')),
                              DataColumn(label: Text('email')),
                              DataColumn(label: Text('fullName')),
                              DataColumn(label: Text('isActive')),
                              DataColumn(label: Text('Trạng thái')),
                              DataColumn(label: Text('')),
                            ],
                            rows: List<DataRow>.generate(_rows.length, (i) {
                              final r = _rows[i];
                              final original =
                                  (r['_rowNumber'] as num?)?.toInt();
                              final result = original != null
                                  ? _rowResultByNumber[original]
                                  : null;
                              final status =
                                  (result?['status'] ?? '').toString();
                              final upper = status.toUpperCase();
                              final isReady =
                                  upper == 'READY' || upper == 'CREATED';
                              final isError = !isReady;
                              final Color color =
                                  isError ? Colors.red : Colors.green;
                              return DataRow(cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text('${r['username'] ?? ''}')),
                                DataCell(Text('${r['email'] ?? ''}')),
                                DataCell(Text('${r['fullName'] ?? ''}')),
                                DataCell(Text('${r['isActive'] ?? ''}')),
                                DataCell(
                                  Text(isError
                                      ? (status.isEmpty ? 'Lỗi' : status)
                                      : 'Sẵn sàng'),
                                ),
                                DataCell(IconButton(
                                  tooltip: 'Loại bỏ',
                                  onPressed: () => _removeAt(i),
                                  icon: const Icon(Icons.close),
                                )),
                              ]);
                            }),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            final r = _rows[i];
                            final original = (r['_rowNumber'] as num?)?.toInt();
                            final result = original != null
                                ? _rowResultByNumber[original]
                                : null;
                            final status = (result?['status'] ?? '').toString();
                            final upper = status.toUpperCase();
                            final isReady =
                                upper == 'READY' || upper == 'CREATED';
                            final isError = !isReady;
                            final Color color =
                                isError ? Colors.red : Colors.green;
                            final String label = isError
                                ? (status.isEmpty ? 'Lỗi' : status)
                                : 'Sẵn sàng';
                            return Dismissible(
                              key: ValueKey(r['_rowNumber'] ?? i),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.redAccent,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                _removeAt(i);
                              },
                              child: Card(
                                shape: isError
                                    ? RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.redAccent, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(child: Text('${i + 1}')),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('${r['fullName'] ?? ''}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall),
                                                Text('${r['email'] ?? ''}'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                              'username: ${r['username'] ?? ''}'),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.verified_user,
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                              'active: ${r['isActive'] ?? ''}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Spacer(),
                                          Text(label,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: _rows.length,
                        ),
                    ],
                    if (_rows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Tổng kết xem trước',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.add_circle,
                                color: Colors.green),
                            label: Text('Sẵn sàng: ${stats['ready']}'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.error, color: Colors.red),
                            label: Text('Lỗi: ${stats['errors']}'),
                          ),
                          Chip(
                            avatar:
                                const Icon(Icons.summarize, color: Colors.blue),
                            label: Text('Tổng: ${stats['total']}'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
