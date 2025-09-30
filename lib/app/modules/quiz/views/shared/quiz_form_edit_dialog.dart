import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuizEditQuestionDialog extends StatefulWidget {
  final int questionIndex;
  final QuestionCreateRequest question;
  final Function(QuestionCreateRequest) onSave;

  const QuizEditQuestionDialog({
    Key? key,
    required this.questionIndex,
    required this.question,
    required this.onSave,
  }) : super(key: key);

  @override
  State<QuizEditQuestionDialog> createState() => _QuizEditQuestionDialogState();
}

class _QuizEditQuestionDialogState extends State<QuizEditQuestionDialog> {
  late TextEditingController questionController;
  late TextEditingController pointsController;
  late String selectedType;
  late List<Map<String, dynamic>> options;

  @override
  void initState() {
    super.initState();
    questionController =
        TextEditingController(text: widget.question.questionText);
    pointsController =
        TextEditingController(text: (widget.question.points ?? 1).toString());
    selectedType = widget.question.questionType;
    options = widget.question.options
            ?.map((opt) => {
                  'text': opt.optionText,
                  'isCorrect': opt.isCorrect,
                })
            .toList() ??
        [];
  }

  @override
  void dispose() {
    questionController.dispose();
    pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Question ${widget.questionIndex + 1}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Text
                    Text(
                      'Question Text',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your question here...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),

                    const SizedBox(height: 20),

                    // Question Type and Points
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedType,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'multiple_choice',
                                      child: Text('Multiple Choice')),
                                  DropdownMenuItem(
                                      value: 'text', child: Text('Text')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedType = value!;
                                    if (selectedType == 'text') {
                                      options.clear();
                                    } else if (selectedType ==
                                            'multiple_choice' &&
                                        options.isEmpty) {
                                      options.addAll([
                                        {'text': '', 'isCorrect': false},
                                        {'text': '', 'isCorrect': false},
                                        {'text': '', 'isCorrect': false},
                                        {'text': '', 'isCorrect': false},
                                      ]);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Points',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: pointsController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (selectedType == 'multiple_choice') ...[
                      const SizedBox(height: 20),
                      Text(
                        'Answer Options',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),

                      // Options List
                      ...options.asMap().entries.map((entry) {
                        final optionIndex = entry.key;
                        final option = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: option['isCorrect']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.05),
                            border: Border.all(
                              color: option['isCorrect']
                                  ? Colors.green
                                  : Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: option['isCorrect']
                                          ? Colors.green
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + optionIndex),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: option['text'],
                                      decoration: InputDecoration(
                                        hintText: 'Enter option text...',
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        options[optionIndex]['text'] = value;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        options.removeAt(optionIndex);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    tooltip: 'Remove option',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(
                                    value: option['isCorrect'],
                                    onChanged: (value) {
                                      setState(() {
                                        options[optionIndex]['isCorrect'] =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Correct Answer'),
                                  if (option['isCorrect'])
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final updatedQuestion = QuestionCreateRequest(
                        questionText: questionController.text.trim(),
                        questionType: selectedType,
                        points: int.tryParse(pointsController.text.trim()) ?? 1,
                        orderIndex: widget.question.orderIndex,
                        isRequired: widget.question.isRequired,
                        options: selectedType == 'multiple_choice'
                            ? options
                                .map((opt) => QuestionOptionCreateRequest(
                                      optionText: opt['text'],
                                      isCorrect: opt['isCorrect'],
                                    ))
                                .toList()
                            : null,
                      );

                      widget.onSave(updatedQuestion);
                      Get.back();
                      Get.snackbar('Success', 'Question updated successfully');
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
