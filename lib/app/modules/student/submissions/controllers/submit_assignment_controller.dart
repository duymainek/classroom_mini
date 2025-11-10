import 'dart:io';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/data/repositories/student_submission_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubmitAssignmentController extends GetxController {
  final StudentSubmissionRepository _repository;

  SubmitAssignmentController(this._repository);

  // State
  final Rx<Assignment?> assignment = Rx<Assignment?>(null);
  final RxList<AssignmentSubmission> mySubmissions =
      <AssignmentSubmission>[].obs;
  final RxList<File> selectedFiles = <File>[].obs;
  final RxList<String> tempAttachmentIds = <String>[].obs;
  final RxList<String> uploadedFileNames = <String>[].obs;
  final RxString submissionText = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString error = ''.obs;

  // Text controller for submission text
  final TextEditingController submissionTextController =
      TextEditingController();

  // Computed properties
  int get currentAttempts => mySubmissions.length;
  int get maxAttempts => assignment.value?.maxAttempts ?? 1;
  int get remainingAttempts => maxAttempts - currentAttempts;
  bool get canSubmit => remainingAttempts > 0 && !isPastDeadline;

  bool get isPastDeadline {
    if (assignment.value == null) return false;

    final now = DateTime.now();
    final lateDueDate = assignment.value!.lateDueDate;

    // If past late due date, definitely past deadline
    if (lateDueDate != null && now.isAfter(lateDueDate)) {
      return true;
    }

    // If past due date and late submission not allowed
    if (now.isAfter(assignment.value!.dueDate) &&
        !assignment.value!.allowLateSubmission) {
      return true;
    }

    return false;
  }

  bool get isLateSubmission {
    if (assignment.value == null) return false;

    final now = DateTime.now();
    final dueDate = assignment.value!.dueDate;
    final lateDueDate = assignment.value!.lateDueDate;

    // If past due date but before late due date (or no late due date set)
    if (now.isAfter(dueDate)) {
      if (lateDueDate == null || now.isBefore(lateDueDate)) {
        return true;
      }
    }

    return false;
  }

  AssignmentSubmission? get latestSubmission {
    if (mySubmissions.isEmpty) return null;
    return mySubmissions.last;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['assignment'] != null) {
      assignment.value = args['assignment'] as Assignment;
      loadMySubmissions();
    }
  }

  @override
  void onClose() {
    submissionTextController.dispose();
    super.onClose();
  }

  /// Load student's submission history for this assignment
  Future<void> loadMySubmissions() async {
    if (assignment.value == null) return;

    try {
      isLoading.value = true;
      error.value = '';

      final result = await _repository.getMySubmissions(
        assignmentId: assignment.value!.id,
      );

      if (result.success) {
        mySubmissions.value = result.submissions;
      } else {
        error.value = result.message ?? 'Failed to load submissions';
        Get.snackbar(
          'Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick files from device
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files.map((f) => File(f.path!)).toList();

        // Validate files
        final validFiles = <File>[];
        for (final file in files) {
          if (await _validateFile(file)) {
            validFiles.add(file);
          }
        }

        if (validFiles.isNotEmpty) {
          selectedFiles.addAll(validFiles);
          Get.snackbar(
            'Success',
            '${validFiles.length} file(s) selected',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick files: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  /// Validate file against assignment requirements
  Future<bool> _validateFile(File file) async {
    if (assignment.value == null) return false;

    // Get file info
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    final fileSize = await file.length();

    // Check file format
    if (assignment.value!.fileFormats.isNotEmpty &&
        !assignment.value!.fileFormats.contains(fileExtension)) {
      Get.snackbar(
        'Invalid File Format',
        '$fileName: Only ${assignment.value!.fileFormats.join(', ')} files are allowed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return false;
    }

    // Check file size (maxFileSize is in MB)
    final maxSizeBytes = assignment.value!.maxFileSize * 1024 * 1024;
    if (fileSize > maxSizeBytes) {
      Get.snackbar(
        'File Too Large',
        '$fileName: Maximum file size is ${assignment.value!.maxFileSize}MB',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return false;
    }

    return true;
  }

  /// Remove selected file
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
      if (index < tempAttachmentIds.length) {
        tempAttachmentIds.removeAt(index);
      }
      if (index < uploadedFileNames.length) {
        uploadedFileNames.removeAt(index);
      }
    }
  }

  /// Upload files to temp storage
  Future<bool> uploadFiles() async {
    if (selectedFiles.isEmpty) return true;

    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final totalFiles = selectedFiles.length;
      var uploadedCount = 0;

      for (final file in selectedFiles) {
        final result = await _repository.uploadTempFile(file: file);

        if (result.success && result.tempAttachmentId != null) {
          tempAttachmentIds.add(result.tempAttachmentId!);
          uploadedFileNames.add(result.fileName ?? file.path.split('/').last);
          uploadedCount++;
          uploadProgress.value = uploadedCount / totalFiles;
        } else {
          Get.snackbar(
            'Upload Failed',
            'Failed to upload ${file.path.split('/').last}: ${result.message}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload files: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Submit assignment
  Future<void> submit() async {
    if (assignment.value == null) return;

    // Validation
    if (!canSubmit) {
      Get.snackbar(
        'Cannot Submit',
        isPastDeadline ? 'Deadline has passed' : 'Maximum attempts reached',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final text = submissionTextController.text.trim();
    if (text.isEmpty && selectedFiles.isEmpty) {
      Get.snackbar(
        'Empty Submission',
        'Please provide either text or files',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    // Show late submission warning
    if (isLateSubmission) {
      final confirmed = await _showLateSubmissionDialog();
      if (confirmed != true) return;
    }

    try {
      isSubmitting.value = true;

      // Upload files if not already uploaded
      if (selectedFiles.isNotEmpty && tempAttachmentIds.isEmpty) {
        final uploaded = await uploadFiles();
        if (!uploaded) {
          isSubmitting.value = false;
          return;
        }
      }

      // Submit assignment
      final result = await _repository.submitAssignment(
        assignmentId: assignment.value!.id,
        submissionText: text.isEmpty ? null : text,
        tempAttachmentIds: tempAttachmentIds,
      );

      if (result.success) {
        Get.snackbar(
          'Success',
          result.message ?? 'Assignment submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );

        // Clear form
        _clearForm();

        // Reload submissions
        await loadMySubmissions();

        // Navigate back or to detail
        Get.back(result: true);
      } else {
        _handleSubmissionError(result.message, result.errorCode);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit assignment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Update existing submission (only latest, only if not graded)
  Future<void> updateSubmission() async {
    final latest = latestSubmission;
    if (latest == null || latest.isGraded) {
      Get.snackbar(
        'Cannot Update',
        latest?.isGraded == true
            ? 'Cannot update graded submission'
            : 'No submission to update',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    // Check if still within deadline
    if (isPastDeadline) {
      Get.snackbar(
        'Cannot Update',
        'Deadline has passed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final text = submissionTextController.text.trim();

      final result = await _repository.updateSubmission(
        submissionId: latest.id!,
        submissionText: text.isEmpty ? null : text,
        attachments: latest.attachments,
      );

      if (result.success) {
        Get.snackbar(
          'Success',
          'Submission updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );

        // Reload submissions
        await loadMySubmissions();

        Get.back(result: true);
      } else {
        _handleSubmissionError(result.message, result.errorCode);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update submission: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Handle submission error with specific error codes
  void _handleSubmissionError(String? message, String? errorCode) {
    String errorMessage = message ?? 'Failed to submit assignment';

    switch (errorCode) {
      case 'MAX_ATTEMPTS_EXCEEDED':
        errorMessage = 'You have reached the maximum number of attempts';
        break;
      case 'ASSIGNMENT_CLOSED':
      case 'DEADLINE_PASSED':
        errorMessage = 'Assignment deadline has passed';
        break;
      case 'LATE_SUBMISSION_CLOSED':
      case 'LATE_DEADLINE_PASSED':
        errorMessage = 'Late submission deadline has also passed';
        break;
      case 'INVALID_FILE_FORMAT':
        errorMessage = 'One or more files have invalid format';
        break;
      case 'FILE_TOO_LARGE':
        errorMessage = 'One or more files exceed the size limit';
        break;
      case 'EMPTY_SUBMISSION':
        errorMessage = 'Please provide either text or files';
        break;
    }

    Get.snackbar(
      'Submission Failed',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      duration: const Duration(seconds: 5),
    );
  }

  /// Show late submission confirmation dialog
  Future<bool?> _showLateSubmissionDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Late Submission'),
        content: const Text(
          'This assignment is past the due date. Your submission will be marked as late. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Submit Late'),
          ),
        ],
      ),
    );
  }

  /// Clear form data
  void _clearForm() {
    submissionTextController.clear();
    selectedFiles.clear();
    tempAttachmentIds.clear();
    uploadedFileNames.clear();
    submissionText.value = '';
  }

  /// View submission detail
  void viewSubmission(AssignmentSubmission submission) {
    Get.toNamed(
      '/submissions/detail',
      arguments: {
        'submission': submission,
        'assignment': assignment.value,
      },
    );
  }
}
