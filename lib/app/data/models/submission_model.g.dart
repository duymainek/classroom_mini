// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentSubmission _$AssignmentSubmissionFromJson(
        Map<String, dynamic> json) =>
    AssignmentSubmission(
      id: json['id'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      attemptNumber: (json['attemptNumber'] as num).toInt(),
      submissionText: json['submissionText'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isLate: json['isLate'] as bool,
      grade: (json['grade'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedAt: json['gradedAt'] == null
          ? null
          : DateTime.parse(json['gradedAt'] as String),
      gradedBy: json['gradedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  SubmissionAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      student: json['student'] == null
          ? null
          : StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentSubmissionToJson(
        AssignmentSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assignmentId': instance.assignmentId,
      'studentId': instance.studentId,
      'attemptNumber': instance.attemptNumber,
      'submissionText': instance.submissionText,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'isLate': instance.isLate,
      'grade': instance.grade,
      'feedback': instance.feedback,
      'gradedAt': instance.gradedAt?.toIso8601String(),
      'gradedBy': instance.gradedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'attachments': instance.attachments,
      'student': instance.student,
    };

SubmissionAttachment _$SubmissionAttachmentFromJson(
        Map<String, dynamic> json) =>
    SubmissionAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileType: json['fileType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SubmissionAttachmentToJson(
        SubmissionAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'createdAt': instance.createdAt.toIso8601String(),
    };

StudentInfo _$StudentInfoFromJson(Map<String, dynamic> json) => StudentInfo(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$StudentInfoToJson(StudentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
    };

SubmissionTrackingData _$SubmissionTrackingDataFromJson(
        Map<String, dynamic> json) =>
    SubmissionTrackingData(
      studentId: json['studentId'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      totalSubmissions: (json['totalSubmissions'] as num).toInt(),
      latestSubmission: json['latestSubmission'] == null
          ? null
          : AssignmentSubmission.fromJson(
              json['latestSubmission'] as Map<String, dynamic>),
      status: $enumDecode(_$SubmissionStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$SubmissionTrackingDataToJson(
        SubmissionTrackingData instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
      'totalSubmissions': instance.totalSubmissions,
      'latestSubmission': instance.latestSubmission,
      'status': _$SubmissionStatusEnumMap[instance.status]!,
    };

const _$SubmissionStatusEnumMap = {
  SubmissionStatus.notSubmitted: 'notSubmitted',
  SubmissionStatus.submitted: 'submitted',
  SubmissionStatus.late: 'late',
  SubmissionStatus.graded: 'graded',
};
