import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assignment_request.g.dart';

@JsonSerializable()
class AssignmentCreateRequest {
  final String title;
  final String? description;
  final String courseId;
  final String semesterId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final List<String> fileFormats;
  final int maxFileSize;
  @JsonKey(includeIfNull: false)
  final List<String>? groupIds;
  @JsonKey(includeIfNull: false)
  final List<SubmissionAttachment>? attachments;

  AssignmentCreateRequest({
    required this.title,
    this.description,
    required this.courseId,
    required this.semesterId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    required this.fileFormats,
    required this.maxFileSize,
    this.groupIds,
    this.attachments,
  });

  factory AssignmentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignmentCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentCreateRequestToJson(this);
}

@JsonSerializable()
class AssignmentUpdateRequest {
  final String id;
  final String? title;
  final String? description;
  final String? courseId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? lateDueDate;
  final bool? allowLateSubmission;
  final int? maxAttempts;
  final List<String>? fileFormats;
  final int? maxFileSize;
  final bool? isActive;
  @JsonKey(includeIfNull: false)
  final List<String>? groupIds;
  @JsonKey(includeIfNull: false)
  final List<SubmissionAttachment>? attachments;

  AssignmentUpdateRequest({
    required this.id,
    this.title,
    this.description,
    this.courseId,
    this.startDate,
    this.dueDate,
    this.lateDueDate,
    this.allowLateSubmission,
    this.maxAttempts,
    this.fileFormats,
    this.maxFileSize,
    this.isActive,
    this.groupIds,
    this.attachments,
  });

  factory AssignmentUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignmentUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentUpdateRequestToJson(this);
}

@JsonSerializable()
class SubmitAssignmentRequest {
  final String? submissionText;
  final List<SubmissionAttachment>? attachments;

  SubmitAssignmentRequest({
    this.submissionText,
    this.attachments,
  });

  factory SubmitAssignmentRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitAssignmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SubmitAssignmentRequestToJson(this);
}

@JsonSerializable()
class UpdateSubmissionRequest {
  final String? submissionText;
  final List<SubmissionAttachment>? attachments;

  UpdateSubmissionRequest({
    this.submissionText,
    this.attachments,
  });

  factory UpdateSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSubmissionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateSubmissionRequestToJson(this);
}

@JsonSerializable()
class GradeSubmissionRequest {
  final double grade;
  final String? feedback;

  GradeSubmissionRequest({
    required this.grade,
    this.feedback,
  });

  factory GradeSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      _$GradeSubmissionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GradeSubmissionRequestToJson(this);
}

@JsonSerializable()
class FileUploadRequest {
  final String filePath;
  final String fileName;
  final String fileType;

  FileUploadRequest({
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  factory FileUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$FileUploadRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FileUploadRequestToJson(this);
}
