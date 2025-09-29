// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentResponse _$AssignmentResponseFromJson(Map<String, dynamic> json) =>
    AssignmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: Assignment.fromJson(AssignmentResponse._readAssignment(json, 'data')
          as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentResponseToJson(AssignmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AssignmentListResponse _$AssignmentListResponseFromJson(
        Map<String, dynamic> json) =>
    AssignmentListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (AssignmentListResponse._readAssignments(json, 'data')
              as List<dynamic>)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
          AssignmentListResponse._readPagination(json, 'pagination')
              as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssignmentListResponseToJson(
        AssignmentListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'pagination': instance.pagination,
    };

SubmissionResponse _$SubmissionResponseFromJson(Map<String, dynamic> json) =>
    SubmissionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: AssignmentSubmission.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionResponseToJson(SubmissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SubmissionListResponse _$SubmissionListResponseFromJson(
        Map<String, dynamic> json) =>
    SubmissionListResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionListResponseToJson(
        SubmissionListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'pagination': instance.pagination,
    };

StudentSubmissionResponse _$StudentSubmissionResponseFromJson(
        Map<String, dynamic> json) =>
    StudentSubmissionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      assignment:
          Assignment.fromJson(json['assignment'] as Map<String, dynamic>),
      submissions: (json['submissions'] as List<dynamic>)
          .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentAttempts: (json['currentAttempts'] as num).toInt(),
      remainingAttempts: (json['remainingAttempts'] as num).toInt(),
    );

Map<String, dynamic> _$StudentSubmissionResponseToJson(
        StudentSubmissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'assignment': instance.assignment,
      'submissions': instance.submissions,
      'currentAttempts': instance.currentAttempts,
      'remainingAttempts': instance.remainingAttempts,
    };

SubmissionTrackingResponse _$SubmissionTrackingResponseFromJson(
        Map<String, dynamic> json) =>
    SubmissionTrackingResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map(
              (e) => SubmissionTrackingData.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmissionTrackingResponseToJson(
        SubmissionTrackingResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'pagination': instance.pagination,
    };

AttachmentResponse _$AttachmentResponseFromJson(Map<String, dynamic> json) =>
    AttachmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: SubmissionAttachment.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentResponseToJson(AttachmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) =>
    PaginationInfo(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationInfoToJson(PaginationInfo instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };
