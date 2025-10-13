import 'package:classroom_mini/app/modules/assignments/controllers/assignment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../widgets/tracking_statistics.dart';

class AssignmentTrackingPage extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const AssignmentTrackingPage(
      {super.key, required this.assignmentId, required this.assignmentTitle});

  @override
  State<AssignmentTrackingPage> createState() => _AssignmentTrackingPageState();
}

class _AssignmentTrackingPageState extends State<AssignmentTrackingPage> {
  late final AssignmentController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AssignmentController());
    if (widget.assignmentId.isNotEmpty) {
      controller.loadAssignmentSubmissions(widget.assignmentId);
    } else {
      Get.snackbar('Lỗi', 'Thiếu assignmentId để theo dõi');
    }
  }

  Future<void> _exportTracking() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final csvBytes = await controller.exportAssignmentTracking(
        widget.assignmentId,
      );

      // Đóng dialog trước khi xử lý kết quả
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (csvBytes == null || csvBytes.isEmpty) {
        Get.snackbar('Lỗi', 'Không thể xuất dữ liệu');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath =
          '${directory.path}/assignment_tracking_${widget.assignmentId}_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsBytes(csvBytes);

      Get.snackbar(
        'Thành công',
        'Đã xuất file CSV: $filePath',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Đóng dialog nếu có lỗi
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      Get.snackbar('Lỗi', 'Không thể xuất file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignmentTitle.isEmpty
            ? 'Theo dõi nộp bài'
            : widget.assignmentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Xuất CSV',
            onPressed: _exportTracking,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TrackingStatistics(controller: controller),
        ),
      ),
    );
  }
}
