import 'package:json_annotation/json_annotation.dart';
import 'course_model.dart';
import 'semester_model.dart';

part 'group_model.g.dart';

@JsonSerializable()
class Group {
  final String id;
  final String name;
  @JsonKey(name: 'course_id')
  final String courseId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'courses')
  final GroupCourseBrief? courseBrief;

  const Group({
    required this.id,
    required this.name,
    required this.courseId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.courseBrief,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  Group copyWith({
    String? id,
    String? name,
    String? courseId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    GroupCourseBrief? courseBrief,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      courseId: courseId ?? this.courseId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseBrief: courseBrief ?? this.courseBrief,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, courseId: $courseId)';
  }
}

@JsonSerializable()
class GroupCreateRequest {
  final String name;
  @JsonKey(name: 'courseId')
  final String courseId;

  const GroupCreateRequest({
    required this.name,
    required this.courseId,
  });

  factory GroupCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GroupCreateRequestToJson(this);
}

@JsonSerializable()
class GroupUpdateRequest {
  final String? name;
  @JsonKey(name: 'courseId')
  final String? courseId;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  const GroupUpdateRequest({
    this.name,
    this.courseId,
    this.isActive,
  });

  factory GroupUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GroupUpdateRequestToJson(this);
}

@JsonSerializable()
class GroupListData {
  final List<Group> groups;
  final PaginationInfo pagination;

  const GroupListData({
    required this.groups,
    required this.pagination,
  });

  factory GroupListData.fromJson(Map<String, dynamic> json) =>
      _$GroupListDataFromJson(json);
  Map<String, dynamic> toJson() => _$GroupListDataToJson(this);
}

@JsonSerializable()
class GroupListResponse {
  final bool success;
  final GroupListData data;

  const GroupListResponse({
    required this.success,
    required this.data,
  });

  factory GroupListResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GroupListResponseToJson(this);
}

@JsonSerializable()
class GroupResponse {
  final Group group;

  const GroupResponse({
    required this.group,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GroupResponseToJson(this);
}

@JsonSerializable()
class GroupCourseBrief {
  final String code;
  final String name;
  @JsonKey(name: 'semesters')
  final CourseSemesterBrief? semesterBrief;

  const GroupCourseBrief({
    required this.code,
    required this.name,
    this.semesterBrief,
  });

  factory GroupCourseBrief.fromJson(Map<String, dynamic> json) =>
      _$GroupCourseBriefFromJson(json);
  Map<String, dynamic> toJson() => _$GroupCourseBriefToJson(this);
}
