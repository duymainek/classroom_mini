// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      totalCourses: (json['totalCourses'] as num).toInt(),
      totalGroups: (json['totalGroups'] as num).toInt(),
      totalStudents: (json['totalStudents'] as num).toInt(),
      totalAssignments: (json['totalAssignments'] as num).toInt(),
      totalQuizzes: (json['totalQuizzes'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'totalCourses': instance.totalCourses,
      'totalGroups': instance.totalGroups,
      'totalStudents': instance.totalStudents,
      'totalAssignments': instance.totalAssignments,
      'totalQuizzes': instance.totalQuizzes,
    };

ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) => ActivityLog(
      id: json['id'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ActivityLogToJson(ActivityLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
    };

InstructorDashboardData _$InstructorDashboardDataFromJson(
        Map<String, dynamic> json) =>
    InstructorDashboardData(
      currentSemester: json['currentSemester'] == null
          ? null
          : Semester.fromJson(json['currentSemester'] as Map<String, dynamic>),
      statistics:
          DashboardStats.fromJson(json['statistics'] as Map<String, dynamic>),
      recentActivity: (json['recentActivity'] as List<dynamic>)
          .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InstructorDashboardDataToJson(
        InstructorDashboardData instance) =>
    <String, dynamic>{
      'currentSemester': instance.currentSemester,
      'statistics': instance.statistics,
      'recentActivity': instance.recentActivity,
    };

EnrolledCourse _$EnrolledCourseFromJson(Map<String, dynamic> json) =>
    EnrolledCourse(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      groupId: json['groupId'] as String,
      semesterId: json['semesterId'] as String,
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
      group: Group.fromJson(json['group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EnrolledCourseToJson(EnrolledCourse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'groupId': instance.groupId,
      'semesterId': instance.semesterId,
      'course': instance.course,
      'group': instance.group,
    };

StudentDashboardData _$StudentDashboardDataFromJson(
        Map<String, dynamic> json) =>
    StudentDashboardData(
      currentSemester: json['currentSemester'] == null
          ? null
          : Semester.fromJson(json['currentSemester'] as Map<String, dynamic>),
      enrolledCourses: (json['enrolledCourses'] as List<dynamic>)
          .map((e) => EnrolledCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingAssignments: (json['upcomingAssignments'] as List<dynamic>)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSubmissions: (json['recentSubmissions'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StudentDashboardDataToJson(
        StudentDashboardData instance) =>
    <String, dynamic>{
      'currentSemester': instance.currentSemester,
      'enrolledCourses': instance.enrolledCourses,
      'upcomingAssignments': instance.upcomingAssignments,
      'recentSubmissions': instance.recentSubmissions,
    };

InstructorDashboardResponse _$InstructorDashboardResponseFromJson(
        Map<String, dynamic> json) =>
    InstructorDashboardResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: InstructorDashboardData.fromJson(
          json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InstructorDashboardResponseToJson(
        InstructorDashboardResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

StudentDashboardResponse _$StudentDashboardResponseFromJson(
        Map<String, dynamic> json) =>
    StudentDashboardResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: StudentDashboardData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentDashboardResponseToJson(
        StudentDashboardResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

CurrentSemesterResponse _$CurrentSemesterResponseFromJson(
        Map<String, dynamic> json) =>
    CurrentSemesterResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : CurrentSemesterData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CurrentSemesterResponseToJson(
        CurrentSemesterResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

CurrentSemesterData _$CurrentSemesterDataFromJson(Map<String, dynamic> json) =>
    CurrentSemesterData(
      currentSemester: json['currentSemester'] == null
          ? null
          : Semester.fromJson(json['currentSemester'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CurrentSemesterDataToJson(
        CurrentSemesterData instance) =>
    <String, dynamic>{
      'currentSemester': instance.currentSemester,
    };

SwitchSemesterResponse _$SwitchSemesterResponseFromJson(
        Map<String, dynamic> json) =>
    SwitchSemesterResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : SwitchSemesterData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwitchSemesterResponseToJson(
        SwitchSemesterResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SwitchSemesterData _$SwitchSemesterDataFromJson(Map<String, dynamic> json) =>
    SwitchSemesterData(
      semester: Semester.fromJson(json['semester'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwitchSemesterDataToJson(SwitchSemesterData instance) =>
    <String, dynamic>{
      'semester': instance.semester,
    };
