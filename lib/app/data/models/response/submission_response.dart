import 'package:json_annotation/json_annotation.dart';
import 'semester_response.dart';

part 'submission_response.g.dart';

@JsonSerializable()
class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final int attemptNumber;
  final String? submissionText;
  final DateTime submittedAt;
  final bool isLate;
  final double? grade;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubmissionAttachment> attachments;
  final StudentInfo? student;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.attemptNumber,
    this.submissionText,
    required this.submittedAt,
    required this.isLate,
    this.grade,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.student,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentSubmissionToJson(this);

  /// Check if submission is graded
  bool get isGraded => grade != null;

  /// Get submission status
  SubmissionStatus get status {
    if (isGraded) return SubmissionStatus.graded;
    if (isLate) return SubmissionStatus.late;
    return SubmissionStatus.submitted;
  }

  /// Get grade display
  String get gradeDisplay {
    if (grade == null) return 'Chưa chấm';
    return '${grade!.toStringAsFixed(1)}/100';
  }

  /// Get grade color based on score
  String get gradeColor {
    if (grade == null) return 'grey';
    if (grade! >= 80) return 'green';
    if (grade! >= 60) return 'orange';
    return 'red';
  }
}

@JsonSerializable()
class SubmissionAttachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? fileType;
  final DateTime createdAt;

  SubmissionAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    required this.createdAt,
  });

  factory SubmissionAttachment.fromJson(Map<String, dynamic> json) =>
      _$SubmissionAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionAttachmentToJson(this);

  /// Get file size display
  String get fileSizeDisplay {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is image
  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileExtension);
  }

  /// Check if file is document
  bool get isDocument {
    const docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    return docExtensions.contains(fileExtension);
  }
}

@JsonSerializable()
class StudentInfo {
  final String id;
  final String username;
  final String fullName;
  final String email;

  StudentInfo({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) =>
      _$StudentInfoFromJson(json);
  Map<String, dynamic> toJson() => _$StudentInfoToJson(this);
}

@JsonSerializable()
class SubmissionTrackingData {
  final String studentId;
  final String username;
  final String fullName;
  final String email;
  final int totalSubmissions;
  final AssignmentSubmission? latestSubmission;
  final SubmissionStatus status;

  SubmissionTrackingData({
    required this.studentId,
    required this.username,
    required this.fullName,
    required this.email,
    required this.totalSubmissions,
    this.latestSubmission,
    required this.status,
  });

  factory SubmissionTrackingData.fromJson(Map<String, dynamic> json) =>
      _$SubmissionTrackingDataFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionTrackingDataToJson(this);
}

enum SubmissionStatus {
  notSubmitted,
  submitted,
  late,
  graded,
}

extension SubmissionStatusExtension on SubmissionStatus {
  String get displayName {
    switch (this) {
      case SubmissionStatus.notSubmitted:
        return 'Chưa nộp';
      case SubmissionStatus.submitted:
        return 'Đã nộp';
      case SubmissionStatus.late:
        return 'Nộp trễ';
      case SubmissionStatus.graded:
        return 'Đã chấm';
    }
  }

  String get color {
    switch (this) {
      case SubmissionStatus.notSubmitted:
        return 'red';
      case SubmissionStatus.submitted:
        return 'blue';
      case SubmissionStatus.late:
        return 'orange';
      case SubmissionStatus.graded:
        return 'green';
    }
  }

  String get icon {
    switch (this) {
      case SubmissionStatus.notSubmitted:
        return 'close_circle';
      case SubmissionStatus.submitted:
        return 'check_circle';
      case SubmissionStatus.late:
        return 'schedule';
      case SubmissionStatus.graded:
        return 'grade';
    }
  }
}

@JsonSerializable()
class SubmissionData {
  final AssignmentSubmission submission;

  const SubmissionData({
    required this.submission,
  });

  factory SubmissionData.fromJson(Map<String, dynamic> json) =>
      _$SubmissionDataFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionDataToJson(this);
}

@JsonSerializable()
class SubmissionResponse {
  final bool success;
  final String? message;
  final SubmissionData data;

  const SubmissionResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionResponseToJson(this);
}

@JsonSerializable()
class StudentSubmissionData {
  final List<AssignmentSubmission> submissions;

  const StudentSubmissionData({
    required this.submissions,
  });

  factory StudentSubmissionData.fromJson(Map<String, dynamic> json) =>
      _$StudentSubmissionDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentSubmissionDataToJson(this);
}

@JsonSerializable()
class StudentSubmissionResponse {
  final bool success;
  final StudentSubmissionData data;

  const StudentSubmissionResponse({
    required this.success,
    required this.data,
  });

  factory StudentSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentSubmissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentSubmissionResponseToJson(this);
}

@JsonSerializable()
class SubmissionListData {
  final List<AssignmentSubmission> submissions;
  final PaginationInfo pagination;

  const SubmissionListData({
    required this.submissions,
    required this.pagination,
  });

  factory SubmissionListData.fromJson(Map<String, dynamic> json) =>
      _$SubmissionListDataFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionListDataToJson(this);
}

@JsonSerializable()
class SubmissionListResponse {
  final bool success;
  final SubmissionListData data;

  const SubmissionListResponse({
    required this.success,
    required this.data,
  });

  factory SubmissionListResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionListResponseToJson(this);
}

@JsonSerializable()
class SubmissionTrackingList {
  final List<SubmissionTrackingData> submissions;
  final PaginationInfo pagination;

  const SubmissionTrackingList({
    required this.submissions,
    required this.pagination,
  });

  factory SubmissionTrackingList.fromJson(Map<String, dynamic> json) =>
      _$SubmissionTrackingListFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionTrackingListToJson(this);
}

@JsonSerializable()
class SubmissionTrackingResponse {
  final bool success;
  final SubmissionTrackingList data;

  const SubmissionTrackingResponse({
    required this.success,
    required this.data,
  });

  factory SubmissionTrackingResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionTrackingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionTrackingResponseToJson(this);
}

@JsonSerializable()
class AttachmentData {
  final SubmissionAttachment attachment;

  const AttachmentData({
    required this.attachment,
  });

  factory AttachmentData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentDataFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentDataToJson(this);
}

@JsonSerializable()
class AttachmentResponse {
  final bool success;
  final String? message;
  final AttachmentData data;

  const AttachmentResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentResponseToJson(this);
}
