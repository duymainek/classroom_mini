import 'package:json_annotation/json_annotation.dart';
import 'assignment_model.dart'; // Assuming CourseInfo and GroupInfo are here

part 'quiz_model.g.dart';

// --- Quiz Model ---
@JsonSerializable()
class Quiz {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'course_id')
  final String courseId;
  @JsonKey(name: 'instructor_id')
  final String instructorId;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @JsonKey(name: 'late_due_date')
  final DateTime? lateDueDate;
  @JsonKey(name: 'allow_late_submission')
  final bool allowLateSubmission;
  @JsonKey(name: 'max_attempts')
  final int maxAttempts;
  @JsonKey(name: 'time_limit')
  final int? timeLimit; // in minutes
  @JsonKey(name: 'shuffle_questions')
  final bool shuffleQuestions;
  @JsonKey(name: 'shuffle_options')
  final bool shuffleOptions;
  @JsonKey(name: 'show_correct_answers')
  final bool showCorrectAnswers;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'courses')
  final CourseInfo? course; // Nested course info (backend returns 'courses')
  @JsonKey(name: 'quiz_groups')
  final List<QuizGroup>? quizGroups; // Nested group info (via pivot table)
  @JsonKey(name: 'quiz_questions')
  final List<QuizQuestion>? questions; // Nested questions
  @JsonKey(name: 'question_count')
  final int? questionCount; // For list API where questions are omitted

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.instructorId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    this.timeLimit,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.showCorrectAnswers,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.course,
    this.quizGroups,
    this.questions,
    this.questionCount,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);
  Map<String, dynamic> toJson() => _$QuizToJson(this);
}

// --- QuizGroup (Pivot table for Quiz-Group relationship) ---
@JsonSerializable()
class QuizGroup {
  final String? id;
  @JsonKey(name: 'quiz_id')
  final String? quizId;
  @JsonKey(name: 'group_id')
  final String? groupId;
  final GroupInfo? groups; // Nested group info

  QuizGroup({
    this.id,
    this.quizId,
    this.groupId,
    this.groups,
  });

  factory QuizGroup.fromJson(Map<String, dynamic> json) {
    // Handle the case where response only has nested groups object
    if (json.containsKey('groups') && !json.containsKey('id')) {
      return QuizGroup(
        id: null,
        quizId: null,
        groupId: null,
        groups: GroupInfo.fromJson(json['groups'] as Map<String, dynamic>),
      );
    }
    return _$QuizGroupFromJson(json);
  }

  Map<String, dynamic> toJson() => _$QuizGroupToJson(this);
}

// --- QuizQuestion Model ---
@JsonSerializable()
class QuizQuestion {
  final String id;
  @JsonKey(name: 'quiz_id')
  final String quizId;
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'question_type')
  final String questionType; // 'text' or 'multiple_choice'
  final int points;
  @JsonKey(name: 'order_index')
  final int orderIndex;
  @JsonKey(name: 'is_required')
  final bool isRequired;
  @JsonKey(name: 'quiz_question_options')
  final List<QuizQuestionOption>? options; // For multiple choice

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.orderIndex,
    required this.isRequired,
    this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);
}

// --- QuizQuestionOption Model ---
@JsonSerializable()
class QuizQuestionOption {
  final String id;
  @JsonKey(name: 'question_id')
  final String questionId;
  @JsonKey(name: 'option_text')
  final String optionText;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  @JsonKey(name: 'order_index')
  final int orderIndex;

  QuizQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
    required this.orderIndex,
  });

  factory QuizQuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$QuizQuestionOptionToJson(this);
}

// --- Request Models ---

@JsonSerializable()
class QuizCreateRequest {
  final String title;
  final String? description;
  final String courseId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final int? timeLimit;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showCorrectAnswers;
  final List<String>? groupIds;
  final List<QuestionCreateRequest>? questions;

  QuizCreateRequest({
    required this.title,
    this.description,
    required this.courseId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    this.timeLimit,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.showCorrectAnswers,
    this.groupIds,
    this.questions,
  });

  factory QuizCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$QuizCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuizCreateRequestToJson(this);
}

@JsonSerializable()
class QuizUpdateRequest {
  final String id;
  final String? title;
  final String? description;
  @JsonKey(name: 'course_id')
  final String? courseId;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @JsonKey(name: 'late_due_date')
  final DateTime? lateDueDate;
  @JsonKey(name: 'allow_late_submission')
  final bool? allowLateSubmission;
  @JsonKey(name: 'max_attempts')
  final int? maxAttempts;
  @JsonKey(name: 'time_limit')
  final int? timeLimit;
  @JsonKey(name: 'shuffle_questions')
  final bool? shuffleQuestions;
  @JsonKey(name: 'shuffle_options')
  final bool? shuffleOptions;
  @JsonKey(name: 'show_correct_answers')
  final bool? showCorrectAnswers;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'group_ids')
  final List<String>? groupIds;

  QuizUpdateRequest({
    required this.id,
    this.title,
    this.description,
    this.courseId,
    this.startDate,
    this.dueDate,
    this.lateDueDate,
    this.allowLateSubmission,
    this.maxAttempts,
    this.timeLimit,
    this.shuffleQuestions,
    this.shuffleOptions,
    this.showCorrectAnswers,
    this.isActive,
    this.groupIds,
  });

  factory QuizUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$QuizUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuizUpdateRequestToJson(this);
}

@JsonSerializable()
class QuestionCreateRequest {
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'question_type')
  final String questionType; // 'text' or 'multiple_choice'
  final int? points;
  @JsonKey(name: 'order_index')
  final int? orderIndex;
  @JsonKey(name: 'is_required')
  final bool? isRequired;
  final List<QuestionOptionCreateRequest>? options;

  QuestionCreateRequest({
    required this.questionText,
    required this.questionType,
    this.points,
    this.orderIndex,
    this.isRequired,
    this.options,
  });

  factory QuestionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionCreateRequestToJson(this);
}

@JsonSerializable()
class QuestionUpdateRequest {
  final String id;
  @JsonKey(name: 'question_text')
  final String? questionText;
  @JsonKey(name: 'question_type')
  final String? questionType; // 'text' or 'multiple_choice'
  final int? points;
  @JsonKey(name: 'order_index')
  final int? orderIndex;
  @JsonKey(name: 'is_required')
  final bool? isRequired;
  final List<QuestionOptionCreateRequest>? options;

  QuestionUpdateRequest({
    required this.id,
    this.questionText,
    this.questionType,
    this.points,
    this.orderIndex,
    this.isRequired,
    this.options,
  });

  factory QuestionUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionUpdateRequestToJson(this);
}

@JsonSerializable()
class QuestionOptionCreateRequest {
  @JsonKey(name: 'option_text')
  final String optionText;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  @JsonKey(name: 'order_index')
  final int? orderIndex;

  QuestionOptionCreateRequest({
    required this.optionText,
    required this.isCorrect,
    this.orderIndex,
  });

  factory QuestionOptionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionOptionCreateRequestToJson(this);
}

// --- Response Models ---
@JsonSerializable()
class QuizListData {
  final List<Quiz> quizzes;
  final Pagination pagination;

  QuizListData({required this.quizzes, required this.pagination});

  factory QuizListData.fromJson(Map<String, dynamic> json) =>
      _$QuizListDataFromJson(json);
  Map<String, dynamic> toJson() => _$QuizListDataToJson(this);
}

@JsonSerializable()
class QuizListResponse {
  final bool success;
  final QuizListData data;

  QuizListResponse({required this.success, required this.data});

  factory QuizListResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizListResponseToJson(this);
}

@JsonSerializable()
class QuizSingleResponse {
  final bool success;
  final Quiz data;

  QuizSingleResponse({required this.success, required this.data});

  factory QuizSingleResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizSingleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizSingleResponseToJson(this);
}

@JsonSerializable()
class QuizQuestionSingleResponse {
  final bool success;
  final QuizQuestion data;

  QuizQuestionSingleResponse({required this.success, required this.data});

  factory QuizQuestionSingleResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionSingleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizQuestionSingleResponseToJson(this);
}

// --- Quiz Create Response Model ---
@JsonSerializable()
class QuizCreateResponse {
  final bool success;
  final String message;
  final QuizCreateData data;

  QuizCreateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory QuizCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizCreateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizCreateResponseToJson(this);
}

@JsonSerializable()
class QuizCreateData {
  final Quiz quiz;

  QuizCreateData({required this.quiz});

  factory QuizCreateData.fromJson(Map<String, dynamic> json) =>
      _$QuizCreateDataFromJson(json);
  Map<String, dynamic> toJson() => _$QuizCreateDataToJson(this);
}

// --- Pagination (re-use if exists, otherwise define) ---
@JsonSerializable()
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination(
      {required this.page,
      required this.limit,
      required this.total,
      required this.pages});

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
