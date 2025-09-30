import 'dart:convert';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import '../../../data/services/quiz_api_service.dart';
import '../../../data/services/gemini_service.dart'; // Import GeminiService

class QuizController extends GetxController {
  final QuizApiService _quizApiService;
  late final GeminiService _geminiService; // Instantiate GeminiService

  QuizController(this._quizApiService);

  final RxList<Quiz> quizzes = <Quiz>[].obs;
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
      print('Failed to generate quiz questions: $e');
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
      final response = await _quizApiService.getQuizById(quizId);
      return response.data;
    } catch (e) {
      errorMessage.value = 'Failed to get quiz details: $e';
      Get.snackbar('Error', errorMessage.value);
      return null;
    }
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
}
