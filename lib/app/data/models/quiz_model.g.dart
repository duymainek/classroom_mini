// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Quiz _$QuizFromJson(Map<String, dynamic> json) => Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      instructorId: json['instructor_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      lateDueDate: json['late_due_date'] == null
          ? null
          : DateTime.parse(json['late_due_date'] as String),
      allowLateSubmission: json['allow_late_submission'] as bool,
      maxAttempts: (json['max_attempts'] as num).toInt(),
      timeLimit: (json['time_limit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffle_questions'] as bool,
      shuffleOptions: json['shuffle_options'] as bool,
      showCorrectAnswers: json['show_correct_answers'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      course: json['course'] == null
          ? null
          : CourseInfo.fromJson(json['course'] as Map<String, dynamic>),
      quizGroups: (json['quiz_groups'] as List<dynamic>?)
          ?.map((e) => QuizGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      questions: (json['quiz_questions'] as List<dynamic>?)
          ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizToJson(Quiz instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'course_id': instance.courseId,
      'instructor_id': instance.instructorId,
      'start_date': instance.startDate.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'late_due_date': instance.lateDueDate?.toIso8601String(),
      'allow_late_submission': instance.allowLateSubmission,
      'max_attempts': instance.maxAttempts,
      'time_limit': instance.timeLimit,
      'shuffle_questions': instance.shuffleQuestions,
      'shuffle_options': instance.shuffleOptions,
      'show_correct_answers': instance.showCorrectAnswers,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'course': instance.course,
      'quiz_groups': instance.quizGroups,
      'quiz_questions': instance.questions,
    };

QuizGroup _$QuizGroupFromJson(Map<String, dynamic> json) => QuizGroup(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      groupId: json['group_id'] as String,
      groups: json['groups'] == null
          ? null
          : GroupInfo.fromJson(json['groups'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizGroupToJson(QuizGroup instance) => <String, dynamic>{
      'id': instance.id,
      'quiz_id': instance.quizId,
      'group_id': instance.groupId,
      'groups': instance.groups,
    };

QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) => QuizQuestion(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: (json['points'] as num).toInt(),
      orderIndex: (json['order_index'] as num).toInt(),
      isRequired: json['is_required'] as bool,
      options: (json['quiz_question_options'] as List<dynamic>?)
          ?.map((e) => QuizQuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizQuestionToJson(QuizQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_id': instance.quizId,
      'question_text': instance.questionText,
      'question_type': instance.questionType,
      'points': instance.points,
      'order_index': instance.orderIndex,
      'is_required': instance.isRequired,
      'quiz_question_options': instance.options,
    };

QuizQuestionOption _$QuizQuestionOptionFromJson(Map<String, dynamic> json) =>
    QuizQuestionOption(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'] as bool,
      orderIndex: (json['order_index'] as num).toInt(),
    );

Map<String, dynamic> _$QuizQuestionOptionToJson(QuizQuestionOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_id': instance.questionId,
      'option_text': instance.optionText,
      'is_correct': instance.isCorrect,
      'order_index': instance.orderIndex,
    };

QuizCreateRequest _$QuizCreateRequestFromJson(Map<String, dynamic> json) =>
    QuizCreateRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      lateDueDate: json['late_due_date'] == null
          ? null
          : DateTime.parse(json['late_due_date'] as String),
      allowLateSubmission: json['allow_late_submission'] as bool,
      maxAttempts: (json['max_attempts'] as num).toInt(),
      timeLimit: (json['time_limit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffle_questions'] as bool,
      shuffleOptions: json['shuffle_options'] as bool,
      showCorrectAnswers: json['show_correct_answers'] as bool,
      groupIds: (json['group_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuizCreateRequestToJson(QuizCreateRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'course_id': instance.courseId,
      'start_date': instance.startDate.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'late_due_date': instance.lateDueDate?.toIso8601String(),
      'allow_late_submission': instance.allowLateSubmission,
      'max_attempts': instance.maxAttempts,
      'time_limit': instance.timeLimit,
      'shuffle_questions': instance.shuffleQuestions,
      'shuffle_options': instance.shuffleOptions,
      'show_correct_answers': instance.showCorrectAnswers,
      'group_ids': instance.groupIds,
    };

QuizUpdateRequest _$QuizUpdateRequestFromJson(Map<String, dynamic> json) =>
    QuizUpdateRequest(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      courseId: json['course_id'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      lateDueDate: json['late_due_date'] == null
          ? null
          : DateTime.parse(json['late_due_date'] as String),
      allowLateSubmission: json['allow_late_submission'] as bool?,
      maxAttempts: (json['max_attempts'] as num?)?.toInt(),
      timeLimit: (json['time_limit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffle_questions'] as bool?,
      shuffleOptions: json['shuffle_options'] as bool?,
      showCorrectAnswers: json['show_correct_answers'] as bool?,
      isActive: json['is_active'] as bool?,
      groupIds: (json['group_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuizUpdateRequestToJson(QuizUpdateRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'course_id': instance.courseId,
      'start_date': instance.startDate?.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'late_due_date': instance.lateDueDate?.toIso8601String(),
      'allow_late_submission': instance.allowLateSubmission,
      'max_attempts': instance.maxAttempts,
      'time_limit': instance.timeLimit,
      'shuffle_questions': instance.shuffleQuestions,
      'shuffle_options': instance.shuffleOptions,
      'show_correct_answers': instance.showCorrectAnswers,
      'is_active': instance.isActive,
      'group_ids': instance.groupIds,
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

QuizListResponse _$QuizListResponseFromJson(Map<String, dynamic> json) =>
    QuizListResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => Quiz.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizListResponseToJson(QuizListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'pagination': instance.pagination,
    };

QuizSingleResponse _$QuizSingleResponseFromJson(Map<String, dynamic> json) =>
    QuizSingleResponse(
      success: json['success'] as bool,
      data: Quiz.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizSingleResponseToJson(QuizSingleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

QuizQuestionSingleResponse _$QuizQuestionSingleResponseFromJson(
        Map<String, dynamic> json) =>
    QuizQuestionSingleResponse(
      success: json['success'] as bool,
      data: QuizQuestion.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizQuestionSingleResponseToJson(
        QuizQuestionSingleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };
