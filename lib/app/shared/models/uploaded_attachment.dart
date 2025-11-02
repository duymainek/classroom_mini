import 'dart:typed_data';

enum AttachmentUploadStatus {
  pending, // File selected but not uploaded yet
  uploading, // Currently uploading to storage
  uploaded, // Successfully uploaded to storage
  failed // Upload failed
}

class UploadedAttachment {
  final String id; // Unique ID for this attachment
  final String fileName; // Original file name
  final String filePath; // Local file path (may be empty on web)
  final Uint8List? fileBytes; // File bytes (for web platform)
  final int fileSize; // File size in bytes
  final String fileType; // MIME type
  final AttachmentUploadStatus status;
  final String? attachmentId; // Backend attachment ID (after upload)
  final String? fileUrl; // Public URL (after upload)
  final String? errorMessage; // Error message if failed
  final double? uploadProgress; // Upload progress 0.0 - 1.0

  UploadedAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileBytes,
    required this.fileSize,
    required this.fileType,
    required this.status,
    this.attachmentId,
    this.fileUrl,
    this.errorMessage,
    this.uploadProgress,
  });

  UploadedAttachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    Uint8List? fileBytes,
    int? fileSize,
    String? fileType,
    AttachmentUploadStatus? status,
    String? attachmentId,
    String? fileUrl,
    String? errorMessage,
    double? uploadProgress,
  }) {
    return UploadedAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileBytes: fileBytes ?? this.fileBytes,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      status: status ?? this.status,
      attachmentId: attachmentId ?? this.attachmentId,
      fileUrl: fileUrl ?? this.fileUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  bool get isUploaded =>
      status == AttachmentUploadStatus.uploaded && attachmentId != null;
  bool get isUploading => status == AttachmentUploadStatus.uploading;
  bool get hasFailed => status == AttachmentUploadStatus.failed;
  bool get isPending => status == AttachmentUploadStatus.pending;

  @override
  String toString() {
    return 'UploadedAttachment(id: $id, fileName: $fileName, status: $status, attachmentId: $attachmentId, fileUrl: $fileUrl)';
  }
}

