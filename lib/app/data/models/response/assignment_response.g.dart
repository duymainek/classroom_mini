// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String,
      instructorId: json['instructorId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lateDueDate: json['lateDueDate'] == null
          ? null
          : DateTime.parse(json['lateDueDate'] as String),
      allowLateSubmission: json['allowLateSubmission'] as bool,
      maxAttempts: (json['maxAttempts'] as num).toInt(),
      fileFormats: (json['fileFormats'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxFileSize: (json['maxFileSize'] as num).toInt(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      course: json['course'] == null
          ? null
          : CourseInfo.fromJson(json['course'] as Map<String, dynamic>),
      instructor: json['instructor'] == null
          ? null
          : InstructorInfo.fromJson(json['instructor'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  AssignmentAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      groups: (Assignment._readGroups(json, 'groups') as List<dynamic>?)
              ?.map((e) => GroupInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'instructorId': instance.instructorId,
      'startDate': instance.startDate.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'fileFormats': instance.fileFormats,
      'maxFileSize': instance.maxFileSize,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'course': instance.course,
      'instructor': instance.instructor,
      'attachments': instance.attachments,
      'groups': instance.groups,
    };

AssignmentAttachment _$AssignmentAttachmentFromJson(
        Map<String, dynamic> json) =>
    AssignmentAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileType: json['fileType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AssignmentAttachmentToJson(
        AssignmentAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CourseInfo _$CourseInfoFromJson(Map<String, dynamic> json) => CourseInfo(
      id: json['id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      semesterId: json['semesterId'] as String?,
    );

Map<String, dynamic> _$CourseInfoToJson(CourseInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'semesterId': instance.semesterId,
    };

InstructorInfo _$InstructorInfoFromJson(Map<String, dynamic> json) =>
    InstructorInfo(
      id: json['id'] as String?,
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$InstructorInfoToJson(InstructorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
    };

GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => GroupInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$GroupInfoToJson(GroupInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

AssignmentListData _$AssignmentListDataFromJson(Map<String, dynamic> json) =>
    AssignmentListData(
      assignments: (json['assignments'] as List<dynamic>)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentListDataToJson(AssignmentListData instance) =>
    <String, dynamic>{
      'assignments': instance.assignments,
      'pagination': instance.pagination,
    };

AssignmentListResponse _$AssignmentListResponseFromJson(
        Map<String, dynamic> json) =>
    AssignmentListResponse(
      success: json['success'] as bool,
      data: AssignmentListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentListResponseToJson(
        AssignmentListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

AssignmentData _$AssignmentDataFromJson(Map<String, dynamic> json) =>
    AssignmentData(
      assignment:
          Assignment.fromJson(json['assignment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentDataToJson(AssignmentData instance) =>
    <String, dynamic>{
      'assignment': instance.assignment,
    };

AssignmentResponse _$AssignmentResponseFromJson(Map<String, dynamic> json) =>
    AssignmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: AssignmentData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentResponseToJson(AssignmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
