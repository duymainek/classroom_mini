import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../views/shared/quiz_form.dart';

class QuizDetailView extends StatefulWidget {
  final String quizId;
  const QuizDetailView({Key? key, required this.quizId}) : super(key: key);

  @override
  State<QuizDetailView> createState() => _QuizDetailViewState();
}

class _QuizDetailViewState extends State<QuizDetailView> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Quiz?>(
        future: Get.find<QuizController>().getQuizById(widget.quizId),
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
            onlyView: !_isUpdating,
            isUpdating: _isUpdating,
            appBarActions: _isUpdating
                ? [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _isUpdating = false),
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(() => _isUpdating = true),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteDialog(context, widget.quizId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Quiz'),
                        ),
                      ],
                    ),
                  ],
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
              final success =
                  await Get.find<QuizController>().updateQuiz(request);
              if (success) {
                setState(() => _isUpdating = false);
                Get.snackbar('Success', 'Quiz updated successfully');
              }
            },
            onCancel: () => setState(() => _isUpdating = false),
            isLoading: Get.find<QuizController>().isLoading.value,
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String quizId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.find<QuizController>().deleteQuiz(quizId);
              Get.back();
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
