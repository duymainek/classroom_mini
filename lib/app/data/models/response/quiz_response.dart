import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart'; // For CourseInfo and GroupInfo
import 'semester_response.dart';

part 'quiz_response.g.dart';

// --- Quiz Model ---
@JsonSerializable()
class Quiz {
  final String id;
  final String title;
  final String? description;
  final String courseId;
  final String instructorId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final int? timeLimit; // in minutes
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showCorrectAnswers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseInfo? course; // Nested course info (backend returns 'courses')
  final UserInfo?
      instructor; // Nested instructor info (backend returns 'users')
  final List<QuizGroup>? quizGroups; // Nested group info (via pivot table)
  final List<QuizQuestion>? questions; // Nested questions
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
    this.instructor,
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
  final String? quizId;
  final String? groupId;
  final GroupInfo? groups; // Nested group info

  QuizGroup({
    this.id,
    this.quizId,
    this.groupId,
    this.groups,
  });

  factory QuizGroup.fromJson(Map<String, dynamic> json) {
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
  final String quizId;
  final String questionText;
  final String questionType; // 'text', 'multiple_choice', or 'essay'
  final int points;
  final int orderIndex;
  final bool isRequired;
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

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      quizId: (json['quiz_id'] ?? '') as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: (json['points'] ?? 1) as int,
      orderIndex: (json['order_index'] ?? 0) as int,
      isRequired: (json['is_required'] ?? true) as bool,
      options: (json['quiz_question_options'] as List?)
          ?.map((e) => QuizQuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);
}

// --- QuizQuestionOption Model ---
@JsonSerializable()
class QuizQuestionOption {
  final String id;
  final String questionId;
  final String optionText;
  final bool isCorrect;
  final int orderIndex;

  QuizQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
    required this.orderIndex,
  });

  factory QuizQuestionOption.fromJson(Map<String, dynamic> json) {
    return QuizQuestionOption(
      id: json['id'] as String,
      questionId: (json['question_id'] ?? '') as String,
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'] as bool,
      orderIndex: json['order_index'] as int,
    );
  }
  Map<String, dynamic> toJson() => _$QuizQuestionOptionToJson(this);
}

// --- Response Models ---
@JsonSerializable()
class QuizListData {
  final List<Quiz> quizzes;
  final PaginationInfo pagination;

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

  factory QuizSingleResponse.fromJson(Map<String, dynamic> json) {
    final dynamic dataField = json['data'];
    if (dataField is Map<String, dynamic> && dataField['quiz'] != null) {
      return QuizSingleResponse(
        success: json['success'] as bool,
        data: Quiz.fromJson(dataField['quiz'] as Map<String, dynamic>),
      );
    }
    return _$QuizSingleResponseFromJson(json);
  }
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

// --- UserInfo Model ---
@JsonSerializable()
class UserInfo {
  final String fullName;

  UserInfo({required this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        fullName: json['full_name'] as String,
      );
  Map<String, dynamic> toJson() => {
        'full_name': fullName,
      };
}
