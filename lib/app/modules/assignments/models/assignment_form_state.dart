import 'package:classroom_mini/app/data/models/assignment_model.dart';

class AssignmentFormState {
  String? title;
  String? description;
  String? courseId;
  DateTime? startDate;
  DateTime? dueDate;
  DateTime? lateDueDate;
  bool allowLateSubmission;
  int maxAttempts;
  List<String> fileFormats;
  int maxFileSize;
  Set<String> selectedGroupIds;
  List<CourseInfo> courses;
  List<GroupInfo> groups;

  AssignmentFormState({
    this.title,
    this.description,
    this.courseId,
    this.startDate,
    this.dueDate,
    this.lateDueDate,
    this.allowLateSubmission = false,
    this.maxAttempts = 1,
    List<String>? fileFormats,
    this.maxFileSize = 10,
    Set<String>? selectedGroupIds,
    List<CourseInfo>? courses,
    List<GroupInfo>? groups,
  })  : fileFormats = fileFormats ?? <String>[],
        selectedGroupIds = selectedGroupIds ?? <String>{},
        courses = courses ?? const <CourseInfo>[],
        groups = groups ?? const <GroupInfo>[];

  AssignmentFormState copyWith({
    String? title,
    String? description,
    String? courseId,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? lateDueDate,
    bool? allowLateSubmission,
    int? maxAttempts,
    List<String>? fileFormats,
    int? maxFileSize,
    Set<String>? selectedGroupIds,
    List<CourseInfo>? courses,
    List<GroupInfo>? groups,
  }) {
    return AssignmentFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      lateDueDate: lateDueDate ?? this.lateDueDate,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      fileFormats: fileFormats ?? List<String>.from(this.fileFormats),
      maxFileSize: maxFileSize ?? this.maxFileSize,
      selectedGroupIds:
          selectedGroupIds ?? Set<String>.from(this.selectedGroupIds),
      courses: courses ?? List<CourseInfo>.from(this.courses),
      groups: groups ?? List<GroupInfo>.from(this.groups),
    );
  }

  bool get isValidBasic {
    final titleOk = (title?.trim().length ?? 0) >= 2;
    final courseOk = courseId != null && courseId!.isNotEmpty;
    final startOk = startDate != null;
    final dueOk = dueDate != null;
    final lateOk = !allowLateSubmission ||
        lateDueDate == null ||
        (dueDate != null && lateDueDate!.isAfter(dueDate!));
    return titleOk && courseOk && startOk && dueOk && lateOk;
  }
}
