import 'package:json_annotation/json_annotation.dart';

part 'quiz_request.g.dart';

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
  final String? courseId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? lateDueDate;
  final bool? allowLateSubmission;
  final int? maxAttempts;
  final int? timeLimit;
  final bool? shuffleQuestions;
  final bool? shuffleOptions;
  final bool? showCorrectAnswers;
  final bool? isActive;
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
  final String questionType; // 'text', 'multiple_choice', or 'essay'
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
