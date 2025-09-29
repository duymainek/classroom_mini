import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quiz_controller.dart';
import '../../../data/models/quiz_model.dart';
import '../../../routes/app_routes.dart';
import '../views/shared/question_form_dialog.dart';

class QuizDetailView extends GetView<QuizController> {
  final String quizId;
  const QuizDetailView({Key? key, required this.quizId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Quiz?>(
          future: controller.getQuizById(quizId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Text('Quiz Details');
            }
            return Text(snapshot.data!.title);
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.toNamed(Routes.QUIZZES_EDIT, arguments: quizId),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, quizId);
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
      ),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(context, quiz),
                const SizedBox(height: 24),
                _buildQuestionsCard(context, quiz),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (quiz.description != null && quiz.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(quiz.description!),
              ),
            const Divider(height: 24),
            _buildInfoRow(context, Icons.book, 'Course', quiz.course?.name ?? 'N/A'),
            _buildInfoRow(context, Icons.calendar_today, 'Start Date', DateFormat('yyyy-MM-dd HH:mm').format(quiz.startDate)),
            _buildInfoRow(context, Icons.calendar_today, 'Due Date', DateFormat('yyyy-MM-dd HH:mm').format(quiz.dueDate)),
            if (quiz.allowLateSubmission && quiz.lateDueDate != null)
              _buildInfoRow(context, Icons.calendar_today, 'Late Due Date', DateFormat('yyyy-MM-dd HH:mm').format(quiz.lateDueDate!)),
            _buildInfoRow(context, Icons.timer, 'Time Limit', quiz.timeLimit != null ? '${quiz.timeLimit} minutes' : 'No limit'),
            _buildInfoRow(context, Icons.repeat, 'Max Attempts', quiz.maxAttempts.toString()),
            _buildInfoRow(context, Icons.shuffle, 'Shuffle Questions', quiz.shuffleQuestions ? 'Yes' : 'No'),
            _buildInfoRow(context, Icons.shuffle_on, 'Shuffle Options', quiz.shuffleOptions ? 'Yes' : 'No'),
            _buildInfoRow(context, Icons.check_circle_outline, 'Show Correct Answers', quiz.showCorrectAnswers ? 'Yes' : 'No'),
            _buildInfoRow(context, Icons.group, 'Assigned Groups', quiz.quizGroups?.map((qg) => qg.groups?.name ?? '').join(', ') ?? 'None'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text('$label:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            if (quiz.questions == null || quiz.questions!.isEmpty)
              const Center(child: Text('No questions added yet.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quiz.questions!.length,
                itemBuilder: (context, index) {
                  final question = quiz.questions![index];
                  return QuestionTile(
                    question: question,
                    onEdit: () => _showQuestionFormDialog(context, quiz.id, question: question),
                    onDelete: () => _showDeleteQuestionDialog(context, quiz.id, question.id),
                  );
                },
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showQuestionFormDialog(context, quiz.id),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionFormDialog(BuildContext context, String quizId, {QuizQuestion? question}) {
    Get.dialog(
      QuestionFormDialog(
        question: question,
        onSubmit: (formData) async {
          final request = QuestionCreateRequest(
            questionText: formData.questionText,
            questionType: formData.questionType,
            points: formData.points,
            isRequired: formData.isRequired,
            options: formData.options?.map((opt) => QuestionOptionCreateRequest(
              optionText: opt.optionText,
              isCorrect: opt.isCorrect,
            )).toList(),
          );
          if (question == null) {
            await Get.find<QuizController>().addQuestion(quizId, request);
          } else {
            final updateRequest = QuestionUpdateRequest(
              id: question.id,
              questionText: formData.questionText,
              questionType: formData.questionType,
              points: formData.points,
              isRequired: formData.isRequired,
              options: formData.options?.map((opt) => QuestionOptionCreateRequest(
                optionText: opt.optionText,
                isCorrect: opt.isCorrect,
              )).toList(),
            );
            await Get.find<QuizController>().updateQuestion(quizId, question.id, updateRequest);
          }
          // Refresh quiz details after adding/updating question
          Get.find<QuizController>().getQuizById(quizId); // This will trigger a rebuild of FutureBuilder
        },
      ),
    );
  }

  void _showDeleteQuestionDialog(BuildContext context, String quizId, String questionId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.find<QuizController>().deleteQuestion(quizId, questionId);
              Get.back();
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
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

class QuestionTile extends StatelessWidget {
  final QuizQuestion question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuestionTile({Key? key, required this.question, this.onEdit, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(question.questionText, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('Type: ${question.questionType} | Points: ${question.points}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
        children: [
          if (question.questionType == 'multiple_choice' && question.options != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: question.options!.map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(option.isCorrect ? Icons.check_circle : Icons.radio_button_off,
                          color: option.isCorrect ? Colors.green : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option.optionText)),
                    ],
                  ),
                )).toList(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No options for this question type.'),
            ),
        ],
      ),
    );
  }
}