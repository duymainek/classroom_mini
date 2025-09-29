// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      instructorId: json['instructor_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      lateDueDate: json['late_due_date'] == null
          ? null
          : DateTime.parse(json['late_due_date'] as String),
      allowLateSubmission: json['allow_late_submission'] as bool,
      maxAttempts: (json['max_attempts'] as num).toInt(),
      fileFormats: (json['file_formats'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxFileSize: (json['max_file_size'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      course: json['courses'] == null
          ? null
          : CourseInfo.fromJson(json['courses'] as Map<String, dynamic>),
      instructor: json['users'] == null
          ? null
          : InstructorInfo.fromJson(json['users'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  AssignmentAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => GroupInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'course_id': instance.courseId,
      'instructor_id': instance.instructorId,
      'start_date': instance.startDate.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'late_due_date': instance.lateDueDate?.toIso8601String(),
      'allow_late_submission': instance.allowLateSubmission,
      'max_attempts': instance.maxAttempts,
      'file_formats': instance.fileFormats,
      'max_file_size': instance.maxFileSize,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'courses': instance.course,
      'users': instance.instructor,
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
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AssignmentAttachmentToJson(
        AssignmentAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'created_at': instance.createdAt.toIso8601String(),
    };

CourseInfo _$CourseInfoFromJson(Map<String, dynamic> json) => CourseInfo(
      id: json['id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CourseInfoToJson(CourseInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

InstructorInfo _$InstructorInfoFromJson(Map<String, dynamic> json) =>
    InstructorInfo(
      id: json['id'] as String?,
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$InstructorInfoToJson(InstructorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
    };

GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => GroupInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$GroupInfoToJson(GroupInfo instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
