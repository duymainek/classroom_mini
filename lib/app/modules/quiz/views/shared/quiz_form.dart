import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/services/metadata_service.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';
import 'package:classroom_mini/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'quiz_form_edit_dialog.dart';
import 'quiz_add_question_dialog.dart';
import 'package:classroom_mini/app/core/widgets/responsive_container.dart';

class QuizForm extends StatefulWidget {
  final Quiz? quiz;
  final Function(QuizFormData) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool onlyView;
  final bool isUpdating;
  final List<Widget>? appBarActions;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const QuizForm({
    super.key,
    this.quiz,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.onlyView = false,
    this.isUpdating = false,
    this.appBarActions,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  State<QuizForm> createState() => _QuizFormState();
}

class _QuizFormState extends State<QuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final QuizController controller;
  late final MetadataService _metadataService;
  late final ConnectivityService _connectivityService;

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

  // Generated questions from Gemini
  List<QuestionCreateRequest> _generatedQuestions = [];

  @override
  void initState() {
    super.initState();
    controller = Get.find<QuizController>();
    _metadataService = Get.find<MetadataService>();
    _connectivityService = Get.find<ConnectivityService>();
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
      _selectedGroupIds = (quiz.quizGroups
              ?.map((qg) => qg.groupId)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList()) ??
          [];

      // If viewing an existing quiz, pre-populate the local questions list
      // so the Questions section can render them in view-only mode.
      if (quiz.questions != null && quiz.questions!.isNotEmpty) {
        _generatedQuestions = quiz.questions!
            .map(
              (q) => QuestionCreateRequest(
                questionText: q.questionText,
                questionType: q.questionType,
                points: q.points,
                orderIndex: q.orderIndex,
                isRequired: q.isRequired,
                options: q.options
                    ?.map(
                      (o) => QuestionOptionCreateRequest(
                        optionText: o.optionText,
                        isCorrect: o.isCorrect,
                        orderIndex: o.orderIndex,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
      }
    }
  }

  Future<void> _loadMetaData() async {
    setState(() => _isMetaDataLoading = true);
    try {
      // Sử dụng MetadataService thay vì AssignmentController
      final metadata = await _metadataService.loadFormMetadata(
        selectedCourseId: _selectedCourseId,
      );

      _availableCourses = metadata['courses'] as List<CourseInfo>;
      _availableGroups = metadata['groups'] as List<GroupInfo>;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Failed to load metadata: $e');
      });
    } finally {
      setState(() => _isMetaDataLoading = false);
    }
  }

  Future<void> _loadGroupsForCourse(String courseId) async {
    try {
      final groups = await _metadataService.loadGroupsForCourse(courseId);
      setState(() {
        _availableGroups = groups;
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Failed to load groups: $e');
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditable => !widget.onlyView || widget.isUpdating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ResponsiveContainer(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
              actions: widget.appBarActions,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.onlyView
                      ? 'Quiz Details'
                      : widget.quiz != null
                          ? 'Edit Quiz'
                          : 'Create Quiz',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                        colorScheme.secondaryContainer.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Form Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Basic Information Section
                  _buildModernSection(
                    context,
                    title: 'Basic Information',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _buildModernTextField(
                        controller: _titleController,
                        label: 'Quiz Title',
                        hint: 'Enter a descriptive title for your quiz',
                        validator: (value) =>
                            value?.isEmpty == true ? 'Title is required' : null,
                        prefixIcon: Icons.quiz_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint:
                            'Provide additional details about this quiz (optional)',
                        maxLines: 3,
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildModernCourseDropdown(context),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timing & Attempts Section
                  _buildModernSection(
                    context,
                    title: 'Timing & Attempts',
                    icon: Icons.schedule_rounded,
                    children: [
                      _buildModernDatePickers(context),
                      const SizedBox(height: 16),
                      _buildModernSwitchTile(
                        context,
                        title: 'Allow Late Submission',
                        subtitle: 'Students can submit after the due date',
                        value: _allowLateSubmission,
                        onChanged: (value) =>
                            setState(() => _allowLateSubmission = value),
                        icon: Icons.schedule_send_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              initialValue: _maxAttempts.toString(),
                              label: 'Max Attempts',
                              hint: 'Number of attempts allowed',
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null ||
                                      int.tryParse(value) == null ||
                                      int.parse(value) <= 0
                                  ? 'Enter a valid number'
                                  : null,
                              onChanged: (value) =>
                                  _maxAttempts = int.tryParse(value) ?? 1,
                              prefixIcon: Icons.repeat_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTextField(
                              initialValue: _timeLimit?.toString(),
                              label: 'Time Limit (minutes)',
                              hint: 'Optional time limit',
                              keyboardType: TextInputType.number,
                              validator: (value) => value != null &&
                                      value.isNotEmpty &&
                                      (int.tryParse(value) == null ||
                                          int.parse(value) <= 0)
                                  ? 'Enter a valid number or leave empty'
                                  : null,
                              onChanged: (value) =>
                                  _timeLimit = int.tryParse(value),
                              prefixIcon: Icons.timer_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Settings Section
                  _buildModernSection(
                    context,
                    title: 'Quiz Settings',
                    icon: Icons.settings_rounded,
                    children: [
                      _buildModernSwitchTile(
                        context,
                        title: 'Shuffle Questions',
                        subtitle: 'Randomize question order for each student',
                        value: _shuffleQuestions,
                        onChanged: (value) =>
                            setState(() => _shuffleQuestions = value),
                        icon: Icons.shuffle_rounded,
                      ),
                      _buildModernSwitchTile(
                        context,
                        title: 'Shuffle Options',
                        subtitle: 'Randomize answer options order',
                        value: _shuffleOptions,
                        onChanged: (value) =>
                            setState(() => _shuffleOptions = value),
                        icon: Icons.swap_vert_rounded,
                      ),
                      _buildModernSwitchTile(
                        context,
                        title: 'Show Correct Answers',
                        subtitle: 'Display correct answers after submission',
                        value: _showCorrectAnswers,
                        onChanged: (value) =>
                            setState(() => _showCorrectAnswers = value),
                        icon: Icons.visibility_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Group Assignment Section
                  _buildModernSection(
                    context,
                    title: 'Assign to Groups',
                    icon: Icons.groups_rounded,
                    children: [
                      _buildModernGroupSelection(context),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Questions Section
                  _buildModernQuestionsSection(context),

                  const SizedBox(height: 32),

                  // Bottom Action Buttons
                  _buildBottomActionButtons(context),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuestionDialog(BuildContext context) {
    Get.dialog(
      QuizAddQuestionDialog(
        onAdd: (newQuestion) {
          setState(() {
            // Set order index based on current questions count
            final questionWithOrder = QuestionCreateRequest(
              questionText: newQuestion.questionText,
              questionType: newQuestion.questionType,
              points: newQuestion.points,
              orderIndex: _generatedQuestions.length,
              isRequired: newQuestion.isRequired,
              options: newQuestion.options,
            );
            _generatedQuestions.add(questionWithOrder);
          });
        },
      ),
    );
  }

  void _showEditQuestionDialog(BuildContext context, int questionIndex) {
    final question = _generatedQuestions[questionIndex];

    Get.dialog(
      QuizEditQuestionDialog(
        questionIndex: questionIndex,
        question: question,
        onSave: (updatedQuestion) {
          setState(() {
            _generatedQuestions[questionIndex] = updatedQuestion;
          });
        },
      ),
    );
  }

  void _showGeminiGenerationDialog(BuildContext context) {
    final TextEditingController promptController = TextEditingController();
    final TextEditingController numQuestionsController =
        TextEditingController(text: '5');

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
                        final numQuestions =
                            int.tryParse(numQuestionsController.text.trim()) ??
                                0;

                        if (prompt.isEmpty || numQuestions <= 0) {
                          Get.snackbar('Error',
                              'Please provide a valid description and number of questions.');
                          return;
                        }

                        Get.back(); // Close dialog
                        final generatedQuestions =
                            await controller.generateQuizQuestionsFromGemini(
                                prompt, numQuestions);
                        if (generatedQuestions != null) {
                          setState(() {
                            _generatedQuestions.addAll(generatedQuestions);
                          });
                          Get.snackbar('Success',
                              'Generated ${generatedQuestions.length} questions.');
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

  Widget _buildModernSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      enabled: _isEditable,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildModernSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isEditable
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : value
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditable
              ? colorScheme.outline.withValues(alpha: 0.2)
              : value
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _isEditable ? null : (value ? colorScheme.primary : null),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _isEditable
                ? colorScheme.onSurfaceVariant
                : (value ? colorScheme.primary : colorScheme.onSurfaceVariant),
          ),
        ),
        value: value,
        onChanged: _isEditable ? onChanged : null,
        secondary: Icon(
          icon,
          color: _isEditable
              ? colorScheme.primary
              : (value ? colorScheme.primary : colorScheme.onSurfaceVariant),
        ),
        activeThumbColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildModernQuestionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header với Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Questions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                // Action Buttons trong Header - chỉ hiển thị khi có thể edit
                if (_isEditable)
                  Obx(() {
                    if (!_connectivityService.isOnline.value) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      children: [
                        // Add Question Button
                        IconButton(
                          onPressed: () => _showAddQuestionDialog(context),
                          icon: Icon(
                            Icons.add_rounded,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Add Question',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Generate with AI Button
                        Obx(() => IconButton(
                              onPressed: controller.isGeneratingQuiz
                                  ? null
                                  : () => _showGeminiGenerationDialog(context),
                              icon: controller.isGeneratingQuiz
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.auto_awesome_rounded,
                                      color: colorScheme.secondary,
                                    ),
                              tooltip: 'Generate with AI',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.secondary
                                    .withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )),
                      ],
                    );
                  }),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_generatedQuestions.isNotEmpty) ...[
                  _buildModernQuestionsList(context),
                ] else ...[
                  // Empty State
                  _buildQuestionsEmptyState(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add questions manually or generate them with AI',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context) {
    // Chỉ hiển thị action buttons khi không ở chế độ onlyView
    if (widget.onlyView && !widget.isUpdating) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onCancel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: widget.isLoading ? null : _submitForm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.quiz != null ? 'Update Quiz' : 'Create Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCourseDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: _selectedCourseId,
      onChanged: _isEditable
          ? (value) async {
              setState(() {
                _selectedCourseId = value;
                _selectedGroupIds.clear(); // Clear groups when course changes
              });

              // Load groups for the new course
              if (value != null && value.isNotEmpty) {
                await _loadGroupsForCourse(value);
              }
            }
          : null,
      decoration: InputDecoration(
        labelText: 'Course',
        hintText: 'Select a course for this quiz',
        prefixIcon: const Icon(Icons.school_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      items: _availableCourses
          .map((course) => DropdownMenuItem(
                value: course.id,
                child: Text(
                  course.name,
                  style: theme.textTheme.bodyLarge,
                ),
              ))
          .toList(),
      validator: (value) =>
          value == null || value.isEmpty ? 'Course is required' : null,
    );
  }

  Widget _buildModernDatePickers(BuildContext context) {
    return Column(
      children: [
        _buildModernDateTile(
          context,
          title: 'Start Date',
          subtitle: _startDate == null
              ? 'Select when the quiz becomes available'
              : DateFormat('MMM dd, yyyy • HH:mm').format(_startDate!),
          value: _startDate,
          onTap: () => _selectDateTime(
              context, _startDate, (date) => setState(() => _startDate = date)),
          icon: Icons.play_circle_outline,
        ),
        const SizedBox(height: 12),
        _buildModernDateTile(
          context,
          title: 'Due Date',
          subtitle: _dueDate == null
              ? 'Select when the quiz closes'
              : DateFormat('MMM dd, yyyy • HH:mm').format(_dueDate!),
          value: _dueDate,
          onTap: () => _selectDateTime(
              context, _dueDate, (date) => setState(() => _dueDate = date)),
          icon: Icons.stop_circle,
        ),
        if (_allowLateSubmission) ...[
          const SizedBox(height: 12),
          _buildModernDateTile(
            context,
            title: 'Late Due Date',
            subtitle: _lateDueDate == null
                ? 'Select the final deadline for late submissions'
                : DateFormat('MMM dd, yyyy • HH:mm').format(_lateDueDate!),
            value: _lateDueDate,
            onTap: () => _selectDateTime(context, _lateDueDate,
                (date) => setState(() => _lateDueDate = date)),
            icon: Icons.schedule_send_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildModernDateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.calendar_today_outlined,
          color: colorScheme.primary,
        ),
        onTap: _isEditable ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, DateTime? initialDate,
      Function(DateTime) onSelected) async {
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

  Widget _buildModernGroupSelection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isMetaDataLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading groups...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_availableGroups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditable ? 'No groups available' : 'No groups assigned',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isEditable
                  ? 'No groups are available for the selected course.'
                  : 'This quiz is not assigned to any groups.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditable
              ? 'Select groups to assign this quiz to:'
              : 'Assigned groups:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _availableGroups.map((group) {
            final isSelected = _selectedGroupIds.contains(group.id);
            return FilterChip(
              label: Text(group.name),
              selected: isSelected,
              onSelected: _isEditable
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          if (!_selectedGroupIds.contains(group.id)) {
                            _selectedGroupIds.add(group.id);
                          }
                        } else {
                          _selectedGroupIds.remove(group.id);
                        }
                      });
                    }
                  : null,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        if (_selectedGroupIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditable
                      ? '${_selectedGroupIds.length} group${_selectedGroupIds.length > 1 ? 's' : ''} selected'
                      : '${_selectedGroupIds.length} group${_selectedGroupIds.length > 1 ? 's' : ''} assigned',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernQuestionsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz_outlined,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${_generatedQuestions.length} question${_generatedQuestions.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_generatedQuestions.length, (index) {
          final question = _generatedQuestions[index];
          return _buildModernQuestionCard(context, question, index);
        }),
      ],
    );
  }

  Widget _buildModernQuestionCard(
      BuildContext context, QuestionCreateRequest question, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final isOnline = _connectivityService.isOnline.value;
      final canEdit = _isEditable && isOnline;

      return Dismissible(
        key: Key('question_${question.questionText}_$index'),
        direction:
            canEdit ? DismissDirection.endToStart : DismissDirection.none,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Swipe to delete',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await Get.dialog<bool>(
                AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('Delete Question'),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to delete this question? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (direction) {
          setState(() {
            _generatedQuestions.removeAt(index);
          });
          Get.snackbar(
            'Deleted',
            'Question removed successfully',
            backgroundColor: colorScheme.surface,
            colorText: colorScheme.onSurface,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.questionText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: () =>
                            _showEditQuestionDialog(context, index),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Edit question',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                ),
              ),

              // Question Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: question.questionType == 'multiple_choice'
                            ? colorScheme.primaryContainer
                                .withValues(alpha: 0.5)
                            : colorScheme.secondaryContainer
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.questionType == 'multiple_choice'
                                ? Icons.quiz_outlined
                                : Icons.text_fields_outlined,
                            size: 16,
                            color: question.questionType == 'multiple_choice'
                                ? colorScheme.primary
                                : colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            question.questionType.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: question.questionType == 'multiple_choice'
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Options (if multiple choice)
                    if (question.options?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Answer Options:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...question.options!.asMap().entries.map((entry) {
                        final optionIndex = entry.key;
                        final option = entry.value;
                        return _buildModernOptionTile(
                          context,
                          option: option,
                          optionIndex: optionIndex,
                          isCorrect: option.isCorrect,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildModernOptionTile(
    BuildContext context, {
    required dynamic option,
    required int optionIndex,
    required bool isCorrect,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: isCorrect
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isCorrect ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + optionIndex), // A, B, C, D
                style: TextStyle(
                  color: isCorrect
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              option.optionText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCorrect
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = QuizFormData(
        id: widget.quiz?.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
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
        questions: _generatedQuestions.isNotEmpty ? _generatedQuestions : null,
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
  final List<QuestionCreateRequest>? questions;
  final String? id;

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
    this.questions,
    this.id,
  });
}
