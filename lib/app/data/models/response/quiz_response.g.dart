// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Quiz _$QuizFromJson(Map<String, dynamic> json) => Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String,
      instructorId: json['instructorId'] as String,
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
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      course: json['course'] == null
          ? null
          : CourseInfo.fromJson(json['course'] as Map<String, dynamic>),
      instructor: json['instructor'] == null
          ? null
          : UserInfo.fromJson(json['instructor'] as Map<String, dynamic>),
      quizGroups: (json['quizGroups'] as List<dynamic>?)
          ?.map((e) => QuizGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionCount: (json['questionCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuizToJson(Quiz instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'courseId': instance.courseId,
      'instructorId': instance.instructorId,
      'startDate': instance.startDate.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'lateDueDate': instance.lateDueDate?.toIso8601String(),
      'allowLateSubmission': instance.allowLateSubmission,
      'maxAttempts': instance.maxAttempts,
      'timeLimit': instance.timeLimit,
      'shuffleQuestions': instance.shuffleQuestions,
      'shuffleOptions': instance.shuffleOptions,
      'showCorrectAnswers': instance.showCorrectAnswers,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'course': instance.course,
      'instructor': instance.instructor,
      'quizGroups': instance.quizGroups,
      'questions': instance.questions,
      'questionCount': instance.questionCount,
    };

QuizGroup _$QuizGroupFromJson(Map<String, dynamic> json) => QuizGroup(
      id: json['id'] as String?,
      quizId: json['quizId'] as String?,
      groupId: json['groupId'] as String?,
      groups: json['groups'] == null
          ? null
          : GroupInfo.fromJson(json['groups'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizGroupToJson(QuizGroup instance) => <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'groupId': instance.groupId,
      'groups': instance.groups,
    };

QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) => QuizQuestion(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      questionText: json['questionText'] as String,
      questionType: json['questionType'] as String,
      points: (json['points'] as num).toInt(),
      orderIndex: (json['orderIndex'] as num).toInt(),
      isRequired: json['isRequired'] as bool,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => QuizQuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizQuestionToJson(QuizQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'questionText': instance.questionText,
      'questionType': instance.questionType,
      'points': instance.points,
      'orderIndex': instance.orderIndex,
      'isRequired': instance.isRequired,
      'options': instance.options,
    };

QuizQuestionOption _$QuizQuestionOptionFromJson(Map<String, dynamic> json) =>
    QuizQuestionOption(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      optionText: json['optionText'] as String,
      isCorrect: json['isCorrect'] as bool,
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$QuizQuestionOptionToJson(QuizQuestionOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'optionText': instance.optionText,
      'isCorrect': instance.isCorrect,
      'orderIndex': instance.orderIndex,
    };

QuizListData _$QuizListDataFromJson(Map<String, dynamic> json) => QuizListData(
      quizzes: (json['quizzes'] as List<dynamic>)
          .map((e) => Quiz.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizListDataToJson(QuizListData instance) =>
    <String, dynamic>{
      'quizzes': instance.quizzes,
      'pagination': instance.pagination,
    };

QuizListResponse _$QuizListResponseFromJson(Map<String, dynamic> json) =>
    QuizListResponse(
      success: json['success'] as bool,
      data: QuizListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizListResponseToJson(QuizListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
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

QuizCreateResponse _$QuizCreateResponseFromJson(Map<String, dynamic> json) =>
    QuizCreateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: QuizCreateData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizCreateResponseToJson(QuizCreateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

QuizCreateData _$QuizCreateDataFromJson(Map<String, dynamic> json) =>
    QuizCreateData(
      quiz: Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizCreateDataToJson(QuizCreateData instance) =>
    <String, dynamic>{
      'quiz': instance.quiz,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'fullName': instance.fullName,
    };
