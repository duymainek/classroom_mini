import 'package:json_annotation/json_annotation.dart';

part 'semester_response.g.dart';

@JsonSerializable()
class Semester {
  final String id;
  final String code;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Semester({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Semester.fromJson(Map<String, dynamic> json) =>
      _$SemesterFromJson(json);
@override
  Map<String, dynamic> toJson() => _$SemesterToJson(this);

  Semester copyWith({
    String? id,
    String? code,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Semester(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Semester && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Semester(id: $id, code: $code, name: $name, isActive: $isActive)';
  }
}

@JsonSerializable()
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);
@override
  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}

@JsonSerializable()
class SemesterListData {
  final List<Semester> semesters;
  final PaginationInfo pagination;

  const SemesterListData({
    required this.semesters,
    required this.pagination,
  });

  factory SemesterListData.fromJson(Map<String, dynamic> json) =>
      _$SemesterListDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$SemesterListDataToJson(this);
}

@JsonSerializable()
class SemesterListResponse {
  final bool success;
  final SemesterListData data;

  const SemesterListResponse({
    required this.success,
    required this.data,
  });

  factory SemesterListResponse.fromJson(Map<String, dynamic> json) =>
      _$SemesterListResponseFromJson(json);
@override
  Map<String, dynamic> toJson() => _$SemesterListResponseToJson(this);
}

@JsonSerializable()
class SemesterResponse {
  final bool success;
  final String? message;
  final SemesterData data;

  const SemesterResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory SemesterResponse.fromJson(Map<String, dynamic> json) {
    return SemesterResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: SemesterData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

@override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

@JsonSerializable()
class SemesterData {
  final Semester semester;

  const SemesterData({
    required this.semester,
  });

  factory SemesterData.fromJson(Map<String, dynamic> json) =>
      _$SemesterDataFromJson(json);
@override
  Map<String, dynamic> toJson() => _$SemesterDataToJson(this);
}
