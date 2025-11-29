import 'dart:io' if (dart.library.html) 'package:classroom_mini/app/shared/controllers/io_stub.dart';
import 'package:classroom_mini/app/data/models/request/assignment_request.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

/// Result class for single submission operations
class SubmissionResult {
  final bool success;
  final String? message;
  final AssignmentSubmission? submission;
  final String? errorCode;

  SubmissionResult({
    required this.success,
    this.message,
    this.submission,
    this.errorCode,
  });

  factory SubmissionResult.success({
    AssignmentSubmission? submission,
    String? message,
  }) {
    return SubmissionResult(
      success: true,
      submission: submission,
      message: message,
    );
  }

  factory SubmissionResult.failure({
    String? message,
    String? errorCode,
  }) {
    return SubmissionResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Result class for temp file upload
class TempFileUploadResult {
  final bool success;
  final String? message;
  final String? tempAttachmentId;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;

  TempFileUploadResult({
    required this.success,
    this.message,
    this.tempAttachmentId,
    this.fileName,
    this.fileUrl,
    this.fileSize,
  });

  factory TempFileUploadResult.success({
    required String tempAttachmentId,
    required String fileName,
    String? fileUrl,
    int? fileSize,
  }) {
    return TempFileUploadResult(
      success: true,
      tempAttachmentId: tempAttachmentId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSize: fileSize,
      message: 'File uploaded successfully',
    );
  }

  factory TempFileUploadResult.failure({
    String? message,
  }) {
    return TempFileUploadResult(
      success: false,
      message: message ?? 'Failed to upload file',
    );
  }
}

/// Result class for submissions list
class SubmissionsListResult {
  final bool success;
  final String? message;
  final List<AssignmentSubmission> submissions;
  final int currentAttempts;
  final int remainingAttempts;
  final Map<String, dynamic>? assignmentInfo;

  SubmissionsListResult({
    required this.success,
    this.message,
    this.submissions = const [],
    this.currentAttempts = 0,
    this.remainingAttempts = 0,
    this.assignmentInfo,
  });

  factory SubmissionsListResult.success({
    required List<AssignmentSubmission> submissions,
    int currentAttempts = 0,
    int remainingAttempts = 0,
    Map<String, dynamic>? assignmentInfo,
  }) {
    return SubmissionsListResult(
      success: true,
      submissions: submissions,
      currentAttempts: currentAttempts,
      remainingAttempts: remainingAttempts,
      assignmentInfo: assignmentInfo,
    );
  }

  factory SubmissionsListResult.failure({
    String? message,
  }) {
    return SubmissionsListResult(
      success: false,
      message: message ?? 'Failed to fetch submissions',
    );
  }
}

/// Repository for student submission operations
class StudentSubmissionRepository {
  final ApiService _apiService;

  StudentSubmissionRepository(this._apiService);

  /// Submit assignment
  Future<SubmissionResult> submitAssignment({
    required String assignmentId,
    String? submissionText,
    List<String> tempAttachmentIds = const [],
  }) async {
    try {
      final request = SubmitAssignmentRequest(
        submissionText: submissionText,
        tempAttachmentIds: tempAttachmentIds,
      );

      final response = await _apiService.submitAssignment(
        assignmentId,
        request,
      );

      if (response.success) {
        return SubmissionResult.success(
          submission: response.data.submission,
          message: response.message,
        );
      } else {
        return SubmissionResult.failure(
          message: response.message,
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      final errorCode = _extractErrorCode(e);

      return SubmissionResult.failure(
        message: message,
        errorCode: errorCode,
      );
    } catch (e) {
      return SubmissionResult.failure(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Get student's submissions for an assignment
  Future<SubmissionsListResult> getMySubmissions({
    required String assignmentId,
  }) async {
    try {
      final response = await _apiService.getStudentSubmissions(assignmentId);

      if (response.success) {
        return SubmissionsListResult.success(
          submissions: response.data.submissions,
        );
      } else {
        return SubmissionsListResult.failure(
          message: 'Failed to fetch submissions',
        );
      }
    } on DioException catch (e) {
      return SubmissionsListResult.failure(
        message: _extractErrorMessage(e),
      );
    } catch (e) {
      return SubmissionsListResult.failure(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Update submission
  Future<SubmissionResult> updateSubmission({
    required String submissionId,
    String? submissionText,
    List<SubmissionAttachment>? attachments,
  }) async {
    try {
      final request = UpdateSubmissionRequest(
        submissionText: submissionText,
        attachments: attachments,
      );

      final response = await _apiService.updateSubmission(
        submissionId,
        request,
      );

      if (response.success) {
        return SubmissionResult.success(
          submission: response.data.submission,
          message: response.message,
        );
      } else {
        return SubmissionResult.failure(
          message: response.message,
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      final errorCode = _extractErrorCode(e);

      return SubmissionResult.failure(
        message: message,
        errorCode: errorCode,
      );
    } catch (e) {
      return SubmissionResult.failure(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Delete submission
  Future<SubmissionResult> deleteSubmission({
    required String submissionId,
  }) async {
    try {
      final response = await _apiService.deleteSubmission(submissionId);

      if (response.success) {
        return SubmissionResult.success(
          message: response.message ?? 'Submission deleted successfully',
        );
      } else {
        return SubmissionResult.failure(
          message: response.message ?? 'Failed to delete submission',
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      final errorCode = _extractErrorCode(e);

      return SubmissionResult.failure(
        message: message,
        errorCode: errorCode,
      );
    } catch (e) {
      return SubmissionResult.failure(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Upload temp file for submission
  Future<TempFileUploadResult> uploadTempFile({
    File? file,
    PlatformFile? platformFile,
  }) async {
    try {
      if (platformFile != null) {
        // Use PlatformFile (web compatible)
        final bytes = platformFile.bytes ?? Uint8List(0);
        final response = await DioClient.uploadSubmissionTempFileFromBytes(
          bytes,
          platformFile.name,
        );
        if (response.success) {
          return TempFileUploadResult.success(
            tempAttachmentId: response.data.attachmentId,
            fileName: response.data.fileName,
            fileUrl: response.data.fileUrl,
            fileSize: response.data.fileSize,
          );
        } else {
          return TempFileUploadResult.failure(
            message: response.message,
          );
        }
      } else if (file != null) {
        // Use File (mobile/desktop)
        final response = await _apiService.uploadSubmissionTempFile(file);

        if (response.success) {
          return TempFileUploadResult.success(
            tempAttachmentId: response.data.attachmentId,
            fileName: response.data.fileName,
            fileUrl: response.data.fileUrl,
            fileSize: response.data.fileSize,
          );
        } else {
          return TempFileUploadResult.failure(
            message: response.message,
          );
        }
      } else {
        return TempFileUploadResult.failure(
          message: 'No file or platformFile provided',
        );
      }
    } on DioException catch (e) {
      return TempFileUploadResult.failure(
        message: _extractErrorMessage(e),
      );
    } catch (e) {
      return TempFileUploadResult.failure(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Extract error message from DioException
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        final data = e.response!.data as Map;
        return data['message'] ?? data['error'] ?? 'An error occurred';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please try again.';
    }
  }

  /// Extract error code from DioException
  String? _extractErrorCode(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      final data = e.response!.data as Map;
      return data['code'] as String?;
    }
    return null;
  }
}
