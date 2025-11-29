import 'package:json_annotation/json_annotation.dart';
import 'semester_response.dart';

part 'submission_response.g.dart';

@JsonSerializable()
class AssignmentSubmission {
  final String? id;
  final String? assignmentId;
  final String? studentId;
  final int? attemptNumber;
  final String? submissionText;
  final DateTime? submittedAt;
  final bool? isLate;
  final double? grade;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SubmissionAttachment> attachments;
  final StudentInfo? student;

  AssignmentSubmission({
    required this.id,
    this.assignmentId,
    this.studentId,
    required this.attemptNumber,
    this.submissionText,
    this.submittedAt,
    this.isLate,
    this.grade,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
    this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.student,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case and camelCase formats
    final normalizedJson = <String, dynamic>{};

    // Copy all existing keys
    json.forEach((key, value) {
      normalizedJson[key] = value;
    });

    // Map snake_case to camelCase if needed
    if (json.containsKey('assignment_id') &&
        !json.containsKey('assignmentId')) {
      normalizedJson['assignmentId'] = json['assignment_id'];
    }
    if (json.containsKey('student_id') && !json.containsKey('studentId')) {
      normalizedJson['studentId'] = json['student_id'];
    }
    if (json.containsKey('attempt_number') &&
        !json.containsKey('attemptNumber')) {
      normalizedJson['attemptNumber'] = json['attempt_number'];
    }
    if (json.containsKey('submission_text') &&
        !json.containsKey('submissionText')) {
      normalizedJson['submissionText'] = json['submission_text'];
    }
    if (json.containsKey('submitted_at') && !json.containsKey('submittedAt')) {
      normalizedJson['submittedAt'] = json['submitted_at'];
    }
    if (json.containsKey('is_late') && !json.containsKey('isLate')) {
      normalizedJson['isLate'] = json['is_late'];
    }
    if (json.containsKey('graded_at') && !json.containsKey('gradedAt')) {
      normalizedJson['gradedAt'] = json['graded_at'];
    }
    if (json.containsKey('graded_by') && !json.containsKey('gradedBy')) {
      normalizedJson['gradedBy'] = json['graded_by'];
    }
    if (json.containsKey('created_at') && !json.containsKey('createdAt')) {
      normalizedJson['createdAt'] = json['created_at'];
    }
    if (json.containsKey('updated_at') && !json.containsKey('updatedAt')) {
      normalizedJson['updatedAt'] = json['updated_at'];
    }

    // Handle attachments with different field names
    if (json.containsKey('submission_attachments') &&
        !json.containsKey('attachments')) {
      normalizedJson['attachments'] = json['submission_attachments'];
    } else if (json.containsKey('submissionAttachments') &&
        !json.containsKey('attachments')) {
      normalizedJson['attachments'] = json['submissionAttachments'];
    }

    return _$AssignmentSubmissionFromJson(normalizedJson);
  }
  @override
  Map<String, dynamic> toJson() => _$AssignmentSubmissionToJson(this);

  /// Check if submission is graded
  bool get isGraded => grade != null;

  /// Get submission status
  SubmissionStatus get status {
    if (isGraded) return SubmissionStatus.graded;
    if (isLate == true) return SubmissionStatus.late;
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
  final DateTime? createdAt;

  SubmissionAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    this.createdAt,
  });

  factory SubmissionAttachment.fromJson(Map<String, dynamic> json) =>
      _$SubmissionAttachmentFromJson(json);
  @override
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
  @override
  Map<String, dynamic> toJson() => _$StudentInfoToJson(this);
}

@JsonSerializable()
class SubmissionTrackingData {
  final String studentId;
  final String username;
  final String fullName;
  final String email;
  final String? groupId;
  final String? groupName;
  final int totalSubmissions;
  final int gradedSubmissions;
  final int lateSubmissions;
  final double? averageGrade;
  final AssignmentSubmission? latestSubmission;
  @JsonKey(unknownEnumValue: SubmissionStatus.notSubmitted)
  final SubmissionStatus status;
  final bool hasMultipleAttempts;

  SubmissionTrackingData({
    required this.studentId,
    required this.username,
    required this.fullName,
    required this.email,
    this.groupId,
    this.groupName,
    required this.totalSubmissions,
    required this.gradedSubmissions,
    required this.lateSubmissions,
    this.averageGrade,
    this.latestSubmission,
    required this.status,
    required this.hasMultipleAttempts,
  });

  // Custom JSON mapping to accept snake_case status from API without codegen
  factory SubmissionTrackingData.fromJson(Map<String, dynamic> json) {
    return SubmissionTrackingData(
      studentId: json['studentId'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      totalSubmissions: (json['totalSubmissions'] as num? ?? 0).toInt(),
      gradedSubmissions: (json['gradedSubmissions'] as num? ?? 0).toInt(),
      lateSubmissions: (json['lateSubmissions'] as num? ?? 0).toInt(),
      averageGrade: (json['averageGrade'] as num?)?.toDouble(),
      latestSubmission: json['latestSubmission'] == null
          ? null
          : AssignmentSubmission.fromJson(
              json['latestSubmission'] as Map<String, dynamic>,
            ),
      status: _parseSubmissionStatus(json['status']),
      hasMultipleAttempts: json['hasMultipleAttempts'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'username': username,
        'fullName': fullName,
        'email': email,
        'groupId': groupId,
        'groupName': groupName,
        'totalSubmissions': totalSubmissions,
        'gradedSubmissions': gradedSubmissions,
        'lateSubmissions': lateSubmissions,
        'averageGrade': averageGrade,
        'latestSubmission': latestSubmission?.toJson(),
        'status': _submissionStatusToString(status),
        'hasMultipleAttempts': hasMultipleAttempts,
      };
}

enum SubmissionStatus {
  @JsonValue('not_submitted')
  notSubmitted,
  @JsonValue('submitted')
  submitted,
  @JsonValue('late')
  late,
  @JsonValue('graded')
  graded,
}

// Helpers for mapping status values
SubmissionStatus _parseSubmissionStatus(dynamic raw) {
  if (raw is String) {
    switch (raw) {
      case 'not_submitted':
        return SubmissionStatus.notSubmitted;
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'late':
        return SubmissionStatus.late;
      case 'graded':
        return SubmissionStatus.graded;
      default:
        // Fallback for typos like "not_submited"
        final normalized = raw.replaceAll('-', '_');
        if (normalized.contains('not') && normalized.contains('submit')) {
          return SubmissionStatus.notSubmitted;
        }
        return SubmissionStatus.notSubmitted;
    }
  }
  return SubmissionStatus.notSubmitted;
}

String _submissionStatusToString(SubmissionStatus status) {
  switch (status) {
    case SubmissionStatus.notSubmitted:
      return 'not_submitted';
    case SubmissionStatus.submitted:
      return 'submitted';
    case SubmissionStatus.late:
      return 'late';
    case SubmissionStatus.graded:
      return 'graded';
  }
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
  Map<String, dynamic> toJson() => _$AttachmentResponseToJson(this);
}
