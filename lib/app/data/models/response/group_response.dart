import 'package:json_annotation/json_annotation.dart';
import 'course_response.dart';
import 'semester_response.dart';
import 'package:classroom_mini/app/data/models/response/auth_response.dart';

part 'group_response.g.dart';

class Group {
  final String id;
  final String name;
  final String? courseId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GroupCourseBrief? courseBrief;

  const Group({
    required this.id,
    required this.name,
    this.courseId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.courseBrief,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final courseData = json['course'] ?? json['courses'];
    
    GroupCourseBrief? courseBrief;
    if (courseData != null && courseData is Map<String, dynamic>) {
      final semesterData = courseData['semester'] ?? courseData['semesters'];
      CourseSemesterBrief? semesterBrief;
      if (semesterData != null && semesterData is Map<String, dynamic>) {
        semesterBrief = CourseSemesterBrief.fromJson(semesterData);
      }
      
      courseBrief = GroupCourseBrief(
        code: courseData['code'] as String,
        name: courseData['name'] as String,
        semesterBrief: semesterBrief,
      );
    }
    
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      courseId: json['courseId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      courseBrief: courseBrief,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'courseId': courseId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'course': courseBrief?.toJson(),
    };
  }

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
class GroupListResponse extends BaseResponse {
  final GroupListData data;

  GroupListResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    required this.data,
  });

  factory GroupListResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GroupListResponseToJson(this);
}

@JsonSerializable()
class GroupResponse extends BaseResponse {
  final GroupData? data;

  GroupResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GroupResponseToJson(this);

  Group? get group => data?.group;
}

@JsonSerializable()
class GroupData {
  final Group group;

  const GroupData({
    required this.group,
  });

  factory GroupData.fromJson(Map<String, dynamic> json) =>
      _$GroupDataFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDataToJson(this);
}

class GroupCourseBrief {
  final String code;
  final String name;
  final CourseSemesterBrief? semesterBrief;

  const GroupCourseBrief({
    required this.code,
    required this.name,
    this.semesterBrief,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'semester': semesterBrief?.toJson(),
    };
  }
}
