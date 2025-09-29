import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/assignment_model.dart'; // For CourseInfo and GroupInfo
import '../../core_management/controllers/core_management_controller.dart'; // For fetching courses/groups
import '../../assignments/controllers/assignment_controller.dart'; // For fetching courses/groups

class QuizForm extends StatefulWidget {
  final Quiz? quiz;
  final Function(QuizFormData) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const QuizForm({
    Key? key,
    this.quiz,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<QuizForm> createState() => _QuizFormState();
}

class _QuizFormState extends State<QuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCourseId;
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _lateDueDate;
  bool _allowLateSubmission = false;
  int _maxAttempts = 1;
  int? _timeLimit;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  bool _showCorrectAnswers = false;
  List<String> _selectedGroupIds = [];

  List<CourseInfo> _availableCourses = [];
  List<GroupInfo> _availableGroups = [];
  bool _isMetaDataLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadMetaData();
  }

  void _initializeForm() {
    if (widget.quiz != null) {
      final quiz = widget.quiz!;
      _titleController.text = quiz.title;
      _descriptionController.text = quiz.description ?? '';
      _selectedCourseId = quiz.courseId;
      _startDate = quiz.startDate;
      _dueDate = quiz.dueDate;
      _lateDueDate = quiz.lateDueDate;
      _allowLateSubmission = quiz.allowLateSubmission;
      _maxAttempts = quiz.maxAttempts;
      _timeLimit = quiz.timeLimit;
      _shuffleQuestions = quiz.shuffleQuestions;
      _shuffleOptions = quiz.shuffleOptions;
      _showCorrectAnswers = quiz.showCorrectAnswers;
      _selectedGroupIds = quiz.quizGroups?.map((qg) => qg.groupId).toList() ?? [];
    }
  }

  Future<void> _loadMetaData() async {
    setState(() => _isMetaDataLoading = true);
    try {
      // Using AssignmentController for course/group fetching as it has the logic
      final assignmentController = Get.find<AssignmentController>();
      await assignmentController.loadCoursesForForm();
      _availableCourses = assignmentController.formState.value.courses;

      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        await assignmentController.loadGroupsForForm(_selectedCourseId!); // Load groups for selected course
        _availableGroups = assignmentController.formState.value.groups;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load metadata: $e');
    } finally {
      setState(() => _isMetaDataLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info
            _buildSectionHeader(context, 'Basic Information', Icons.info_outline),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildCourseDropdown(context),
            const SizedBox(height: 24),

            // Timing & Attempts
            _buildSectionHeader(context, 'Timing & Attempts', Icons.timer),
            const SizedBox(height: 16),
            _buildDatePickers(context),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow Late Submission'),
              value: _allowLateSubmission,
              onChanged: (value) => setState(() => _allowLateSubmission = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _maxAttempts.toString(),
              decoration: const InputDecoration(labelText: 'Max Attempts', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || int.tryParse(value) == null || int.parse(value) <= 0 ? 'Enter a valid number' : null,
              onChanged: (value) => _maxAttempts = int.tryParse(value) ?? 1,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _timeLimit?.toString(),
              decoration: const InputDecoration(labelText: 'Time Limit (minutes)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => value != null && value.isNotEmpty && (int.tryParse(value) == null || int.parse(value) <= 0) ? 'Enter a valid number or leave empty' : null,
              onChanged: (value) => _timeLimit = int.tryParse(value),
            ),
            const SizedBox(height: 24),

            // Settings
            _buildSectionHeader(context, 'Settings', Icons.settings),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Shuffle Questions'),
              value: _shuffleQuestions,
              onChanged: (value) => setState(() => _shuffleQuestions = value),
            ),
            SwitchListTile(
              title: const Text('Shuffle Options'),
              value: _shuffleOptions,
              onChanged: (value) => setState(() => _shuffleOptions = value),
            ),
            SwitchListTile(
              title: const Text('Show Correct Answers'),
              value: _showCorrectAnswers,
              onChanged: (value) => setState(() => _showCorrectAnswers = value),
            ),
            const SizedBox(height: 24),

            // Distribution
            _buildSectionHeader(context, 'Assign to Groups', Icons.group),
            const SizedBox(height: 16),
            _buildGroupSelection(context),
            const SizedBox(height: 24),

            // Question Management (Placeholder for now)
            _buildSectionHeader(context, 'Questions', Icons.help_outline),
            const SizedBox(height: 16),
            // TODO: Implement actual question management UI
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isGeneratingQuiz
                        ? null
                        : () => _showGeminiGenerationDialog(context),
                    icon: controller.isGeneratingQuiz
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Generate Questions with AI'),
                  )),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: widget.isLoading ? null : _submitForm,
                  child: widget.isLoading ? const CircularProgressIndicator() : const Text('Save Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGeminiGenerationDialog(BuildContext context) {
    final TextEditingController promptController = TextEditingController();
    final TextEditingController numQuestionsController = TextEditingController(text: '5');

    Get.dialog(
      AlertDialog(
        title: const Text('Generate Questions with Gemini AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: promptController,
              decoration: const InputDecoration(
                labelText: 'Description for AI',
                hintText: 'e.g., "Questions about Flutter widgets"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: numQuestionsController,
              decoration: const InputDecoration(
                labelText: 'Number of Questions',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isGeneratingQuiz
                    ? null
                    : () async {
                        final prompt = promptController.text.trim();
                        final numQuestions = int.tryParse(numQuestionsController.text.trim()) ?? 0;

                        if (prompt.isEmpty || numQuestions <= 0) {
                          Get.snackbar('Error', 'Please provide a valid description and number of questions.');
                          return;
                        }

                        Get.back(); // Close dialog
                        final generatedQuestions = await controller.generateQuizQuestionsFromGemini(prompt, numQuestions);
                        if (generatedQuestions != null) {
                          // TODO: Add generated questions to the form's question list
                          Get.snackbar('Success', 'Generated ${generatedQuestions.length} questions.');
                        }
                      },
                child: controller.isGeneratingQuiz
                    ? const CircularProgressIndicator()
                    : const Text('Generate'),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedCourseId,
      decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
      items: _availableCourses.map((course) => DropdownMenuItem(value: course.id, child: Text(course.name))).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCourseId = value;
          _selectedGroupIds.clear(); // Clear groups when course changes
          // TODO: Reload groups for the new course
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Course is required' : null,
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Start Date'),
          subtitle: Text(_startDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd HH:mm').format(_startDate!)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDateTime(context, _startDate, (date) => setState(() => _startDate = date)),
        ),
        ListTile(
          title: const Text('Due Date'),
          subtitle: Text(_dueDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDateTime(context, _dueDate, (date) => setState(() => _dueDate = date)),
        ),
        if (_allowLateSubmission)
          ListTile(
            title: const Text('Late Due Date'),
            subtitle: Text(_lateDueDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd HH:mm').format(_lateDueDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDateTime(context, _lateDueDate, (date) => setState(() => _lateDueDate = date)),
          ),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context, DateTime? initialDate, Function(DateTime) onSelected) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        onSelected(DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ));
      }
    }
  }

  Widget _buildGroupSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: _availableGroups.map((group) {
            final isSelected = _selectedGroupIds.contains(group.id);
            return FilterChip(
              label: Text(group.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGroupIds.add(group.id);
                  } else {
                    _selectedGroupIds.remove(group.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_availableGroups.isEmpty && !_isMetaDataLoading)
          const Text('No groups available for this course.'),
        if (_isMetaDataLoading)
          const CircularProgressIndicator(),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = QuizFormData(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        courseId: _selectedCourseId!,
        startDate: _startDate!,
        dueDate: _dueDate!,
        lateDueDate: _allowLateSubmission ? _lateDueDate : null,
        allowLateSubmission: _allowLateSubmission,
        maxAttempts: _maxAttempts,
        timeLimit: _timeLimit,
        shuffleQuestions: _shuffleQuestions,
        shuffleOptions: _shuffleOptions,
        showCorrectAnswers: _showCorrectAnswers,
        groupIds: _selectedGroupIds.isEmpty ? null : _selectedGroupIds,
      );
      widget.onSubmit(formData);
    }
  }
}

class QuizFormData {
  final String title;
  final String? description;
  final String courseId;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? lateDueDate;
  final bool allowLateSubmission;
  final int maxAttempts;
  final int? timeLimit;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showCorrectAnswers;
  final List<String>? groupIds;

  QuizFormData({
    required this.title,
    this.description,
    required this.courseId,
    required this.startDate,
    required this.dueDate,
    this.lateDueDate,
    required this.allowLateSubmission,
    required this.maxAttempts,
    this.timeLimit,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.showCorrectAnswers,
    this.groupIds,
  });
}
