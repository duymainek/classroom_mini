// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentCreateRequest _$AssignmentCreateRequestFromJson(
        Map<String, dynamic> json) =>
    AssignmentCreateRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String,
      semesterId: json['semesterId'] as String,
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
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AssignmentCreateRequestToJson(
        AssignmentCreateRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'semesterId': instance.semesterId,
      'startDate': instance.startDate.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'fileFormats': instance.fileFormats,
      'maxFileSize': instance.maxFileSize,
      'groupIds': instance.groupIds,
      'attachmentIds': instance.attachmentIds,
    };

AssignmentUpdateRequest _$AssignmentUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    AssignmentUpdateRequest(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      courseId: json['courseId'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      lateDueDate: json['lateDueDate'] == null
          ? null
          : DateTime.parse(json['lateDueDate'] as String),
      allowLateSubmission: json['allowLateSubmission'] as bool?,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      fileFormats: (json['fileFormats'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      maxFileSize: (json['maxFileSize'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AssignmentUpdateRequestToJson(
        AssignmentUpdateRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'startDate': instance.startDate?.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'fileFormats': instance.fileFormats,
      'maxFileSize': instance.maxFileSize,
      'isActive': instance.isActive,
      'groupIds': instance.groupIds,
      'attachmentIds': instance.attachmentIds,
    };

SubmitAssignmentRequest _$SubmitAssignmentRequestFromJson(
        Map<String, dynamic> json) =>
    SubmitAssignmentRequest(
      submissionText: json['submissionText'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => SubmissionAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubmitAssignmentRequestToJson(
        SubmitAssignmentRequest instance) =>
    <String, dynamic>{
      'submissionText': instance.submissionText,
      'attachments': instance.attachments,
    };

UpdateSubmissionRequest _$UpdateSubmissionRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateSubmissionRequest(
      submissionText: json['submissionText'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => SubmissionAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateSubmissionRequestToJson(
        UpdateSubmissionRequest instance) =>
    <String, dynamic>{
      'submissionText': instance.submissionText,
      'attachments': instance.attachments,
    };

GradeSubmissionRequest _$GradeSubmissionRequestFromJson(
        Map<String, dynamic> json) =>
    GradeSubmissionRequest(
      grade: (json['grade'] as num).toDouble(),
      feedback: json['feedback'] as String?,
    );

Map<String, dynamic> _$GradeSubmissionRequestToJson(
        GradeSubmissionRequest instance) =>
    <String, dynamic>{
      'grade': instance.grade,
      'feedback': instance.feedback,
    };

FileUploadRequest _$FileUploadRequestFromJson(Map<String, dynamic> json) =>
    FileUploadRequest(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
    );

Map<String, dynamic> _$FileUploadRequestToJson(FileUploadRequest instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'fileType': instance.fileType,
    };
