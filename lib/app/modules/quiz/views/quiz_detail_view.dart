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
