import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../views/shared/quiz_form.dart';

class QuizEditView extends GetView<QuizController> {
  final String quizId;
  const QuizEditView({Key? key, required this.quizId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Quiz?>(
        future: controller.getQuizById(quizId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Quiz not found'));
          }
          final quiz = snapshot.data!;
          return QuizForm(
            quiz: quiz,
            onlyView: false,
            isUpdating: true,
            onSubmit: (formData) async {
              final request = QuizUpdateRequest(
                id: quiz.id,
                title: formData.title,
                description: formData.description,
                courseId: formData.courseId,
                startDate: formData.startDate,
                dueDate: formData.dueDate,
                lateDueDate: formData.lateDueDate,
                allowLateSubmission: formData.allowLateSubmission,
                maxAttempts: formData.maxAttempts,
                timeLimit: formData.timeLimit,
                shuffleQuestions: formData.shuffleQuestions,
                shuffleOptions: formData.shuffleOptions,
                showCorrectAnswers: formData.showCorrectAnswers,
                groupIds: formData.groupIds,
              );
              final success = await controller.updateQuiz(request);
              if (success) {
                Get.back();
              }
            },
            onCancel: () => Get.back(),
            isLoading: controller.isLoading.value,
          );
        },
      ),
    );
  }
}
