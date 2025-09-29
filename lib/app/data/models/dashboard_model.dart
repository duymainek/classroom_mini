import 'package:classroom_mini/app/data/models/course_model.dart';
import 'package:classroom_mini/app/data/models/group_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'semester_model.dart';

part 'dashboard_model.g.dart';

@JsonSerializable()
class DashboardStats {
  @JsonKey(name: 'totalCourses', defaultValue: 0)
  final int totalCourses;
  @JsonKey(name: 'totalGroups', defaultValue: 0)
  final int totalGroups;
  @JsonKey(name: 'totalStudents', defaultValue: 0)
  final int totalStudents;
  @JsonKey(name: 'totalAssignments', defaultValue: 0)
  final int totalAssignments;
  @JsonKey(name: 'totalQuizzes', defaultValue: 0)
  final int totalQuizzes;

  const DashboardStats({
    required this.totalCourses,
    required this.totalGroups,
    required this.totalStudents,
    required this.totalAssignments,
    required this.totalQuizzes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}

@JsonSerializable()
class ActivityLog {
  final String id;
  final String action;
  final String description;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);
}

@JsonSerializable()
class InstructorDashboardData {
  final Semester? currentSemester;
  final DashboardStats statistics;
  final List<ActivityLog> recentActivity;

  const InstructorDashboardData({
    this.currentSemester,
    required this.statistics,
    required this.recentActivity,
  });

  factory InstructorDashboardData.fromJson(Map<String, dynamic> json) =>
      _$InstructorDashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$InstructorDashboardDataToJson(this);
}

@JsonSerializable()
class EnrolledCourse {
  final String id;
  final String courseId;
  final String groupId;
  final String semesterId;
  final Course course;
  final Group group;

  const EnrolledCourse({
    required this.id,
    required this.courseId,
    required this.groupId,
    required this.semesterId,
    required this.course,
    required this.group,
  });

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) =>
      _$EnrolledCourseFromJson(json);
  Map<String, dynamic> toJson() => _$EnrolledCourseToJson(this);
}

@JsonSerializable()
class Assignment {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @JsonKey(name: 'course_id')
  final String courseId;
  final Course course;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.courseId,
    required this.course,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentToJson(this);
}

@JsonSerializable()
class AssignmentSubmission {
  final String id;
  @JsonKey(name: 'assignment_id')
  final String assignmentId;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;
  final String status;
  final Assignment assignment;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.submittedAt,
    required this.status,
    required this.assignment,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentSubmissionToJson(this);
}

@JsonSerializable()
class StudentDashboardData {
  @JsonKey(name: 'current_semester')
  final Semester? currentSemester;
  @JsonKey(name: 'enrolled_courses')
  final List<EnrolledCourse> enrolledCourses;
  @JsonKey(name: 'upcoming_assignments')
  final List<Assignment> upcomingAssignments;
  @JsonKey(name: 'recent_submissions')
  final List<AssignmentSubmission> recentSubmissions;

  const StudentDashboardData({
    this.currentSemester,
    required this.enrolledCourses,
    required this.upcomingAssignments,
    required this.recentSubmissions,
  });

  factory StudentDashboardData.fromJson(Map<String, dynamic> json) =>
      _$StudentDashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentDashboardDataToJson(this);
}

@JsonSerializable()
class InstructorDashboardResponse {
  final bool success;
  final String? message;
  final InstructorDashboardData data;

  const InstructorDashboardResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory InstructorDashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$InstructorDashboardResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InstructorDashboardResponseToJson(this);
}

@JsonSerializable()
class StudentDashboardResponse {
  final bool success;
  final String? message;
  final StudentDashboardData data;

  const StudentDashboardResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory StudentDashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentDashboardResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentDashboardResponseToJson(this);
}

@JsonSerializable()
@JsonSerializable()
class CurrentSemesterResponse {
  final bool success;
  final CurrentSemesterData? data;

  const CurrentSemesterResponse({
    required this.success,
    this.data,
  });

  factory CurrentSemesterResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrentSemesterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentSemesterResponseToJson(this);
}

@JsonSerializable()
class CurrentSemesterData {
  @JsonKey(name: 'currentSemester')
  final Semester? currentSemester;

  const CurrentSemesterData({
    this.currentSemester,
  });

  factory CurrentSemesterData.fromJson(Map<String, dynamic> json) =>
      _$CurrentSemesterDataFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentSemesterDataToJson(this);
}

@JsonSerializable()
class SwitchSemesterResponse {
  final bool success;
  final String? message;
  final SwitchSemesterData? data;

  const SwitchSemesterResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SwitchSemesterResponse.fromJson(Map<String, dynamic> json) =>
      _$SwitchSemesterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SwitchSemesterResponseToJson(this);
}

@JsonSerializable()
class SwitchSemesterData {
  final Semester semester;

  const SwitchSemesterData({
    required this.semester,
  });

  factory SwitchSemesterData.fromJson(Map<String, dynamic> json) =>
      _$SwitchSemesterDataFromJson(json);
  Map<String, dynamic> toJson() => _$SwitchSemesterDataToJson(this);
}
