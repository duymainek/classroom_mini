import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/quiz_model.dart';

class QuestionFormDialog extends StatefulWidget {
  final QuizQuestion? question;
  final Function(QuestionFormData) onSubmit;

  const QuestionFormDialog({Key? key, this.question, required this.onSubmit}) : super(key: key);

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  String _questionType = 'text'; // Default to text answer
  int _points = 1;
  bool _isRequired = true;
  List<QuestionOptionFormData> _options = [];

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionTextController.text = widget.question!.questionText;
      _questionType = widget.question!.questionType;
      _points = widget.question!.points;
      _isRequired = widget.question!.isRequired;
      if (widget.question!.options != null) {
        _options = widget.question!.options!
            .map((opt) => QuestionOptionFormData(optionText: opt.optionText, isCorrect: opt.isCorrect))
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(QuestionOptionFormData(optionText: '', isCorrect: false));
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = QuestionFormData(
        questionText: _questionTextController.text,
        questionType: _questionType,
        points: _points,
        isRequired: _isRequired,
        options: _questionType == 'multiple_choice' ? _options : null,
      );
      widget.onSubmit(formData);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionTextController,
                decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Question text is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text Answer')),
                  DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                ],
                onChanged: (value) {
                  setState(() {
                    _questionType = value!;
                    if (_questionType == 'multiple_choice' && _options.isEmpty) {
                      _addOption(); // Add at least one option for multiple choice
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _points.toString(),
                decoration: const InputDecoration(labelText: 'Points', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null || int.parse(value) <= 0 ? 'Enter a valid number' : null,
                onChanged: (value) => _points = int.tryParse(value) ?? 1,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Required'),
                value: _isRequired,
                onChanged: (value) => setState(() => _isRequired = value),
              ),
              if (_questionType == 'multiple_choice') ...[
                const SizedBox(height: 24),
                Text('Options', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _options[index].optionText,
                              decoration: InputDecoration(labelText: 'Option ${index + 1}', border: const OutlineInputBorder()),
                              validator: (value) => value == null || value.isEmpty ? 'Option text is required' : null,
                              onChanged: (value) => _options[index].optionText = value,
                            ),
                          ),
                          Checkbox(
                            value: _options[index].isCorrect,
                            onChanged: (value) {
                              setState(() {
                                _options[index].isCorrect = value!;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeOption(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submitForm, child: const Text('Save')),
      ],
    );
  }
}

class QuestionFormData {
  final String questionText;
  final String questionType;
  final int points;
  final bool isRequired;
  final List<QuestionOptionFormData>? options;

  QuestionFormData({
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.isRequired,
    this.options,
  });
}

class QuestionOptionFormData {
  String optionText;
  bool isCorrect;

  QuestionOptionFormData({
    required this.optionText,
    required this.isCorrect,
  });
}
