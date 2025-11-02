// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentUploadResponse _$AttachmentUploadResponseFromJson(
        Map<String, dynamic> json) =>
    AttachmentUploadResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: AttachmentUploadData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentUploadResponseToJson(
        AttachmentUploadResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AttachmentUploadData _$AttachmentUploadDataFromJson(
        Map<String, dynamic> json) =>
    AttachmentUploadData(
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => AttachmentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      uploadCount: (json['uploadCount'] as num).toInt(),
    );

Map<String, dynamic> _$AttachmentUploadDataToJson(
        AttachmentUploadData instance) =>
    <String, dynamic>{
      'attachments': instance.attachments,
      'uploadCount': instance.uploadCount,
    };

AttachmentListResponse _$AttachmentListResponseFromJson(
        Map<String, dynamic> json) =>
    AttachmentListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: AttachmentListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentListResponseToJson(
        AttachmentListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AttachmentListData _$AttachmentListDataFromJson(Map<String, dynamic> json) =>
    AttachmentListData(
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => AttachmentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AttachmentListDataToJson(AttachmentListData instance) =>
    <String, dynamic>{
      'attachments': instance.attachments,
      'count': instance.count,
    };

AttachmentFile _$AttachmentFileFromJson(Map<String, dynamic> json) =>
    AttachmentFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      fileType: json['fileType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AttachmentFileToJson(AttachmentFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'createdAt': instance.createdAt.toIso8601String(),
    };

TempAttachmentResponse _$TempAttachmentResponseFromJson(
        Map<String, dynamic> json) =>
    TempAttachmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: TempAttachmentData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TempAttachmentResponseToJson(
        TempAttachmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

TempAttachmentData _$TempAttachmentDataFromJson(Map<String, dynamic> json) =>
    TempAttachmentData(
      attachmentId: json['attachmentId'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      fileType: json['fileType'] as String,
    );

Map<String, dynamic> _$TempAttachmentDataToJson(TempAttachmentData instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
    };
