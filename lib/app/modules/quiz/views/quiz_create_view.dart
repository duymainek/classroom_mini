import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../views/shared/quiz_form.dart';

class QuizCreateView extends GetView<QuizController> {
  const QuizCreateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QuizForm(
        onlyView: false,
        isUpdating: false,
        onSubmit: (formData) async {
          final request = QuizCreateRequest(
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
            questions: formData.questions,
          );
          final success = await controller.createQuiz(request);
          if (success) {
            Navigator.of(context).pop(true);
          }
        },
        onCancel: () => Get.back(),
        isLoading: controller.isLoading.value,
      ),
    );
  }
}
