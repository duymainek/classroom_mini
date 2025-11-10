// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentSubmission _$AssignmentSubmissionFromJson(
        Map<String, dynamic> json) =>
    AssignmentSubmission(
      id: json['id'] as String?,
      assignmentId: json['assignmentId'] as String?,
      studentId: json['studentId'] as String?,
      attemptNumber: (json['attemptNumber'] as num?)?.toInt(),
      submissionText: json['submissionText'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isLate: json['isLate'] as bool,
      grade: (json['grade'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedAt: json['gradedAt'] == null
          ? null
          : DateTime.parse(json['gradedAt'] as String),
      gradedBy: json['gradedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
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
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
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
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SubmissionAttachmentToJson(
        SubmissionAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'createdAt': instance.createdAt?.toIso8601String(),
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
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      totalSubmissions: (json['totalSubmissions'] as num).toInt(),
      gradedSubmissions: (json['gradedSubmissions'] as num).toInt(),
      lateSubmissions: (json['lateSubmissions'] as num).toInt(),
      averageGrade: (json['averageGrade'] as num?)?.toDouble(),
      latestSubmission: json['latestSubmission'] == null
          ? null
          : AssignmentSubmission.fromJson(
              json['latestSubmission'] as Map<String, dynamic>),
      status: $enumDecode(_$SubmissionStatusEnumMap, json['status'],
          unknownValue: SubmissionStatus.notSubmitted),
      hasMultipleAttempts: json['hasMultipleAttempts'] as bool,
    );

Map<String, dynamic> _$SubmissionTrackingDataToJson(
        SubmissionTrackingData instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
      'groupId': instance.groupId,
      'groupName': instance.groupName,
      'totalSubmissions': instance.totalSubmissions,
      'gradedSubmissions': instance.gradedSubmissions,
      'lateSubmissions': instance.lateSubmissions,
      'averageGrade': instance.averageGrade,
      'latestSubmission': instance.latestSubmission,
      'status': _$SubmissionStatusEnumMap[instance.status]!,
      'hasMultipleAttempts': instance.hasMultipleAttempts,
    };

const _$SubmissionStatusEnumMap = {
  SubmissionStatus.notSubmitted: 'not_submitted',
  SubmissionStatus.submitted: 'submitted',
  SubmissionStatus.late: 'late',
  SubmissionStatus.graded: 'graded',
};

SubmissionData _$SubmissionDataFromJson(Map<String, dynamic> json) =>
    SubmissionData(
      submission: AssignmentSubmission.fromJson(
          json['submission'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionDataToJson(SubmissionData instance) =>
    <String, dynamic>{
      'submission': instance.submission,
    };

SubmissionResponse _$SubmissionResponseFromJson(Map<String, dynamic> json) =>
    SubmissionResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: SubmissionData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionResponseToJson(SubmissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

StudentSubmissionData _$StudentSubmissionDataFromJson(
        Map<String, dynamic> json) =>
    StudentSubmissionData(
      submissions: (json['submissions'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StudentSubmissionDataToJson(
        StudentSubmissionData instance) =>
    <String, dynamic>{
      'submissions': instance.submissions,
    };

StudentSubmissionResponse _$StudentSubmissionResponseFromJson(
        Map<String, dynamic> json) =>
    StudentSubmissionResponse(
      success: json['success'] as bool,
      data:
          StudentSubmissionData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentSubmissionResponseToJson(
        StudentSubmissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

SubmissionListData _$SubmissionListDataFromJson(Map<String, dynamic> json) =>
    SubmissionListData(
      submissions: (json['submissions'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionListDataToJson(SubmissionListData instance) =>
    <String, dynamic>{
      'submissions': instance.submissions,
      'pagination': instance.pagination,
    };

SubmissionListResponse _$SubmissionListResponseFromJson(
        Map<String, dynamic> json) =>
    SubmissionListResponse(
      success: json['success'] as bool,
      data: SubmissionListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionListResponseToJson(
        SubmissionListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

SubmissionTrackingList _$SubmissionTrackingListFromJson(
        Map<String, dynamic> json) =>
    SubmissionTrackingList(
      submissions: (json['submissions'] as List<dynamic>)
          .map(
              (e) => SubmissionTrackingData.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionTrackingListToJson(
        SubmissionTrackingList instance) =>
    <String, dynamic>{
      'submissions': instance.submissions,
      'pagination': instance.pagination,
    };

SubmissionTrackingResponse _$SubmissionTrackingResponseFromJson(
        Map<String, dynamic> json) =>
    SubmissionTrackingResponse(
      success: json['success'] as bool,
      data:
          SubmissionTrackingList.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionTrackingResponseToJson(
        SubmissionTrackingResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

AttachmentData _$AttachmentDataFromJson(Map<String, dynamic> json) =>
    AttachmentData(
      attachment: SubmissionAttachment.fromJson(
          json['attachment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentDataToJson(AttachmentData instance) =>
    <String, dynamic>{
      'attachment': instance.attachment,
    };

AttachmentResponse _$AttachmentResponseFromJson(Map<String, dynamic> json) =>
    AttachmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: AttachmentData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentResponseToJson(AttachmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
