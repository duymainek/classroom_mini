import 'package:json_annotation/json_annotation.dart';

part 'attachment_response.g.dart';

@JsonSerializable()
class AttachmentUploadResponse {
  final bool success;
  final String message;
  final AttachmentUploadData data;

  AttachmentUploadResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentUploadResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AttachmentUploadResponseToJson(this);
}

@JsonSerializable()
class AttachmentUploadData {
  final List<AttachmentFile> attachments;
  final int uploadCount;

  AttachmentUploadData({
    required this.attachments,
    required this.uploadCount,
  });

  factory AttachmentUploadData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentUploadDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AttachmentUploadDataToJson(this);
}

@JsonSerializable()
class AttachmentListResponse {
  final bool success;
  final String? message;
  final AttachmentListData data;

  AttachmentListResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AttachmentListResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentListResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AttachmentListResponseToJson(this);
}

@JsonSerializable()
class AttachmentListData {
  final List<AttachmentFile> attachments;
  final int count;

  AttachmentListData({
    required this.attachments,
    required this.count,
  });

  factory AttachmentListData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentListDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AttachmentListDataToJson(this);
}

@JsonSerializable()
class AttachmentFile {
  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String fileType;
  final DateTime createdAt;

  AttachmentFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
  });

  factory AttachmentFile.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFileFromJson(json);
@override
  Map<String, dynamic> toJson() => _$AttachmentFileToJson(this);
}

@JsonSerializable()
class TempAttachmentResponse {
  final bool success;
  final String message;
  final TempAttachmentData data;

  TempAttachmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TempAttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$TempAttachmentResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$TempAttachmentResponseToJson(this);
}

@JsonSerializable()
class TempAttachmentData {
  final String attachmentId;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String fileType;

  TempAttachmentData({
    required this.attachmentId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
  });

  factory TempAttachmentData.fromJson(Map<String, dynamic> json) =>
      _$TempAttachmentDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$TempAttachmentDataToJson(this);
}
