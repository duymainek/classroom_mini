// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      totalCourses: (json['totalCourses'] as num?)?.toInt() ?? 0,
      totalGroups: (json['totalGroups'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalAssignments: (json['totalAssignments'] as num?)?.toInt() ?? 0,
      totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
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
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActivityLogToJson(ActivityLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
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

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      courseId: json['course_id'] as String,
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'due_date': instance.dueDate.toIso8601String(),
      'course_id': instance.courseId,
      'course': instance.course,
    };

AssignmentSubmission _$AssignmentSubmissionFromJson(
        Map<String, dynamic> json) =>
    AssignmentSubmission(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String,
      assignment:
          Assignment.fromJson(json['assignment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentSubmissionToJson(
        AssignmentSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assignment_id': instance.assignmentId,
      'student_id': instance.studentId,
      'submitted_at': instance.submittedAt.toIso8601String(),
      'status': instance.status,
      'assignment': instance.assignment,
    };

StudentDashboardData _$StudentDashboardDataFromJson(
        Map<String, dynamic> json) =>
    StudentDashboardData(
      currentSemester: json['current_semester'] == null
          ? null
          : Semester.fromJson(json['current_semester'] as Map<String, dynamic>),
      enrolledCourses: (json['enrolled_courses'] as List<dynamic>)
          .map((e) => EnrolledCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingAssignments: (json['upcoming_assignments'] as List<dynamic>)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSubmissions: (json['recent_submissions'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StudentDashboardDataToJson(
        StudentDashboardData instance) =>
    <String, dynamic>{
      'current_semester': instance.currentSemester,
      'enrolled_courses': instance.enrolledCourses,
      'upcoming_assignments': instance.upcomingAssignments,
      'recent_submissions': instance.recentSubmissions,
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
