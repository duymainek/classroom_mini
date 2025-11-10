import 'package:json_annotation/json_annotation.dart';

part 'material_response.g.dart';

@JsonSerializable()
class MaterialResponse {
  final bool success;
  final String message;
  final MaterialData? data;
  final Map<String, dynamic>? meta;

  const MaterialResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  factory MaterialResponse.fromJson(Map<String, dynamic> json) =>
      _$MaterialResponseFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialResponseToJson(this);
}

@JsonSerializable()
class MaterialData {
  final Material? material;
  final List<Material>? materials;
  final Pagination? pagination;
  final List<MaterialFile>? files;
  final TrackingData? tracking;
  final List<FileTrackingData>? fileTracking;

  const MaterialData({
    this.material,
    this.materials,
    this.pagination,
    this.files,
    this.tracking,
    this.fileTracking,
  });

  factory MaterialData.fromJson(Map<String, dynamic> json) =>
      _$MaterialDataFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialDataToJson(this);
}

@JsonSerializable()
class Material {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  final MaterialCourse course;
  final MaterialInstructor instructor;
  final List<MaterialFile> files;
  @JsonKey(name: 'viewCount')
  final int viewCount;

  const Material({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.updatedAt,
    required this.course,
    required this.instructor,
    required this.files,
    required this.viewCount,
  });

  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialToJson(this);
}

@JsonSerializable()
class MaterialCourse {
  final String id;
  final String code;
  final String name;

  const MaterialCourse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory MaterialCourse.fromJson(Map<String, dynamic> json) =>
      _$MaterialCourseFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialCourseToJson(this);
}

@JsonSerializable()
class MaterialInstructor {
  final String id;
  @JsonKey(name: 'fullName')
  final String fullName;
  final String email;

  const MaterialInstructor({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory MaterialInstructor.fromJson(Map<String, dynamic> json) =>
      _$MaterialInstructorFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialInstructorToJson(this);
}

@JsonSerializable()
class MaterialFile {
  final String id;
  @JsonKey(name: 'fileName')
  final String fileName;
  @JsonKey(name: 'fileUrl')
  final String fileUrl;
  @JsonKey(name: 'fileSize')
  final int fileSize;
  @JsonKey(name: 'fileType')
  final String? fileType;

  const MaterialFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    this.fileType,
  });

  factory MaterialFile.fromJson(Map<String, dynamic> json) =>
      _$MaterialFileFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialFileToJson(this);
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
  final MaterialUser student;
  final MaterialGroup group;
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
  final MaterialFile file;
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
  final MaterialUser student;
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
class MaterialUser {
  final String id;
  @JsonKey(name: 'fullName')
  final String fullName;
  final String email;
  final String role;
  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;

  const MaterialUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory MaterialUser.fromJson(Map<String, dynamic> json) =>
      _$MaterialUserFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialUserToJson(this);
}

@JsonSerializable()
class MaterialGroup {
  final String id;
  final String name;

  const MaterialGroup({
    required this.id,
    required this.name,
  });

  factory MaterialGroup.fromJson(Map<String, dynamic> json) =>
      _$MaterialGroupFromJson(json);

@override
  Map<String, dynamic> toJson() => _$MaterialGroupToJson(this);
}

@JsonSerializable()
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

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
