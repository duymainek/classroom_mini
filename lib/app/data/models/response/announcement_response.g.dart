// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementResponse _$AnnouncementResponseFromJson(
        Map<String, dynamic> json) =>
    AnnouncementResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : AnnouncementData.fromJson(json['data'] as Map<String, dynamic>),
      meta: json['meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AnnouncementResponseToJson(
        AnnouncementResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'meta': instance.meta,
    };

AnnouncementData _$AnnouncementDataFromJson(Map<String, dynamic> json) =>
    AnnouncementData(
      announcement: json['announcement'] == null
          ? null
          : Announcement.fromJson(json['announcement'] as Map<String, dynamic>),
      announcements: (json['announcements'] as List<dynamic>?)
          ?.map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => AnnouncementComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => AnnouncementFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracking: json['tracking'] == null
          ? null
          : TrackingData.fromJson(json['tracking'] as Map<String, dynamic>),
      fileTracking: (json['fileTracking'] as List<dynamic>?)
          ?.map((e) => FileTrackingData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnnouncementDataToJson(AnnouncementData instance) =>
    <String, dynamic>{
      'announcement': instance.announcement,
      'announcements': instance.announcements,
      'pagination': instance.pagination,
      'comments': instance.comments,
      'files': instance.files,
      'tracking': instance.tracking,
      'fileTracking': instance.fileTracking,
    };

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      scopeType: json['scopeType'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      course:
          AnnouncementCourse.fromJson(json['course'] as Map<String, dynamic>),
      instructor: AnnouncementInstructor.fromJson(
          json['instructor'] as Map<String, dynamic>),
      groups: (json['groups'] as List<dynamic>)
          .map((e) => AnnouncementGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List<dynamic>)
          .map((e) => AnnouncementFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      commentCount: (json['commentCount'] as num).toInt(),
      viewCount: (json['viewCount'] as num).toInt(),
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'scopeType': instance.scopeType,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'course': instance.course,
      'instructor': instance.instructor,
      'groups': instance.groups,
      'files': instance.files,
      'commentCount': instance.commentCount,
      'viewCount': instance.viewCount,
    };

AnnouncementCourse _$AnnouncementCourseFromJson(Map<String, dynamic> json) =>
    AnnouncementCourse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$AnnouncementCourseToJson(AnnouncementCourse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

AnnouncementInstructor _$AnnouncementInstructorFromJson(
        Map<String, dynamic> json) =>
    AnnouncementInstructor(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$AnnouncementInstructorToJson(
        AnnouncementInstructor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
    };

AnnouncementGroup _$AnnouncementGroupFromJson(Map<String, dynamic> json) =>
    AnnouncementGroup(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$AnnouncementGroupToJson(AnnouncementGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

AnnouncementFile _$AnnouncementFileFromJson(Map<String, dynamic> json) =>
    AnnouncementFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      fileType: json['fileType'] as String?,
    );

Map<String, dynamic> _$AnnouncementFileToJson(AnnouncementFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
    };

AnnouncementComment _$AnnouncementCommentFromJson(Map<String, dynamic> json) =>
    AnnouncementComment(
      id: json['id'] as String,
      commentText: json['commentText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: AnnouncementUser.fromJson(json['user'] as Map<String, dynamic>),
      parentCommentId: json['parentCommentId'] as String?,
    );

Map<String, dynamic> _$AnnouncementCommentToJson(
        AnnouncementComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'commentText': instance.commentText,
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user,
      'parentCommentId': instance.parentCommentId,
    };

AnnouncementUser _$AnnouncementUserFromJson(Map<String, dynamic> json) =>
    AnnouncementUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$AnnouncementUserToJson(AnnouncementUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
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
      student:
          AnnouncementUser.fromJson(json['student'] as Map<String, dynamic>),
      group: AnnouncementGroup.fromJson(json['group'] as Map<String, dynamic>),
      viewed: json['viewed'] as bool,
      viewedAt: json['viewedAt'] == null
          ? null
          : DateTime.parse(json['viewedAt'] as String),
      viewCount: (json['viewCount'] as num).toInt(),
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
      total: (json['total'] as num).toInt(),
      viewed: (json['viewed'] as num).toInt(),
      notViewed: (json['notViewed'] as num).toInt(),
    );

Map<String, dynamic> _$TrackingSummaryToJson(TrackingSummary instance) =>
    <String, dynamic>{
      'total': instance.total,
      'viewed': instance.viewed,
      'notViewed': instance.notViewed,
    };

FileTrackingData _$FileTrackingDataFromJson(Map<String, dynamic> json) =>
    FileTrackingData(
      file: AnnouncementFile.fromJson(json['file'] as Map<String, dynamic>),
      downloads: (json['downloads'] as List<dynamic>)
          .map((e) => FileDownload.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDownloads: (json['totalDownloads'] as num).toInt(),
    );

Map<String, dynamic> _$FileTrackingDataToJson(FileTrackingData instance) =>
    <String, dynamic>{
      'file': instance.file,
      'downloads': instance.downloads,
      'totalDownloads': instance.totalDownloads,
    };

FileDownload _$FileDownloadFromJson(Map<String, dynamic> json) => FileDownload(
      student:
          AnnouncementUser.fromJson(json['student'] as Map<String, dynamic>),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      downloadCount: (json['downloadCount'] as num).toInt(),
    );

Map<String, dynamic> _$FileDownloadToJson(FileDownload instance) =>
    <String, dynamic>{
      'student': instance.student,
      'downloadedAt': instance.downloadedAt.toIso8601String(),
      'downloadCount': instance.downloadCount,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };
