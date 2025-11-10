import 'package:json_annotation/json_annotation.dart';
import 'semester_response.dart';

part 'assignment_response.g.dart';

@JsonSerializable()
class Assignment {
  final String id;
  final String title;
  final String? description;
  final String courseId;
  final String instructorId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final List<String> fileFormats;
  final int maxFileSize;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseInfo? course;
  final InstructorInfo? instructor;
  @JsonKey(name: 'assignmentAttachments')
  final List<AssignmentAttachment> attachments;
  @JsonKey(readValue: _readGroups)
  final List<GroupInfo> groups;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.instructorId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    required this.fileFormats,
    required this.maxFileSize,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.course,
    this.instructor,
    this.attachments = const [],
    this.groups = const [],
  });

  static Object? _readGroups(Map json, String key) {
    final groups = json['assignment_groups'] as List<dynamic>?;
    if (groups == null) return <Map<String, dynamic>>[];

    return groups.map((item) {
      if (item is Map<String, dynamic> && item.containsKey('groups')) {
        return item['groups'] as Map<String, dynamic>;
      }
      return item as Map<String, dynamic>;
    }).toList();
  }

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentToJson(this);

  /// Check if assignment is currently open for submission
  bool get isOpenForSubmission {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(dueDate);
  }

  /// Check if assignment is open for late submission
  bool get isOpenForLateSubmission {
    if (!allowLateSubmission || lateDueDate == null) return false;
    final now = DateTime.now();
    return isActive && now.isAfter(dueDate) && now.isBefore(lateDueDate!);
  }

  /// Check if assignment is closed
  bool get isClosed {
    final now = DateTime.now();
    if (lateDueDate != null) {
      return now.isAfter(lateDueDate!);
    }
    return now.isAfter(dueDate);
  }

  /// Get assignment status
  AssignmentStatus get status {
    final now = DateTime.now();
    if (!isActive) return AssignmentStatus.inactive;
    if (now.isBefore(startDate)) return AssignmentStatus.upcoming;
    if (now.isAfter(dueDate)) {
      if (allowLateSubmission &&
          lateDueDate != null &&
          now.isBefore(lateDueDate!)) {
        return AssignmentStatus.lateSubmission;
      }
      return AssignmentStatus.closed;
    }
    return AssignmentStatus.open;
  }

  /// Get time remaining until due date
  Duration? get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(dueDate)) {
      if (allowLateSubmission &&
          lateDueDate != null &&
          now.isBefore(lateDueDate!)) {
        return lateDueDate!.difference(now);
      }
      return null;
    }
    return dueDate.difference(now);
  }
}

@JsonSerializable()
class AssignmentAttachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? fileType;
  final DateTime createdAt;

  AssignmentAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    required this.createdAt,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentAttachmentFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentAttachmentToJson(this);
}

@JsonSerializable()
class CourseInfo {
  final String? id;
  final String code;
  final String name;
  final String? semesterId;

  CourseInfo({
    this.id,
    required this.code,
    required this.name,
    this.semesterId,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseInfoFromJson(json);
@override
  Map<String, dynamic> toJson() => _$CourseInfoToJson(this);
}

@JsonSerializable()
class InstructorInfo {
  final String? id;
  final String fullName;

  InstructorInfo({
    this.id,
    required this.fullName,
  });

  factory InstructorInfo.fromJson(Map<String, dynamic> json) =>
      _$InstructorInfoFromJson(json);
@override
  Map<String, dynamic> toJson() => _$InstructorInfoToJson(this);
}

@JsonSerializable()
class GroupInfo {
  final String id;
  final String name;

  GroupInfo({
    required this.id,
    required this.name,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
@override
  Map<String, dynamic> toJson() => _$GroupInfoToJson(this);
}

enum AssignmentStatus {
  upcoming,
  open,
  lateSubmission,
  closed,
  inactive,
}

extension AssignmentStatusExtension on AssignmentStatus {
  String get displayName {
    switch (this) {
      case AssignmentStatus.upcoming:
        return 'Sắp mở';
      case AssignmentStatus.open:
        return 'Đang mở';
      case AssignmentStatus.lateSubmission:
        return 'Nộp trễ';
      case AssignmentStatus.closed:
        return 'Đã đóng';
      case AssignmentStatus.inactive:
        return 'Không hoạt động';
    }
  }

  String get color {
    switch (this) {
      case AssignmentStatus.upcoming:
        return 'blue';
      case AssignmentStatus.open:
        return 'green';
      case AssignmentStatus.lateSubmission:
        return 'orange';
      case AssignmentStatus.closed:
        return 'red';
      case AssignmentStatus.inactive:
        return 'grey';
    }
  }
}

@JsonSerializable()
class AssignmentListData {
  final List<Assignment> assignments;
  final PaginationInfo pagination;

  const AssignmentListData({
    required this.assignments,
    required this.pagination,
  });

  factory AssignmentListData.fromJson(Map<String, dynamic> json) =>
      _$AssignmentListDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentListDataToJson(this);
}

@JsonSerializable()
class AssignmentListResponse {
  final bool success;
  final AssignmentListData data;

  const AssignmentListResponse({
    required this.success,
    required this.data,
  });

  factory AssignmentListResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentListResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentListResponseToJson(this);
}

@JsonSerializable()
class AssignmentData {
  final Assignment assignment;

  const AssignmentData({
    required this.assignment,
  });

  factory AssignmentData.fromJson(Map<String, dynamic> json) =>
      _$AssignmentDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentDataToJson(this);
}

@JsonSerializable()
class AssignmentResponse {
  final bool success;
  final String? message;
  final AssignmentData data;

  const AssignmentResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AssignmentResponseToJson(this);
}
