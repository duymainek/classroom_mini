import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/auth_response.dart';

part 'announcement_response.g.dart';

@JsonSerializable()
class AnnouncementResponse extends BaseResponse {
  final AnnouncementData? data;
  final Map<String, dynamic>? meta;

  AnnouncementResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
    this.meta,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementResponseToJson(this);
}

@JsonSerializable()
class AnnouncementData {
  final Announcement? announcement;
  final List<Announcement>? announcements;
  final Pagination? pagination;
  final List<AnnouncementComment>? comments;
  final List<AnnouncementFile>? files;
  final TrackingData? tracking;
  final List<FileTrackingData>? fileTracking;

  const AnnouncementData({
    this.announcement,
    this.announcements,
    this.pagination,
    this.comments,
    this.files,
    this.tracking,
    this.fileTracking,
  });

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    // Nếu json có các field của Announcement (id, title, content, scopeType)
    // nhưng không có field 'announcement', thì tự động wrap vào 'announcement'
    // Điều này xử lý trường hợp backend trả về announcement object trực tiếp trong data
    if (json.containsKey('id') &&
        json.containsKey('title') &&
        json.containsKey('content') &&
        json.containsKey('scopeType') &&
        !json.containsKey('announcement')) {
      // Đây là một announcement object trực tiếp, wrap nó vào 'announcement'
      final announcementJson = Map<String, dynamic>.from(json);
      final wrappedJson = <String, dynamic>{};

      // Wrap toàn bộ json vào 'announcement' field
      wrappedJson['announcement'] = announcementJson;

      // Giữ lại các field khác nếu có (như files, tracking ở root level)
      // Chỉ giữ lại nếu không phải là field của Announcement
      final announcementFields = {
        'id',
        'title',
        'content',
        'scopeType',
        'publishedAt',
        'updatedAt',
        'course',
        'instructor',
        'groups',
        'commentCount',
        'viewCount'
      };

      json.forEach((key, value) {
        if (!announcementFields.contains(key)) {
          wrappedJson[key] = value;
        }
      });

      return _$AnnouncementDataFromJson(wrappedJson);
    }
    return _$AnnouncementDataFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$AnnouncementDataToJson(this);
}

@JsonSerializable()
class Announcement {
  final String id;
  final String title;
  final String content;
  @JsonKey(name: 'scopeType')
  final String scopeType;
  @JsonKey(name: 'publishedAt')
  final DateTime publishedAt;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  final AnnouncementCourse course;
  final AnnouncementInstructor instructor;
  final List<AnnouncementGroup> groups;
  @JsonKey(name: 'files', defaultValue: <AnnouncementFile>[])
  final List<AnnouncementFile> files;
  @JsonKey(name: 'commentCount', defaultValue: 0)
  final int commentCount;
  @JsonKey(name: 'viewCount', defaultValue: 0)
  final int viewCount;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.scopeType,
    required this.publishedAt,
    this.updatedAt,
    required this.course,
    required this.instructor,
    required this.groups,
    List<AnnouncementFile>? files,
    int? commentCount,
    int? viewCount,
  })  : files = files ?? const [],
        commentCount = commentCount ?? 0,
        viewCount = viewCount ?? 0;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}

@JsonSerializable()
class AnnouncementCourse {
  final String id;
  final String code;
  final String name;

  const AnnouncementCourse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory AnnouncementCourse.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementCourseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementCourseToJson(this);
}

@JsonSerializable()
class AnnouncementInstructor {
  final String id;
  @JsonKey(name: 'fullName', defaultValue: '')
  final String fullName;
  @JsonKey(name: 'email', defaultValue: '')
  final String email;

  const AnnouncementInstructor({
    required this.id,
    String? fullName,
    String? email,
  })  : fullName = fullName ?? '',
        email = email ?? '';

  factory AnnouncementInstructor.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementInstructorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementInstructorToJson(this);
}

@JsonSerializable()
class AnnouncementGroup {
  final String id;
  @JsonKey(name: 'name', defaultValue: '')
  final String name;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? courseId;

  const AnnouncementGroup({
    required this.id,
    String? name,
    this.courseId,
  }) : name = name ?? '';

  factory AnnouncementGroup.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementGroupFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementGroupToJson(this);
}

@JsonSerializable()
class AnnouncementFile {
  final String id;
  @JsonKey(name: 'fileName')
  final String fileName;
  @JsonKey(name: 'fileUrl')
  final String fileUrl;
  @JsonKey(name: 'fileSize')
  final int fileSize;
  @JsonKey(name: 'fileType')
  final String? fileType;

  const AnnouncementFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    this.fileType,
  });

  factory AnnouncementFile.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFileFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementFileToJson(this);
}

@JsonSerializable()
class AnnouncementComment {
  final String id;
  @JsonKey(name: 'commentText')
  final String commentText;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  final AnnouncementUser user;
  @JsonKey(name: 'parentCommentId')
  final String? parentCommentId;

  const AnnouncementComment({
    required this.id,
    required this.commentText,
    required this.createdAt,
    required this.user,
    this.parentCommentId,
  });

  factory AnnouncementComment.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementCommentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementCommentToJson(this);
}

@JsonSerializable()
class AnnouncementUser {
  final String id;
  @JsonKey(name: 'fullName')
  final String fullName;
  final String email;
  final String role;
  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;

  const AnnouncementUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory AnnouncementUser.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnnouncementUserToJson(this);
}

@JsonSerializable()
class TrackingData {
  final List<StudentTracking> tracking;
  final TrackingSummary summary;

  const TrackingData({
    required this.tracking,
    required this.summary,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) =>
      _$TrackingDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TrackingDataToJson(this);
}

@JsonSerializable()
class StudentTracking {
  final AnnouncementUser student;
  final AnnouncementGroup group;
  final bool viewed;
  @JsonKey(name: 'viewedAt')
  final DateTime? viewedAt;
  @JsonKey(name: 'viewCount')
  final int viewCount;

  const StudentTracking({
    required this.student,
    required this.group,
    required this.viewed,
    this.viewedAt,
    required this.viewCount,
  });

  factory StudentTracking.fromJson(Map<String, dynamic> json) =>
      _$StudentTrackingFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StudentTrackingToJson(this);
}

@JsonSerializable()
class TrackingSummary {
  final int total;
  final int viewed;
  @JsonKey(name: 'notViewed')
  final int notViewed;

  const TrackingSummary({
    required this.total,
    required this.viewed,
    required this.notViewed,
  });

  factory TrackingSummary.fromJson(Map<String, dynamic> json) =>
      _$TrackingSummaryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TrackingSummaryToJson(this);
}

@JsonSerializable()
class FileTrackingData {
  final AnnouncementFile file;
  final List<FileDownload> downloads;
  @JsonKey(name: 'totalDownloads')
  final int totalDownloads;

  const FileTrackingData({
    required this.file,
    required this.downloads,
    required this.totalDownloads,
  });

  factory FileTrackingData.fromJson(Map<String, dynamic> json) =>
      _$FileTrackingDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FileTrackingDataToJson(this);
}

@JsonSerializable()
class FileDownload {
  final AnnouncementUser student;
  @JsonKey(name: 'downloadedAt')
  final DateTime downloadedAt;
  @JsonKey(name: 'downloadCount')
  final int downloadCount;

  const FileDownload({
    required this.student,
    required this.downloadedAt,
    required this.downloadCount,
  });

  factory FileDownload.fromJson(Map<String, dynamic> json) =>
      _$FileDownloadFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FileDownloadToJson(this);
}

@JsonSerializable()
class Pagination {
  final int? page;
  final int? limit;
  final int? total;
  final int? pages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
