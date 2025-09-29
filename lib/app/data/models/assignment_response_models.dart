import 'package:json_annotation/json_annotation.dart';
import 'assignment_model.dart';
import 'submission_model.dart';

part 'assignment_response_models.g.dart';

@JsonSerializable()
class AssignmentResponse {
  final bool success;
  final String? message;
  @JsonKey(readValue: _readAssignment)
  final Assignment data;

  AssignmentResponse({
    required this.success,
    this.message,
    required this.data,
  });

  static Object? _readAssignment(Map json, String key) {
    final root = json['data'];
    if (root is Map) {
      final inner = root['assignment'];
      return (inner is Map) ? inner : root;
    }
    return null;
  }

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentResponseToJson(this);
}

@JsonSerializable()
class AssignmentListResponse {
  final bool success;
  final String? message;
  @JsonKey(readValue: _readAssignments)
  final List<Assignment> data;
  @JsonKey(readValue: _readPagination)
  final PaginationInfo pagination;

  AssignmentListResponse({
    required this.success,
    this.message,
    required this.data,
    required this.pagination,
  });

  static Object? _readAssignments(Map json, String key) {
    final root = json['data'];
    final list = (root is Map) ? root['assignments'] : null;
    return (list is List) ? list : const [];
  }

  static Object? _readPagination(Map json, String key) {
    final root = json['data'];
    final map = (root is Map) ? root['pagination'] : null;
    return (map is Map) ? map : {'page': 1, 'limit': 0, 'total': 0, 'pages': 1};
  }

  factory AssignmentListResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentListResponseToJson(this);
}

@JsonSerializable()
class SubmissionResponse {
  final bool success;
  final String message;
  final AssignmentSubmission data;

  SubmissionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionResponseToJson(this);
}

@JsonSerializable()
class SubmissionListResponse {
  final bool success;
  final String message;
  final List<AssignmentSubmission> data;
  final PaginationInfo pagination;

  SubmissionListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory SubmissionListResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionListResponseToJson(this);
}

@JsonSerializable()
class StudentSubmissionResponse {
  final bool success;
  final String message;
  final Assignment assignment;
  final List<AssignmentSubmission> submissions;
  final int currentAttempts;
  final int remainingAttempts;

  StudentSubmissionResponse({
    required this.success,
    required this.message,
    required this.assignment,
    required this.submissions,
    required this.currentAttempts,
    required this.remainingAttempts,
  });

  factory StudentSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentSubmissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentSubmissionResponseToJson(this);
}

@JsonSerializable()
class SubmissionTrackingResponse {
  final bool success;
  final String message;
  final List<SubmissionTrackingData> data;
  final PaginationInfo pagination;

  SubmissionTrackingResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory SubmissionTrackingResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionTrackingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionTrackingResponseToJson(this);
}

@JsonSerializable()
class AttachmentResponse {
  final bool success;
  final String message;
  final SubmissionAttachment data;

  AttachmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentResponseToJson(this);
}

@JsonSerializable()
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}
