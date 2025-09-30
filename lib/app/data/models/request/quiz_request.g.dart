// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizCreateRequest _$QuizCreateRequestFromJson(Map<String, dynamic> json) =>
    QuizCreateRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lateDueDate: json['lateDueDate'] == null
          ? null
          : DateTime.parse(json['lateDueDate'] as String),
      allowLateSubmission: json['allowLateSubmission'] as bool,
      maxAttempts: (json['maxAttempts'] as num).toInt(),
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffleQuestions'] as bool,
      shuffleOptions: json['shuffleOptions'] as bool,
      showCorrectAnswers: json['showCorrectAnswers'] as bool,
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      questions: (json['questions'] as List<dynamic>?)
          ?.map(
              (e) => QuestionCreateRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizCreateRequestToJson(QuizCreateRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'startDate': instance.startDate.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'timeLimit': instance.timeLimit,
      'shuffleQuestions': instance.shuffleQuestions,
      'shuffleOptions': instance.shuffleOptions,
      'showCorrectAnswers': instance.showCorrectAnswers,
      'groupIds': instance.groupIds,
      'questions': instance.questions,
    };

QuizUpdateRequest _$QuizUpdateRequestFromJson(Map<String, dynamic> json) =>
    QuizUpdateRequest(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      courseId: json['courseId'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      lateDueDate: json['lateDueDate'] == null
          ? null
          : DateTime.parse(json['lateDueDate'] as String),
      allowLateSubmission: json['allowLateSubmission'] as bool?,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffleQuestions'] as bool?,
      shuffleOptions: json['shuffleOptions'] as bool?,
      showCorrectAnswers: json['showCorrectAnswers'] as bool?,
      isActive: json['isActive'] as bool?,
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuizUpdateRequestToJson(QuizUpdateRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'startDate': instance.startDate?.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'timeLimit': instance.timeLimit,
      'shuffleQuestions': instance.shuffleQuestions,
      'shuffleOptions': instance.shuffleOptions,
      'showCorrectAnswers': instance.showCorrectAnswers,
      'isActive': instance.isActive,
      'groupIds': instance.groupIds,
    };

QuestionCreateRequest _$QuestionCreateRequestFromJson(
        Map<String, dynamic> json) =>
    QuestionCreateRequest(
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: (json['points'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num?)?.toInt(),
      isRequired: json['is_required'] as bool?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) =>
              QuestionOptionCreateRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionCreateRequestToJson(
        QuestionCreateRequest instance) =>
    <String, dynamic>{
      'question_text': instance.questionText,
      'question_type': instance.questionType,
      'points': instance.points,
      'order_index': instance.orderIndex,
      'is_required': instance.isRequired,
      'options': instance.options,
    };

QuestionUpdateRequest _$QuestionUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    QuestionUpdateRequest(
      id: json['id'] as String,
      questionText: json['question_text'] as String?,
      questionType: json['question_type'] as String?,
      points: (json['points'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num?)?.toInt(),
      isRequired: json['is_required'] as bool?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) =>
              QuestionOptionCreateRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionUpdateRequestToJson(
        QuestionUpdateRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_text': instance.questionText,
      'question_type': instance.questionType,
      'points': instance.points,
      'order_index': instance.orderIndex,
      'is_required': instance.isRequired,
      'options': instance.options,
    };

QuestionOptionCreateRequest _$QuestionOptionCreateRequestFromJson(
        Map<String, dynamic> json) =>
    QuestionOptionCreateRequest(
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'] as bool,
      orderIndex: (json['order_index'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuestionOptionCreateRequestToJson(
        QuestionOptionCreateRequest instance) =>
    <String, dynamic>{
      'option_text': instance.optionText,
      'is_correct': instance.isCorrect,
      'order_index': instance.orderIndex,
    };
