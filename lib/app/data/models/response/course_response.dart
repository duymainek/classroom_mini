import 'package:json_annotation/json_annotation.dart';
import 'semester_response.dart';

part 'course_response.g.dart';

@JsonSerializable()
class Course {
  final String id;
  final String code;
  final String name;
  final int sessionCount;
  final String semesterId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Backend returns nested object under key "semesters" with only code & name
  final CourseSemesterBrief? semesterBrief;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    required this.sessionCount,
    required this.semesterId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.semesterBrief,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  Course copyWith({
    String? id,
    String? code,
    String? name,
    int? sessionCount,
    String? semesterId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    CourseSemesterBrief? semesterBrief,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      sessionCount: sessionCount ?? this.sessionCount,
      semesterId: semesterId ?? this.semesterId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      semesterBrief: semesterBrief ?? this.semesterBrief,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, code: $code, name: $name, sessionCount: $sessionCount, semesterId: $semesterId)';
  }
}

@JsonSerializable()
class CourseSemesterBrief {
  final String code;
  final String name;

  const CourseSemesterBrief({
    required this.code,
    required this.name,
  });

  factory CourseSemesterBrief.fromJson(Map<String, dynamic> json) =>
      _$CourseSemesterBriefFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSemesterBriefToJson(this);
}

@JsonSerializable()
class CourseListData {
  final List<Course> courses;
  final PaginationInfo pagination;

  const CourseListData({
    required this.courses,
    required this.pagination,
  });

  factory CourseListData.fromJson(Map<String, dynamic> json) =>
      _$CourseListDataFromJson(json);
  Map<String, dynamic> toJson() => _$CourseListDataToJson(this);
}

@JsonSerializable()
class CourseListResponse {
  final bool success;
  final CourseListData data;

  const CourseListResponse({
    required this.success,
    required this.data,
  });

  factory CourseListResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseListResponseToJson(this);
}

@JsonSerializable()
class CourseResponse {
  final Course course;

  const CourseResponse({
    required this.course,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseResponseToJson(this);
}
