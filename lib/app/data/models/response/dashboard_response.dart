import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'semester_response.dart';

part 'dashboard_response.g.dart';

@JsonSerializable()
class DashboardStats {
  final int totalCourses;
  final int totalGroups;
  final int totalStudents;
  final int totalAssignments;
  final int totalQuizzes;
  final int totalAnnouncements;

  const DashboardStats({
    required this.totalCourses,
    required this.totalGroups,
    required this.totalStudents,
    required this.totalAssignments,
    required this.totalQuizzes,
    required this.totalAnnouncements,
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
class StudentDashboardData {
  final Semester? currentSemester;
  final List<EnrolledCourse> enrolledCourses;
  final List<Assignment> upcomingAssignments;
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
