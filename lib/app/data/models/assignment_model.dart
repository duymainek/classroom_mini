import 'package:json_annotation/json_annotation.dart';

part 'assignment_model.g.dart';

@JsonSerializable()
class Assignment {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'course_id')
  final String courseId;
  @JsonKey(name: 'instructor_id')
  final String instructorId;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @JsonKey(name: 'late_due_date')
  final DateTime? lateDueDate;
  @JsonKey(name: 'allow_late_submission')
  final bool allowLateSubmission;
  @JsonKey(name: 'max_attempts')
  final int maxAttempts;
  @JsonKey(name: 'file_formats')
  final List<String> fileFormats;
  @JsonKey(name: 'max_file_size')
  final int maxFileSize;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'courses')
  final CourseInfo? course;
  @JsonKey(name: 'users')
  final InstructorInfo? instructor;
  final List<AssignmentAttachment> attachments;
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

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);
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
  @JsonKey(name: 'created_at')
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
  Map<String, dynamic> toJson() => _$AssignmentAttachmentToJson(this);
}

@JsonSerializable()
class CourseInfo {
  final String? id;
  final String code;
  final String name;

  CourseInfo({
    this.id,
    required this.code,
    required this.name,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseInfoToJson(this);
}

@JsonSerializable()
class InstructorInfo {
  final String? id;
  @JsonKey(name: 'full_name')
  final String fullName;

  InstructorInfo({
    required this.id,
    required this.fullName,
  });

  factory InstructorInfo.fromJson(Map<String, dynamic> json) =>
      _$InstructorInfoFromJson(json);
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
