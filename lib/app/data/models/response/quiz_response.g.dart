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
      maxAttempts: json['maxAttempts'] as int,
      timeLimit: json['timeLimit'] as int?,
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
      questionCount: json['questionCount'] as int?,
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
      points: json['points'] as int,
      orderIndex: json['orderIndex'] as int,
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
      orderIndex: json['orderIndex'] as int,
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

QuizSubmissionResponse _$QuizSubmissionResponseFromJson(
        Map<String, dynamic> json) =>
    QuizSubmissionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: QuizSubmissionData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizSubmissionResponseToJson(
        QuizSubmissionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

QuizSubmissionData _$QuizSubmissionDataFromJson(Map<String, dynamic> json) =>
    QuizSubmissionData(
      submissionId: json['submissionId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      isLate: json['isLate'] as bool,
      status: json['status'] as String,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$QuizSubmissionDataToJson(QuizSubmissionData instance) =>
    <String, dynamic>{
      'submissionId': instance.submissionId,
      'attemptNumber': instance.attemptNumber,
      'isLate': instance.isLate,
      'status': instance.status,
      'totalScore': instance.totalScore,
      'maxScore': instance.maxScore,
    };

ReviewAnswerResponse _$ReviewAnswerResponseFromJson(
        Map<String, dynamic> json) =>
    ReviewAnswerResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : ReviewAnswerData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewAnswerResponseToJson(
        ReviewAnswerResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ReviewAnswerData _$ReviewAnswerDataFromJson(Map<String, dynamic> json) =>
    ReviewAnswerData(
      answer: json['answer'] == null
          ? null
          : ReviewedAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      totalScore: (json['totalScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ReviewAnswerDataToJson(ReviewAnswerData instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'totalScore': instance.totalScore,
    };

ReviewedAnswer _$ReviewedAnswerFromJson(Map<String, dynamic> json) =>
    ReviewedAnswer(
      id: json['id'] as String,
      reviewStatus: json['reviewStatus'] as String?,
      manualScore: (json['manualScore'] as num?)?.toDouble(),
      pointsEarned: (json['pointsEarned'] as num?)?.toDouble(),
      isCorrect: json['isCorrect'] as bool?,
    );

Map<String, dynamic> _$ReviewedAnswerToJson(ReviewedAnswer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reviewStatus': instance.reviewStatus,
      'manualScore': instance.manualScore,
      'pointsEarned': instance.pointsEarned,
      'isCorrect': instance.isCorrect,
    };

CompleteGradingResponse _$CompleteGradingResponseFromJson(
        Map<String, dynamic> json) =>
    CompleteGradingResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : CompleteGradingData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CompleteGradingResponseToJson(
        CompleteGradingResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

CompleteGradingData _$CompleteGradingDataFromJson(Map<String, dynamic> json) =>
    CompleteGradingData(
      submission: json['submission'] == null
          ? null
          : GradedSubmission.fromJson(
              json['submission'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CompleteGradingDataToJson(
        CompleteGradingData instance) =>
    <String, dynamic>{
      'submission': instance.submission,
    };

GradedSubmission _$GradedSubmissionFromJson(Map<String, dynamic> json) =>
    GradedSubmission(
      id: json['id'] as String,
      isGraded: json['isGraded'] as bool,
      gradedAt: json['gradedAt'] == null
          ? null
          : DateTime.parse(json['gradedAt'] as String),
      gradedBy: json['gradedBy'] as String?,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GradedSubmissionToJson(GradedSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isGraded': instance.isGraded,
      'gradedAt': instance.gradedAt?.toIso8601String(),
      'gradedBy': instance.gradedBy,
      'totalScore': instance.totalScore,
      'maxScore': instance.maxScore,
    };

QuizSubmissionDetailResponse _$QuizSubmissionDetailResponseFromJson(
        Map<String, dynamic> json) =>
    QuizSubmissionDetailResponse(
      success: json['success'] as bool,
      data: QuizSubmissionDetail.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuizSubmissionDetailResponseToJson(
        QuizSubmissionDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

QuizSubmissionDetail _$QuizSubmissionDetailFromJson(
        Map<String, dynamic> json) =>
    QuizSubmissionDetail(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isLate: json['isLate'] as bool,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
      isGraded: json['isGraded'] as bool,
      grade: (json['grade'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      quiz: json['quiz'] == null
          ? null
          : Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
      student: json['student'] == null
          ? null
          : StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => QuizAnswerDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizSubmissionDetailToJson(
        QuizSubmissionDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'studentId': instance.studentId,
      'attemptNumber': instance.attemptNumber,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'isLate': instance.isLate,
      'totalScore': instance.totalScore,
      'maxScore': instance.maxScore,
      'isGraded': instance.isGraded,
      'grade': instance.grade,
      'feedback': instance.feedback,
      'quiz': instance.quiz,
      'student': instance.student,
      'answers': instance.answers,
    };

QuizAnswerDetail _$QuizAnswerDetailFromJson(Map<String, dynamic> json) =>
    QuizAnswerDetail(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      answerText: json['answerText'] as String?,
      selectedOptionId: json['selectedOptionId'] as String?,
      question: json['question'] == null
          ? null
          : QuizQuestion.fromJson(json['question'] as Map<String, dynamic>),
      isCorrect: json['isCorrect'] as bool,
      score: (json['score'] as num?)?.toDouble(),
      reviewStatus: json['reviewStatus'] as String?,
      manualScore: (json['manualScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$QuizAnswerDetailToJson(QuizAnswerDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'answerText': instance.answerText,
      'selectedOptionId': instance.selectedOptionId,
      'question': instance.question,
      'isCorrect': instance.isCorrect,
      'score': instance.score,
      'reviewStatus': instance.reviewStatus,
      'manualScore': instance.manualScore,
    };

StudentInfo _$StudentInfoFromJson(Map<String, dynamic> json) => StudentInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$StudentInfoToJson(StudentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
    };

StudentQuizSubmissionsResponse _$StudentQuizSubmissionsResponseFromJson(
        Map<String, dynamic> json) =>
    StudentQuizSubmissionsResponse(
      success: json['success'] as bool,
      data: StudentQuizSubmissionsData.fromJson(
          json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StudentQuizSubmissionsResponseToJson(
        StudentQuizSubmissionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

StudentQuizSubmissionsData _$StudentQuizSubmissionsDataFromJson(
        Map<String, dynamic> json) =>
    StudentQuizSubmissionsData(
      submissions: (json['submissions'] as List<dynamic>)
          .map((e) => StudentQuizSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxAttempts: json['maxAttempts'] as int,
      currentAttempts: json['currentAttempts'] as int,
    );

Map<String, dynamic> _$StudentQuizSubmissionsDataToJson(
        StudentQuizSubmissionsData instance) =>
    <String, dynamic>{
      'submissions': instance.submissions,
      'maxAttempts': instance.maxAttempts,
      'currentAttempts': instance.currentAttempts,
    };

StudentQuizSubmission _$StudentQuizSubmissionFromJson(
        Map<String, dynamic> json) =>
    StudentQuizSubmission(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isLate: json['isLate'] as bool,
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
      isGraded: json['isGraded'] as bool,
      grade: (json['grade'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedAt: json['gradedAt'] == null
          ? null
          : DateTime.parse(json['gradedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StudentQuizSubmissionToJson(
        StudentQuizSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'studentId': instance.studentId,
      'attemptNumber': instance.attemptNumber,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'isLate': instance.isLate,
      'totalScore': instance.totalScore,
      'maxScore': instance.maxScore,
      'isGraded': instance.isGraded,
      'grade': instance.grade,
      'feedback': instance.feedback,
      'gradedAt': instance.gradedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
