import 'package:flutter/material.dart';
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

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Handle both 'questions' and 'quiz_questions' fields from backend
    final questionsData = json['questions'] ?? json['quiz_questions'];
    if (questionsData != null) {
      json = Map<String, dynamic>.from(json);
      json['questions'] = questionsData;
    }
    return _$QuizFromJson(json);
  }
  @override
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

  @override
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
    try {
      final quizIdValue = json['quizId'] ?? json['quiz_id'] ?? '';
      final questionTextValue =
          json['questionText'] ?? json['question_text'] ?? '';
      final questionTypeValue =
          json['questionType'] ?? json['question_type'] ?? '';
      final pointsValue = json['points'] ?? 1;
      final orderIndexValue = json['orderIndex'] ?? json['order_index'] ?? 0;
      final isRequiredValue = json['isRequired'] ?? json['is_required'] ?? true;

      final optionsData = json['quizQuestionOptions'] ??
          json['quiz_question_options'] ??
          json['options'];

      List<QuizQuestionOption>? parsedOptions;
      if (optionsData != null && optionsData is List) {
        try {
          parsedOptions = (optionsData)
              .where((e) => e != null)
              .map(
                  (e) => QuizQuestionOption.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('⚠️ Error parsing quiz question options: $e');
          parsedOptions = null;
        }
      }

      return QuizQuestion(
        id: json['id'] as String? ?? '',
        quizId: quizIdValue.toString(),
        questionText: questionTextValue.toString(),
        questionType: questionTypeValue.toString(),
        points: (pointsValue is int)
            ? pointsValue
            : ((pointsValue is num) ? pointsValue.toInt() : 1),
        orderIndex: (orderIndexValue is int)
            ? orderIndexValue
            : ((orderIndexValue is num) ? orderIndexValue.toInt() : 0),
        isRequired: (isRequiredValue is bool) ? isRequiredValue : true,
        options: parsedOptions,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing QuizQuestion: $e');
      debugPrint('   JSON: $json');
      debugPrint('   Stack: $stackTrace');
      rethrow;
    }
  }
  @override
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
    try {
      final questionIdValue = json['questionId'] ?? json['question_id'] ?? '';
      final optionTextValue = json['optionText'] ?? json['option_text'] ?? '';
      final isCorrectValue = json['isCorrect'] ?? json['is_correct'] ?? false;
      final orderIndexValue = json['orderIndex'] ?? json['order_index'] ?? 0;

      return QuizQuestionOption(
        id: json['id']?.toString() ?? '',
        questionId: questionIdValue.toString(),
        optionText: optionTextValue.toString(),
        isCorrect: (isCorrectValue is bool) ? isCorrectValue : false,
        orderIndex: (orderIndexValue is int)
            ? orderIndexValue
            : ((orderIndexValue is num) ? orderIndexValue.toInt() : 0),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing QuizQuestionOption: $e');
      debugPrint('   JSON: $json');
      debugPrint('   Stack: $stackTrace');
      rethrow;
    }
  }
  @override
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
  @override
  Map<String, dynamic> toJson() => _$QuizListDataToJson(this);
}

@JsonSerializable()
class QuizListResponse {
  final bool success;
  final QuizListData data;

  QuizListResponse({required this.success, required this.data});

  factory QuizListResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizListResponseFromJson(json);
  @override
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
  @override
  Map<String, dynamic> toJson() => _$QuizSingleResponseToJson(this);
}

@JsonSerializable()
class QuizQuestionSingleResponse {
  final bool success;
  final QuizQuestion data;

  QuizQuestionSingleResponse({required this.success, required this.data});

  factory QuizQuestionSingleResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionSingleResponseFromJson(json);
  @override
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
  @override
  Map<String, dynamic> toJson() => _$QuizCreateResponseToJson(this);
}

@JsonSerializable()
class QuizCreateData {
  final Quiz quiz;

  QuizCreateData({required this.quiz});

  factory QuizCreateData.fromJson(Map<String, dynamic> json) =>
      _$QuizCreateDataFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$QuizCreateDataToJson(this);
}

// --- UserInfo Model ---
@JsonSerializable()
class UserInfo {
  final String fullName;

  UserInfo({required this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        fullName: json['fullName'] ?? json['full_name'] ?? '',
      );
  @override
  Map<String, dynamic> toJson() => {
        'full_name': fullName,
      };
}

// --- Quiz Submission Models ---
@JsonSerializable()
class QuizSubmissionResponse {
  final bool success;
  final String message;
  final QuizSubmissionData data;

  QuizSubmissionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory QuizSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmissionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizSubmissionResponseToJson(this);
}

@JsonSerializable()
class QuizSubmissionData {
  final String submissionId;
  final int attemptNumber;
  final bool isLate;
  final String status;
  final double? totalScore;
  final double? maxScore;

  QuizSubmissionData({
    required this.submissionId,
    required this.attemptNumber,
    required this.isLate,
    required this.status,
    this.totalScore,
    this.maxScore,
  });

  factory QuizSubmissionData.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmissionDataFromJson(json);
  Map<String, dynamic> toJson() => _$QuizSubmissionDataToJson(this);
}

// --- Review Answer Response ---
@JsonSerializable()
class ReviewAnswerResponse {
  final bool success;
  final String? message;
  final ReviewAnswerData? data;

  ReviewAnswerResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ReviewAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewAnswerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewAnswerResponseToJson(this);
}

@JsonSerializable()
class ReviewAnswerData {
  final ReviewedAnswer? answer;
  final double? totalScore;

  ReviewAnswerData({
    this.answer,
    this.totalScore,
  });

  factory ReviewAnswerData.fromJson(Map<String, dynamic> json) =>
      _$ReviewAnswerDataFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewAnswerDataToJson(this);
}

@JsonSerializable()
class ReviewedAnswer {
  final String id;
  final String? reviewStatus;
  final double? manualScore;
  final double? pointsEarned;
  final bool? isCorrect;

  ReviewedAnswer({
    required this.id,
    this.reviewStatus,
    this.manualScore,
    this.pointsEarned,
    this.isCorrect,
  });

  factory ReviewedAnswer.fromJson(Map<String, dynamic> json) =>
      _$ReviewedAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewedAnswerToJson(this);
}

// --- Complete Grading Response ---
@JsonSerializable()
class CompleteGradingResponse {
  final bool success;
  final String? message;
  final CompleteGradingData? data;

  CompleteGradingResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CompleteGradingResponse.fromJson(Map<String, dynamic> json) =>
      _$CompleteGradingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteGradingResponseToJson(this);
}

@JsonSerializable()
class CompleteGradingData {
  final GradedSubmission? submission;

  CompleteGradingData({
    this.submission,
  });

  factory CompleteGradingData.fromJson(Map<String, dynamic> json) =>
      _$CompleteGradingDataFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteGradingDataToJson(this);
}

@JsonSerializable()
class GradedSubmission {
  final String id;
  final bool isGraded;
  final DateTime? gradedAt;
  final String? gradedBy;
  final double? totalScore;
  final double? maxScore;

  GradedSubmission({
    required this.id,
    required this.isGraded,
    this.gradedAt,
    this.gradedBy,
    this.totalScore,
    this.maxScore,
  });

  factory GradedSubmission.fromJson(Map<String, dynamic> json) =>
      _$GradedSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$GradedSubmissionToJson(this);
}

// --- Quiz Submission Detail Models ---
@JsonSerializable()
class QuizSubmissionDetailResponse {
  final bool success;
  final QuizSubmissionDetail data;

  QuizSubmissionDetailResponse({
    required this.success,
    required this.data,
  });

  factory QuizSubmissionDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmissionDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizSubmissionDetailResponseToJson(this);
}

@JsonSerializable()
class QuizSubmissionDetail {
  final String id;
  final String quizId;
  final String studentId;
  final int attemptNumber;
  final DateTime submittedAt;
  final bool isLate;
  final double? totalScore;
  final double? maxScore;
  final bool isGraded;
  final double? grade;
  final String? feedback;
  final Quiz? quiz;
  final StudentInfo? student;
  final List<QuizAnswerDetail> answers;

  QuizSubmissionDetail({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.attemptNumber,
    required this.submittedAt,
    required this.isLate,
    this.totalScore,
    this.maxScore,
    required this.isGraded,
    this.grade,
    this.feedback,
    this.quiz,
    this.student,
    required this.answers,
  });

  factory QuizSubmissionDetail.fromJson(Map<String, dynamic> json) {
    try {
      final jsonCopy = Map<String, dynamic>.from(json);

      if (jsonCopy['quiz'] != null &&
          jsonCopy['quiz'] is Map<String, dynamic>) {
        final quizData = jsonCopy['quiz'] as Map<String, dynamic>;
        if (quizData.length <= 2 &&
            quizData.containsKey('id') &&
            quizData.containsKey('title')) {
          jsonCopy['quiz'] = null;
        }
      }

      return _$QuizSubmissionDetailFromJson(jsonCopy);
    } catch (e) {
      debugPrint('❌ Error parsing QuizSubmissionDetail: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$QuizSubmissionDetailToJson(this);
}

@JsonSerializable()
class QuizAnswerDetail {
  final String id;
  final String questionId;
  final String? answerText;
  final String? selectedOptionId;
  final QuizQuestion? question;
  final bool isCorrect;
  final double? score;
  final String? reviewStatus; // pending, approved, rejected
  final double? manualScore;

  QuizAnswerDetail({
    required this.id,
    required this.questionId,
    this.answerText,
    this.selectedOptionId,
    this.question,
    required this.isCorrect,
    this.score,
    this.reviewStatus,
    this.manualScore,
  });

  factory QuizAnswerDetail.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerDetailFromJson(json);
  Map<String, dynamic> toJson() => _$QuizAnswerDetailToJson(this);
}

@JsonSerializable()
class StudentInfo {
  final String id;
  final String fullName;
  final String? email;

  StudentInfo({
    required this.id,
    required this.fullName,
    this.email,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? json['full_name'] ?? '',
        email: json['email'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
      };
}

@JsonSerializable()
class StudentQuizSubmissionsResponse {
  final bool success;
  final StudentQuizSubmissionsData data;

  StudentQuizSubmissionsResponse({
    required this.success,
    required this.data,
  });

  factory StudentQuizSubmissionsResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentQuizSubmissionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentQuizSubmissionsResponseToJson(this);
}

@JsonSerializable()
class StudentQuizSubmissionsData {
  final List<StudentQuizSubmission> submissions;
  final int maxAttempts;
  final int currentAttempts;

  StudentQuizSubmissionsData({
    required this.submissions,
    required this.maxAttempts,
    required this.currentAttempts,
  });

  factory StudentQuizSubmissionsData.fromJson(Map<String, dynamic> json) =>
      _$StudentQuizSubmissionsDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentQuizSubmissionsDataToJson(this);
}

@JsonSerializable()
class StudentQuizSubmission {
  final String id;
  final String quizId;
  final String studentId;
  final int attemptNumber;
  final DateTime submittedAt;
  final bool isLate;
  final double? totalScore;
  final double? maxScore;
  final bool isGraded;
  final double? grade;
  final String? feedback;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentQuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.attemptNumber,
    required this.submittedAt,
    required this.isLate,
    this.totalScore,
    this.maxScore,
    required this.isGraded,
    this.grade,
    this.feedback,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentQuizSubmission.fromJson(Map<String, dynamic> json) =>
      _$StudentQuizSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$StudentQuizSubmissionToJson(this);
}
