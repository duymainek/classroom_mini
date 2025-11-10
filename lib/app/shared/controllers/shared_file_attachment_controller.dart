import 'package:get/get.dart';
import 'package:classroom_mini/app/shared/models/uploaded_attachment.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;

/**
 * Shared File Attachment Controller
 * Configurable controller for handling file uploads across different modules
 */
class SharedFileAttachmentController extends GetxController {
  final RxList<UploadedAttachment> attachments = <UploadedAttachment>[].obs;
  final ApiService _apiService = ApiService(DioClient.dio);

  // Configuration for different modules
  late String _uploadEndpoint;
  late String _finalizeEndpoint;
  late String _deleteEndpoint;
  late String _getEndpoint;

  // Callback để trả attachment info về view cha
  Function(SubmissionAttachment)? onAttachmentUploaded;
  Function(String)? onAttachmentFailed;

  static const Map<String, List<String>> supportedExtensions = {
    'documents': ['pdf', 'docx', 'doc', 'pptx', 'ppt', 'xlsx', 'xls', 'txt'],
    'images': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    'archives': ['zip', 'rar'],
    'videos': ['mp4', 'mov', 'avi'],
    'code': ['py', 'c', 'cpp', 'java', 'js', 'ts', 'html', 'css', 'json'],
    'spreadsheets': ['csv', 'xls', 'xlsx'],
  };

  /// Configure API endpoints for different modules
  void configureEndpoints({
    required String uploadEndpoint,
    required String finalizeEndpoint,
    required String deleteEndpoint,
    required String getEndpoint,
  }) {
    _uploadEndpoint = uploadEndpoint;
    _finalizeEndpoint = finalizeEndpoint;
    _deleteEndpoint = deleteEndpoint;
    _getEndpoint = getEndpoint;
  }

  bool canAddMoreFiles(int maxFiles) => attachments.length < maxFiles;

  List<String> getAllowedExtensions([List<String>? allowed]) {
    if (allowed != null && allowed.isNotEmpty) return allowed;
    return supportedExtensions.values.expand((e) => e).toList();
  }

  bool isValidExtension(String ext, [List<String>? allowed]) {
    final exts = getAllowedExtensions(allowed);
    return exts.contains(ext.toLowerCase());
  }

  Future<void> pickFiles({
    required int maxFiles,
    required int maxFileSizeMB,
    List<String>? allowedExtensions,
  }) async {
    if (!canAddMoreFiles(maxFiles)) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: getAllowedExtensions(allowedExtensions),
    );
    if (result != null && result.files.isNotEmpty) {
      final newAttachments = <UploadedAttachment>[];
      for (final file in result.files) {
        final fileSize = file.size;
        if (fileSize > maxFileSizeMB * 1024 * 1024) continue;
        final ext = _getFileExtension(file.name);
        if (!isValidExtension(ext, allowedExtensions)) continue;
        if (attachments.length + newAttachments.length >= maxFiles) break;
        final attachment = UploadedAttachment(
          id: '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}',
          fileName: file.name,
          filePath: file.path ?? '',
          fileBytes: file.bytes,
          fileSize: fileSize,
          fileType: getMimeTypeFromExtension(ext),
          status: AttachmentUploadStatus.pending,
        );
        newAttachments.add(attachment);
      }
      if (newAttachments.isNotEmpty) {
        attachments.addAll(newAttachments);
        for (final att in newAttachments) {
          startUpload(att);
        }
      }
    }
  }

  Future<void> startUpload(UploadedAttachment attachment) async {
    try {
      _updateAttachment(
          attachment.copyWith(status: AttachmentUploadStatus.uploading));

      // Tạo File từ filePath
      final file = File(attachment.filePath);

      // Gọi API upload dựa trên configured endpoint
      final response = await _uploadFile(file);

      if (response['success'] == true) {
        final data = response['data'];
        // Upload thành công - tạo SubmissionAttachment
        final submissionAttachment = SubmissionAttachment(
          id: data['attachmentId'],
          fileName: data['fileName'],
          fileUrl: data['fileUrl'],
          fileSize: data['fileSize'],
          fileType: data['fileType'],
          createdAt: DateTime.now(),
        );

        // Cập nhật attachment với thông tin từ server
        _updateAttachment(attachment.copyWith(
          status: AttachmentUploadStatus.uploaded,
          attachmentId: submissionAttachment.id,
          fileUrl: submissionAttachment.fileUrl,
          uploadProgress: 1.0,
        ));

        // Gọi callback để thông báo cho view cha
        onAttachmentUploaded?.call(submissionAttachment);
      } else {
        // Upload thất bại
        const errorMsg = 'Không thể tải file lên server';
        _updateAttachment(attachment.copyWith(
          status: AttachmentUploadStatus.failed,
          errorMessage: errorMsg,
        ));
        onAttachmentFailed?.call(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Lỗi tải lên: $e';
      _updateAttachment(attachment.copyWith(
        status: AttachmentUploadStatus.failed,
        errorMessage: errorMsg,
      ));
      onAttachmentFailed?.call(errorMsg);
    }
  }

  /// Upload file using configured endpoint
  Future<Map<String, dynamic>> _uploadFile(File file) async {
    try {
      // Sử dụng ApiService methods dựa trên endpoint
      if (_uploadEndpoint.contains('assignments')) {
        final response = await _apiService.uploadTempAttachment(file);
        return {
          'success': true,
          'data': {
            'attachmentId': response.data.attachmentId,
            'fileName': response.data.fileName,
            'fileUrl': response.data.fileUrl,
            'fileSize': response.data.fileSize,
            'fileType': response.data.fileType,
          }
        };
      } else if (_uploadEndpoint.contains('announcements')) {
        final response =
            await _apiService.uploadTempAnnouncementAttachment(file);
        return {
          'success': true,
          'data': {
            'attachmentId': response.data.attachmentId,
            'fileName': response.data.fileName,
            'fileUrl': response.data.fileUrl,
            'fileSize': response.data.fileSize,
            'fileType': response.data.fileType,
          }
        };
      } else if (_uploadEndpoint.contains('materials')) {
        final response = await _apiService.uploadTempMaterialAttachment(file);
        return {
          'success': true,
          'data': {
            'attachmentId': response.data.attachmentId,
            'fileName': response.data.fileName,
            'fileUrl': response.data.fileUrl,
            'fileSize': response.data.fileSize,
            'fileType': response.data.fileType,
          }
        };
      } else if (_uploadEndpoint.contains('forum')) {
        // Forum upload uses direct multipart upload
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        });

        final response = await DioClient.dio.post(
          _uploadEndpoint,
          data: formData,
          options: dio.Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        if (response.statusCode == 201 && response.data['success'] == true) {
          final data = response.data['data'];
          return {
            'success': true,
            'data': {
              'attachmentId': data['id']?.toString() ?? '',
              'fileName': data['file_name']?.toString() ?? '',
              'fileUrl': data['file_url']?.toString() ?? '',
              'fileSize': data['file_size']?.toInt() ?? 0,
              'fileType': data['file_type']?.toString() ?? '',
            }
          };
        } else {
          throw Exception('Upload failed: ${response.data['message']}');
        }
      } else {
        throw Exception('Unsupported upload endpoint: $_uploadEndpoint');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Configure for assignment attachments
  void configureForAssignment() {
    configureEndpoints(
      uploadEndpoint: '/assignments/temp-attachments',
      finalizeEndpoint: '/assignments/:id/attachments/finalize',
      deleteEndpoint: '/assignments/attachments/:attachmentId',
      getEndpoint: '/assignments/:id/attachments',
    );
  }

  /// Configure for announcement attachments
  void configureForAnnouncement() {
    configureEndpoints(
      uploadEndpoint: '/announcements/temp-attachments',
      finalizeEndpoint: '/announcements/:id/attachments/finalize',
      deleteEndpoint: '/announcements/attachments/:attachmentId',
      getEndpoint: '/announcements/:id/attachments',
    );
  }

  /// Configure for material attachments
  void configureForMaterial() {
    configureEndpoints(
      uploadEndpoint: '/materials/temp-attachments',
      finalizeEndpoint: '/materials/:id/attachments/finalize',
      deleteEndpoint: '/materials/attachments/:attachmentId',
      getEndpoint: '/materials/:id/attachments',
    );
  }

  /// Configure for forum attachments
  void configureForForum() {
    configureEndpoints(
      uploadEndpoint: '/forum/attachments/upload',
      finalizeEndpoint: '/api/forum/topics/:id/attachments/finalize',
      deleteEndpoint: '/api/forum/attachments/:attachmentId',
      getEndpoint: '/api/forum/topics/:id/attachments',
    );
  }

  /// Finalize attachments using ApiService
  Future<void> finalizeAttachments(
      String entityId, List<String> attachmentIds) async {
    try {
      if (_finalizeEndpoint.contains('assignments')) {
        await _apiService.finalizeAssignmentAttachments(entityId, {
          'attachmentIds': attachmentIds,
        });
      } else if (_finalizeEndpoint.contains('announcements')) {
        await _apiService.finalizeAnnouncementAttachments(entityId, {
          'attachmentIds': attachmentIds,
        });
      } else if (_finalizeEndpoint.contains('materials')) {
        await _apiService.finalizeMaterialAttachments(entityId, {
          'tempAttachmentIds': attachmentIds,
        });
      }
    } catch (e) {
      throw Exception('Failed to finalize attachments: $e');
    }
  }

  /// Get attachments using ApiService
  Future<List<Map<String, dynamic>>> getAttachments(String entityId) async {
    try {
      if (_getEndpoint.contains('assignments')) {
        final response =
            await _apiService.getAssignmentAttachmentsById(entityId);
        return response.data.attachments
            .map((att) => {
                  'id': att.id,
                  'fileName': att.fileName,
                  'fileUrl': att.fileUrl,
                  'fileSize': att.fileSize,
                  'fileType': att.fileType,
                })
            .toList();
      } else if (_getEndpoint.contains('announcements')) {
        final response = await _apiService.getAnnouncementAttachments(entityId);
        return response.data.attachments
            .map((att) => {
                  'id': att.id,
                  'fileName': att.fileName,
                  'fileUrl': att.fileUrl,
                  'fileSize': att.fileSize,
                  'fileType': att.fileType,
                })
            .toList();
      } else if (_getEndpoint.contains('materials')) {
        final response = await _apiService.getMaterialAttachments(entityId);
        return response.data.attachments
            .map((att) => {
                  'id': att.id,
                  'fileName': att.fileName,
                  'fileUrl': att.fileUrl,
                  'fileSize': att.fileSize,
                  'fileType': att.fileType,
                })
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get attachments: $e');
    }
  }

  /// Delete attachment using ApiService
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      if (_deleteEndpoint.contains('assignments')) {
        await _apiService.deleteAssignmentAttachmentById(attachmentId);
      } else if (_deleteEndpoint.contains('announcements')) {
        await _apiService.deleteAnnouncementAttachment(attachmentId);
      } else if (_deleteEndpoint.contains('materials')) {
        await _apiService.deleteMaterialAttachment(attachmentId);
      }
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  void removeAttachment(UploadedAttachment attachment) {
    attachments.removeWhere((a) => a.id == attachment.id);
  }

  /// Set callback khi attachment upload thành công
  void setOnAttachmentUploaded(Function(SubmissionAttachment) callback) {
    onAttachmentUploaded = callback;
  }

  /// Set callback khi attachment upload thất bại
  void setOnAttachmentFailed(Function(String) callback) {
    onAttachmentFailed = callback;
  }

  /// Lấy danh sách attachment đã upload thành công
  List<SubmissionAttachment> getUploadedAttachments() {
    return attachments
        .where((att) => att.isUploaded && att.attachmentId != null)
        .map((att) => SubmissionAttachment(
              id: att.attachmentId!,
              fileName: att.fileName,
              fileUrl: att.fileUrl!,
              fileSize: att.fileSize,
              fileType: att.fileType,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  /// Clear tất cả attachments
  void clearAttachments() {
    attachments.clear();
  }

  Future<void> retryUpload(UploadedAttachment attachment) async {
    final retryAttachment = attachment.copyWith(
      status: AttachmentUploadStatus.pending,
      uploadProgress: 0.0,
      errorMessage: null,
    );
    _updateAttachment(retryAttachment);
    await startUpload(retryAttachment);
  }

  void _updateAttachment(UploadedAttachment updated) {
    final idx = attachments.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      attachments[idx] = updated;
      attachments.refresh();
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'py':
        return 'text/x-python';
      case 'c':
        return 'text/x-c';
      case 'cpp':
        return 'text/x-c++';
      case 'java':
        return 'text/x-java';
      case 'js':
        return 'application/javascript';
      case 'ts':
        return 'application/typescript';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  String getCategoryFromMimeType(String mimeType) {
    if (mimeType.startsWith('application/pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('presentation') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType == 'text/plain') {
      return 'documents';
    } else if (mimeType.startsWith('image/')) {
      return 'images';
    } else if (mimeType.startsWith('video/')) {
      return 'videos';
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return 'archives';
    } else if (mimeType.startsWith('text/') ||
        mimeType.contains('javascript') ||
        mimeType.contains('typescript') ||
        mimeType == 'application/json') {
      return 'code';
    } else if (mimeType == 'text/csv' ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('excel')) {
      return 'spreadsheets';
    }
    return 'other';
  }

  IconData getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'documents':
        return Icons.description;
      case 'images':
        return Icons.image;
      case 'archives':
        return Icons.archive;
      case 'videos':
        return Icons.video_file;
      case 'code':
        return Icons.code;
      case 'spreadsheets':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color getFileTypeColor(String fileType) {
    switch (fileType) {
      case 'documents':
        return Colors.blue;
      case 'images':
        return Colors.green;
      case 'archives':
        return Colors.orange;
      case 'videos':
        return Colors.purple;
      case 'code':
        return Colors.teal;
      case 'spreadsheets':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
