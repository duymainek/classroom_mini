import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import '../../../data/services/quiz_api_service.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/api_service.dart';

class QuizController extends GetxController {
  final QuizApiService _quizApiService;
  late final GeminiService _geminiService; // Instantiate GeminiService

  QuizController(this._quizApiService);

  final RxList<Quiz> quizzes = <Quiz>[].obs;
  final RxList<SubmissionTrackingData> submissions =
      <SubmissionTrackingData>[].obs;
  final RxList<SubmissionTrackingData> _allSubmissions =
      <SubmissionTrackingData>[].obs;
  final Rx<Quiz?> currentQuiz = Rx<Quiz?>(null);
  final RxString selectedGroupId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool _isGeneratingQuiz = false.obs; // Dedicated loading for Gemini

  // Filters and pagination
  final RxString searchQuery = ''.obs;
  final RxString courseIdFilter = ''.obs;
  final RxString semesterIdFilter = ''.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString sortBy = 'created_at'.obs;
  final RxString sortOrder = 'desc'.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;

  // Getters
  List<GroupInfo> get groups {
    if (currentQuiz.value?.quizGroups == null) return [];
    final result = <GroupInfo>[];
    for (final qg in currentQuiz.value!.quizGroups!) {
      if (qg.groups != null && qg.groups!.id.isNotEmpty) {
        result.add(qg.groups!);
      } else if (qg.groupId != null && qg.groupId!.isNotEmpty) {
        result.add(GroupInfo(id: qg.groupId!, name: qg.groups?.name ?? ''));
      }
    }
    return result;
  }

  // Getter for filtered submissions based on selected group
  List<SubmissionTrackingData> get filteredSubmissions {
    if (selectedGroupId.value.isEmpty) {
      return submissions;
    }
    return submissions
        .where((s) => s.groupId == selectedGroupId.value)
        .toList();
  }

  int get totalStudents => filteredSubmissions.length;
  int get submittedCount => filteredSubmissions
      .where((s) => s.status != SubmissionStatus.notSubmitted)
      .length;
  int get notSubmittedCount => filteredSubmissions
      .where((s) => s.status == SubmissionStatus.notSubmitted)
      .length;
  int get gradedCount => filteredSubmissions
      .where((s) => s.status == SubmissionStatus.graded)
      .length;

  void updateSelectedGroupId(String? groupId) {
    selectedGroupId.value = groupId ?? '';
    // Filter is done locally via filteredSubmissions getter
  }

  bool get isGeneratingQuiz => _isGeneratingQuiz.value;

  @override
  void onInit() {
    super.onInit();
    _geminiService = GeminiService(); // Initialize GeminiService without Dio
    loadQuizzes();
  }

  // New method to generate quizzes using Gemini API
  Future<List<QuestionCreateRequest>?> generateQuizQuestionsFromGemini(
      String prompt, int numberOfQuestions) async {
    _isGeneratingQuiz.value = true;
    errorMessage.value = '';

    try {
      // Gọi Gemini API và nhận response trực tiếp
      final response =
          await _geminiService.generateQuiz(prompt, numberOfQuestions);

      // Extract JSON from markdown code block if present
      String jsonString = response.trim();
      if (jsonString.startsWith('```json')) {
        // Remove markdown code block markers
        jsonString = jsonString
            .replaceFirst('```json', '')
            .replaceFirst('```', '')
            .trim();
      } else if (jsonString.startsWith('```')) {
        // Remove generic code block markers
        jsonString =
            jsonString.replaceFirst('```', '').replaceFirst('```', '').trim();
      }

      // Parse JSON response
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<QuestionCreateRequest> generatedQuestions =
          jsonList.map((json) {
        final question = QuestionCreateRequest.fromJson(json);
        // Set default points to 1 for all questions
        return QuestionCreateRequest(
          questionText: question.questionText,
          questionType: question.questionType,
          points: 1, // Default to 1 point
          orderIndex: question.orderIndex,
          isRequired: question.isRequired,
          options: question.options,
        );
      }).toList();

      Get.snackbar(
          'Success', 'Quiz questions generated successfully by Gemini AI');
      return generatedQuestions;
    } catch (e) {
      errorMessage.value = 'Failed to generate quiz questions: $e';
      debugPrint('Failed to generate quiz questions: $e');
      Get.snackbar('Error', errorMessage.value);
      return null;
    } finally {
      _isGeneratingQuiz.value = false;
    }
  }

  Future<void> loadQuizzes({bool refresh = false}) async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    if (refresh) {
      currentPage.value = 1;
      quizzes.clear();
      hasMore.value = true;
    }

    try {
      final response = await _quizApiService.getQuizzes(
        page: currentPage.value,
        search: searchQuery.value,
        courseId: courseIdFilter.value,
        semesterId: semesterIdFilter.value,
        status: statusFilter.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      if (refresh) {
        quizzes.assignAll(response.data.quizzes);
      } else {
        quizzes.addAll(response.data.quizzes);
      }

      hasMore.value = currentPage.value < response.data.pagination.pages;
      currentPage.value++;
    } catch (e) {
      errorMessage.value = 'Failed to load quizzes: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreQuizzes() async {
    if (!hasMore.value || isLoading.value) return;
    await loadQuizzes();
  }

  void searchQuizzes(String query) {
    searchQuery.value = query;
    loadQuizzes(refresh: true);
  }

  void filterByCourse(String courseId) {
    courseIdFilter.value = courseId;
    loadQuizzes(refresh: true);
  }

  void filterBySemester(String semesterId) {
    semesterIdFilter.value = semesterId;
    loadQuizzes(refresh: true);
  }

  void filterByStatus(String status) {
    statusFilter.value = status;
    loadQuizzes(refresh: true);
  }

  void sortQuizzes(String newSortBy, String newSortOrder) {
    sortBy.value = newSortBy;
    sortOrder.value = newSortOrder;
    loadQuizzes(refresh: true);
  }

  Future<Quiz?> getQuizById(String quizId) async {
    try {
      // Clear cache for this quiz to ensure fresh data with questions
      await DioClient.clearCache('/quizzes/$quizId', null);

      final response = await _quizApiService.getQuizById(quizId);
      currentQuiz.value = response.data;

      debugPrint('✅ Quiz loaded: ${response.data.title}');
      debugPrint('📝 Questions count: ${response.data.questions?.length ?? 0}');
      if (response.data.questions != null &&
          response.data.questions!.isNotEmpty) {
        debugPrint(
            '📋 First question: ${response.data.questions!.first.questionText}');
        debugPrint(
            '🔢 First question options: ${response.data.questions!.first.options?.length ?? 0}');
      }

      return response.data;
    } catch (e) {
      errorMessage.value = 'Failed to get quiz details: $e';
      Get.snackbar('Error', errorMessage.value);
      debugPrint('❌ Error loading quiz: $e');
      return null;
    }
  }

  Future<void> loadQuizDetails(String quizId) async {
    await getQuizById(quizId);
  }

  Future<bool> createQuiz(QuizCreateRequest request) async {
    try {
      isLoading.value = true;
      final response = await _quizApiService.createQuiz(request);
      if (response.success) {
        quizzes.insert(0, response.data.quiz);
        Get.snackbar('Success', response.message);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to create quiz');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to create quiz: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateQuiz(QuizUpdateRequest request) async {
    try {
      isLoading.value = true;
      final response = await _quizApiService.updateQuiz(request.id, request);
      if (response.success) {
        final index = quizzes.indexWhere((q) => q.id == request.id);
        if (index != -1) {
          quizzes[index] = response.data;
        }
        Get.snackbar('Success', 'Quiz updated successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update quiz');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update quiz: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      isLoading.value = true;
      await _quizApiService.deleteQuiz(quizId);
      quizzes.removeWhere((q) => q.id == quizId);
      Get.snackbar('Success', 'Quiz deleted successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete quiz: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Question management methods
  Future<bool> addQuestion(String quizId, QuestionCreateRequest request) async {
    try {
      isLoading.value = true;
      final response = await _quizApiService.addQuestion(quizId, request);
      if (response.success) {
        // TODO: Update quiz questions list reactively
        Get.snackbar('Success', 'Question added successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to add question');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to add question: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateQuestion(
      String quizId, String questionId, QuestionUpdateRequest request) async {
    try {
      isLoading.value = true;
      final response =
          await _quizApiService.updateQuestion(quizId, questionId, request);
      if (response.success) {
        // TODO: Update quiz questions list reactively
        Get.snackbar('Success', 'Question updated successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update question');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update question: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteQuestion(String quizId, String questionId) async {
    try {
      isLoading.value = true;
      await _quizApiService.deleteQuestion(quizId, questionId);
      // TODO: Update quiz questions list reactively
      Get.snackbar('Success', 'Question deleted successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete question: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load quiz submissions
  Future<void> loadQuizSubmissions(
    String quizId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'submitted_at',
    String sortOrder = 'desc',
    String? groupId,
    String attemptFilter = 'all',
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Don't pass groupId to API - we'll filter locally
      final response = await _quizApiService.getQuizSubmissions(
        quizId,
        page: page,
        limit: limit,
        search: search,
        status: status,
        sortBy: sortBy,
        sortOrder: sortOrder,
        groupId: '', // Always fetch all groups
        attemptFilter: attemptFilter,
      );

      final sortedSubmissions = List<SubmissionTrackingData>.from(
        response.data.submissions,
      )..sort((a, b) {
          final aHasSubmitted = a.status != SubmissionStatus.notSubmitted;
          final bHasSubmitted = b.status != SubmissionStatus.notSubmitted;

          if (aHasSubmitted && !bHasSubmitted) return -1;
          if (!aHasSubmitted && bHasSubmitted) return 1;

          if (aHasSubmitted && bHasSubmitted) {
            final aTime = a.latestSubmission?.submittedAt;
            final bTime = b.latestSubmission?.submittedAt;
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime);
            }
            if (aTime != null) return -1;
            if (bTime != null) return 1;
          }

          return a.fullName.compareTo(b.fullName);
        });

      _allSubmissions.assignAll(sortedSubmissions);
      submissions.assignAll(sortedSubmissions);
    } catch (e) {
      errorMessage.value = 'Failed to load quiz submissions: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // Student Quiz State
  final RxMap<String, dynamic> studentAnswers = <String, dynamic>{}.obs;
  final RxBool isSubmittingQuiz = false.obs;
  final Rx<QuizSubmissionDetail?> currentSubmission =
      Rx<QuizSubmissionDetail?>(null);

  // Update student answer
  void updateStudentAnswer(String questionId, dynamic answer) {
    studentAnswers[questionId] = answer;
  }

  // Clear student answers
  void clearStudentAnswers() {
    studentAnswers.clear();
  }

  // Submit quiz
  Future<bool> submitQuiz(
      String quizId, List<Map<String, dynamic>> answers) async {
    isSubmittingQuiz.value = true;
    errorMessage.value = '';

    try {
      final answerRequests = answers.map((a) {
        return QuizAnswerRequest(
          questionId: a['questionId'] as String,
          answerText: a['answerText'] as String?,
          selectedOptionId: a['selectedOptionId'] as String?,
        );
      }).toList();

      final request = QuizSubmissionRequest(answers: answerRequests);
      final response = await _quizApiService.submitQuiz(quizId, request);

      if (response.success) {
        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        clearStudentAnswers();
        return true;
      } else {
        errorMessage.value = response.message;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to submit quiz: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isSubmittingQuiz.value = false;
    }
  }

  // Student submissions state
  final Rx<StudentQuizSubmissionsData?> studentSubmissionsData =
      Rx<StudentQuizSubmissionsData?>(null);

  // Load student's submissions for a quiz
  Future<void> loadStudentQuizSubmissions(String quizId) async {
    try {
      final response = await _quizApiService.getStudentQuizSubmissions(quizId);
      if (response.success) {
        studentSubmissionsData.value = response.data;
      }
    } catch (e) {
      debugPrint('Failed to load student quiz submissions: $e');
    }
  }

  // Load quiz submission detail
  Future<void> loadQuizSubmissionDetail(String submissionId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      debugPrint('📥 Loading quiz submission detail: $submissionId');
      final response =
          await _quizApiService.getQuizSubmissionById(submissionId);
      debugPrint('✅ Response received: success=${response.success}');

      if (response.success) {
        debugPrint(
            '📋 Submission data: id=${response.data.id}, quizId=${response.data.quizId}');
        debugPrint('📝 Answers count: ${response.data.answers.length}');
        currentSubmission.value = response.data;
        debugPrint('✅ Submission loaded successfully');
      } else {
        errorMessage.value = 'Failed to load submission details';
        debugPrint('❌ Response success is false');
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Failed to load submission details: $e';
      debugPrint('❌ Error loading submission detail: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar('Error', errorMessage.value);
      currentSubmission.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  // Review essay answer
  Future<bool> reviewAnswer(
    String submissionId,
    String answerId,
    String action, {
    double? manualScore,
  }) async {
    try {
      debugPrint('📝 Reviewing answer: $answerId with action: $action');

      final reviewData = {
        'action': action,
        if (manualScore != null) 'manualScore': manualScore,
      };

      final response = await _quizApiService.reviewAnswer(
        submissionId,
        answerId,
        reviewData,
      );

      if (response.success) {
        debugPrint('✅ Answer reviewed successfully');
        Get.snackbar(
          'Success',
          'Answer ${action == 'approve' ? 'approved' : 'rejected'} successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          colorText: Colors.white,
        );

        // Reload submission detail to get updated data
        await loadQuizSubmissionDetail(submissionId);
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to review answer';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to review answer: $e';
      debugPrint('❌ Error reviewing answer: $e');
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Complete grading for a submission
  Future<bool> completeGrading(String submissionId) async {
    try {
      debugPrint('✅ Completing grading for submission: $submissionId');

      final response = await _quizApiService.completeGrading(submissionId);

      if (response.success) {
        debugPrint('✅ Grading completed successfully');
        Get.snackbar(
          'Success',
          'Grading completed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reload submission detail to get updated data
        await loadQuizSubmissionDetail(submissionId);
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to complete grading';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to complete grading: $e';
      debugPrint('❌ Error completing grading: $e');
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Check if all essay questions have been reviewed
  bool get hasAllEssaysReviewed {
    if (currentSubmission.value == null) return false;

    final essayAnswers = currentSubmission.value!.answers
        .where((a) => a.question?.questionType == 'essay')
        .toList();

    if (essayAnswers.isEmpty) return true;

    return essayAnswers.every((a) =>
      a.reviewStatus != null && a.reviewStatus != 'pending'
    );
  }

  // Check if submission has essay questions
  bool get hasEssayQuestions {
    if (currentSubmission.value == null) return false;

    return currentSubmission.value!.answers
        .any((a) => a.question?.questionType == 'essay');
  }
}
