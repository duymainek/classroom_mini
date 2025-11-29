// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialResponse _$MaterialResponseFromJson(Map<String, dynamic> json) =>
    MaterialResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : MaterialData.fromJson(json['data'] as Map<String, dynamic>),
      meta: json['meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MaterialResponseToJson(MaterialResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'meta': instance.meta,
    };

MaterialData _$MaterialDataFromJson(Map<String, dynamic> json) => MaterialData(
      material: json['material'] == null
          ? null
          : Material.fromJson(json['material'] as Map<String, dynamic>),
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => Material.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => MaterialFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracking: json['tracking'] == null
          ? null
          : TrackingData.fromJson(json['tracking'] as Map<String, dynamic>),
      fileTracking: (json['fileTracking'] as List<dynamic>?)
          ?.map((e) => FileTrackingData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MaterialDataToJson(MaterialData instance) =>
    <String, dynamic>{
      'material': instance.material,
      'materials': instance.materials,
      'pagination': instance.pagination,
      'files': instance.files,
      'tracking': instance.tracking,
      'fileTracking': instance.fileTracking,
    };

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      course: MaterialCourse.fromJson(json['course'] as Map<String, dynamic>),
      instructor: MaterialInstructor.fromJson(
          json['instructor'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>)
          .map((e) => MaterialFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewCount: json['viewCount'] as int,
    );

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'course': instance.course,
      'instructor': instance.instructor,
      'files': instance.files,
      'viewCount': instance.viewCount,
    };

MaterialCourse _$MaterialCourseFromJson(Map<String, dynamic> json) =>
    MaterialCourse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$MaterialCourseToJson(MaterialCourse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

MaterialInstructor _$MaterialInstructorFromJson(Map<String, dynamic> json) =>
    MaterialInstructor(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$MaterialInstructorToJson(MaterialInstructor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
    };

MaterialFile _$MaterialFileFromJson(Map<String, dynamic> json) => MaterialFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int,
      fileType: json['fileType'] as String?,
    );

Map<String, dynamic> _$MaterialFileToJson(MaterialFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
    };

TrackingData _$TrackingDataFromJson(Map<String, dynamic> json) => TrackingData(
      tracking: (json['tracking'] as List<dynamic>)
          .map((e) => StudentTracking.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary:
          TrackingSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TrackingDataToJson(TrackingData instance) =>
    <String, dynamic>{
      'tracking': instance.tracking,
      'summary': instance.summary,
    };

StudentTracking _$StudentTrackingFromJson(Map<String, dynamic> json) =>
    StudentTracking(
      student: MaterialUser.fromJson(json['student'] as Map<String, dynamic>),
      group: MaterialGroup.fromJson(json['group'] as Map<String, dynamic>),
      viewed: json['viewed'] as bool,
      viewedAt: json['viewedAt'] == null
          ? null
          : DateTime.parse(json['viewedAt'] as String),
      viewCount: json['viewCount'] as int,
    );

Map<String, dynamic> _$StudentTrackingToJson(StudentTracking instance) =>
    <String, dynamic>{
      'student': instance.student,
      'group': instance.group,
      'viewed': instance.viewed,
      'viewedAt': instance.viewedAt?.toIso8601String(),
      'viewCount': instance.viewCount,
    };

TrackingSummary _$TrackingSummaryFromJson(Map<String, dynamic> json) =>
    TrackingSummary(
      total: json['total'] as int,
      viewed: json['viewed'] as int,
      notViewed: json['notViewed'] as int,
    );

Map<String, dynamic> _$TrackingSummaryToJson(TrackingSummary instance) =>
    <String, dynamic>{
      'total': instance.total,
      'viewed': instance.viewed,
      'notViewed': instance.notViewed,
    };

FileTrackingData _$FileTrackingDataFromJson(Map<String, dynamic> json) =>
    FileTrackingData(
      file: MaterialFile.fromJson(json['file'] as Map<String, dynamic>),
      downloads: (json['downloads'] as List<dynamic>)
          .map((e) => FileDownload.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDownloads: json['totalDownloads'] as int,
    );

Map<String, dynamic> _$FileTrackingDataToJson(FileTrackingData instance) =>
    <String, dynamic>{
      'file': instance.file,
      'downloads': instance.downloads,
      'totalDownloads': instance.totalDownloads,
    };

FileDownload _$FileDownloadFromJson(Map<String, dynamic> json) => FileDownload(
      student: MaterialUser.fromJson(json['student'] as Map<String, dynamic>),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      downloadCount: json['downloadCount'] as int,
    );

Map<String, dynamic> _$FileDownloadToJson(FileDownload instance) =>
    <String, dynamic>{
      'student': instance.student,
      'downloadedAt': instance.downloadedAt.toIso8601String(),
      'downloadCount': instance.downloadCount,
    };

MaterialUser _$MaterialUserFromJson(Map<String, dynamic> json) => MaterialUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$MaterialUserToJson(MaterialUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
    };

MaterialGroup _$MaterialGroupFromJson(Map<String, dynamic> json) =>
    MaterialGroup(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$MaterialGroupToJson(MaterialGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      pages: json['pages'] as int,
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };
