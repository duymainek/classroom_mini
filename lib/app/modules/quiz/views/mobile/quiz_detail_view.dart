import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import '../../controllers/quiz_controller.dart';
import 'package:classroom_mini/app/core/app_config.dart';

class MobileQuizDetailView extends StatelessWidget {
  final Quiz quiz;

  const MobileQuizDetailView({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInstructor = AppConfig.instance.isInstructor;

    return GetBuilder<QuizController>(
      init: Get.find<QuizController>(),
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = Get.find<QuizController>();
          if (isInstructor) {
            controller.loadQuizDetails(quiz.id);
            controller.loadQuizSubmissions(quiz.id);
          } else {
            controller.loadQuizDetails(quiz.id);
            controller.loadStudentQuizSubmissions(quiz.id);
          }
        });
      },
      builder: (controller) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    quiz.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                          colorScheme.secondaryContainer.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (isInstructor) ...[
                    IconButton(
                      icon: Icon(Icons.edit, color: colorScheme.primary),
                      onPressed: () async {
                        final result = await Get.toNamed(
                          Routes.QUIZZES_EDIT,
                          arguments: quiz,
                        );
                        if (result == true) {
                          controller.loadQuizzes(refresh: true);
                        }
                      },
                    ),
                  ],
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildTimeInfo(context),
                    const SizedBox(height: 16),
                    _buildQuizSettings(context),
                    if (isInstructor) ...[
                      const SizedBox(height: 16),
                      _buildQuestionsSection(context, controller),
                      const SizedBox(height: 16),
                      _buildTrackingOverview(context, controller),
                      const SizedBox(height: 16),
                      _buildSubmissions(context, controller),
                    ] else ...[
                      const SizedBox(height: 16),
                      _buildStudentQuizSection(context, controller),
                    ],
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildModernSection(
      context,
      title: 'Thông tin quiz',
      icon: Icons.quiz,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                quiz.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (quiz.description != null && quiz.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              quiz.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (quiz.course != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.school,
            label: 'Khóa học',
            value: '${quiz.course!.code} - ${quiz.course!.name}',
          ),
        ],
        if (quiz.quizGroups != null && quiz.quizGroups!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.group,
            label: 'Nhóm',
            value: quiz.quizGroups!
                .map((qg) => qg.groups?.name ?? '')
                .where((name) => name.isNotEmpty)
                .join(', '),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Thời gian',
      icon: Icons.schedule,
      children: [
        _buildModernDateTile(
          context,
          title: 'Ngày bắt đầu',
          subtitle: _formatDateTime(quiz.startDate),
          value: quiz.startDate,
          icon: Icons.play_arrow,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _buildModernDateTile(
          context,
          title: 'Hạn chót',
          subtitle: _formatDateTime(quiz.dueDate),
          value: quiz.dueDate,
          icon: Icons.flag,
          onTap: () {},
        ),
        if (quiz.lateDueDate != null) ...[
          const SizedBox(height: 8),
          _buildModernDateTile(
            context,
            title: 'Hạn nộp trễ',
            subtitle: _formatDateTime(quiz.lateDueDate!),
            value: quiz.lateDueDate!,
            icon: Icons.warning,
            onTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildQuizSettings(BuildContext context) {
    return _buildModernSection(
      context,
      title: 'Cài đặt quiz',
      icon: Icons.settings,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.repeat,
          label: 'Số lần làm tối đa',
          value: quiz.maxAttempts.toString(),
        ),
        if (quiz.timeLimit != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.timer,
            label: 'Thời gian làm bài',
            value: '${quiz.timeLimit} phút',
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          icon: Icons.help_outline,
          label: 'Số câu hỏi',
          value: quiz.questionCount?.toString() ??
              (quiz.questions?.length.toString() ?? '0'),
        ),
      ],
    );
  }

  Widget _buildTrackingOverview(
      BuildContext context, QuizController controller) {
    return _buildModernSection(
      context,
      title: 'Tổng quan theo dõi',
      icon: Icons.analytics,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Tổng số SV',
                value: controller.submissions.length.toString(),
                icon: Icons.people,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Đã làm',
                value: controller.submittedCount.toString(),
                icon: Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Chưa làm',
                value: controller.notSubmittedCount.toString(),
                icon: Icons.pending,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissions(BuildContext context, QuizController controller) {
    return Obx(() {
      final filteredSubmissions = controller.filteredSubmissions;
      final groups = controller.groups;
      final validGroups = groups.where((g) => g.id.isNotEmpty).toList();

      return _buildModernSection(
        context,
        title: 'Danh sách làm bài',
        icon: Icons.assignment_turned_in,
        children: [
          // Group filter dropdown
          if (validGroups.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: controller.selectedGroupId.value.isEmpty
                  ? null
                  : controller.selectedGroupId.value,
              decoration: InputDecoration(
                labelText: 'Lọc theo nhóm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả nhóm'),
                ),
                ...validGroups.map((group) => DropdownMenuItem<String?>(
                      value: group.id,
                      child: Text(group.name),
                    )),
              ],
              onChanged: (value) {
                controller.updateSelectedGroupId(value);
              },
            ),
            const SizedBox(height: 16),
          ],
          // Submissions list
          if (filteredSubmissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.submissions.isEmpty
                        ? 'Chưa có sinh viên nào làm bài'
                        : 'Không có sinh viên nào trong nhóm đã chọn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.submissions.isEmpty
                        ? 'Danh sách làm bài sẽ xuất hiện ở đây'
                        : 'Hãy thử chọn nhóm khác',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...filteredSubmissions.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _submissionColor(context, s.status),
                      child:
                          Icon(_submissionIcon(s.status), color: Colors.white),
                    ),
                    title: Text(
                      s.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.email,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        if (s.latestSubmission != null)
                          Text(
                            'Lần ${s.latestSubmission!.attemptNumber} - ${_formatDateTime(s.latestSubmission!.submittedAt)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.8),
                                    ),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(s.status.displayName),
                      backgroundColor: _submissionColor(context, s.status),
                      labelStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => _navigateToSubmissionDetail(s),
                  ),
                )),
        ],
      );
    });
  }

  void _navigateToSubmissionDetail(SubmissionTrackingData submissionData) {
    if (submissionData.latestSubmission == null) {
      Get.snackbar(
        'Thông báo',
        'Sinh viên này chưa có bài làm',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final submission = submissionData.latestSubmission!;

    if (submission.id == null || submission.id!.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Không tìm thấy ID bài làm',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.toNamed(
      Routes.QUIZ_SUBMISSION_DETAIL,
      arguments: {
        'submissionId': submission.id!,
      },
    );
  }

  Color _submissionColor(BuildContext context, SubmissionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return colorScheme.error;
      case SubmissionStatus.submitted:
        return colorScheme.primary;
      case SubmissionStatus.late:
        return colorScheme.tertiary;
      case SubmissionStatus.graded:
        return colorScheme.secondary;
    }
  }

  IconData _submissionIcon(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Icons.cancel;
      case SubmissionStatus.submitted:
        return Icons.check_circle;
      case SubmissionStatus.late:
        return Icons.warning;
      case SubmissionStatus.graded:
        return Icons.grade;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
        children: [
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
                  child: Icon(icon, color: colorScheme.primary, size: 20),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
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
          child: Icon(icon, color: colorScheme.primary, size: 20),
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
        trailing:
            Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
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
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Questions Section for Instructor
  Widget _buildQuestionsSection(
      BuildContext context, QuizController controller) {
    return Obx(() {
      final questions = controller.currentQuiz.value?.questions ?? [];

      debugPrint('📝 Questions count in instructor view: ${questions.length}');

      if (questions.isEmpty) {
        return _buildModernSection(
          context,
          title: 'Questions',
          icon: Icons.help_outline,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No questions added yet'),
              ),
            ),
          ],
        );
      }

      return _buildModernSection(
        context,
        title: 'Questions (${questions.length})',
        icon: Icons.help_outline,
        children: questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding:
                EdgeInsets.only(bottom: index < questions.length - 1 ? 12 : 0),
            child: _buildQuestionCard(context, question, index + 1),
          );
        }).toList(),
      );
    });
  }

  Widget _buildQuestionCard(
      BuildContext context, QuizQuestion question, int questionNumber) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.questionType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${question.points} pts',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.options != null && question.options!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question.options!.map((option) {
              final isCorrect = option.isCorrect;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCorrect
                          ? Colors.green
                          : colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.optionText,
                        style: TextStyle(
                          color: isCorrect
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isCorrect ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // Build Student Quiz Section
  Widget _buildStudentQuizSection(
      BuildContext context, QuizController controller) {
    return Obx(() {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final questions = controller.currentQuiz.value?.questions ?? [];
      final submissionsData = controller.studentSubmissionsData.value;

      debugPrint('📝 Questions count in student view: ${questions.length}');
      debugPrint(
          '📊 Submissions: ${submissionsData?.currentAttempts ?? 0}/${submissionsData?.maxAttempts ?? quiz.maxAttempts}');

      // Check if student has exceeded max attempts
      final maxAttempts = submissionsData?.maxAttempts ?? quiz.maxAttempts;
      final currentAttempts = submissionsData?.currentAttempts ?? 0;
      final hasExceededAttempts = currentAttempts >= maxAttempts;

      // Get latest submission (prefer graded, otherwise latest)
      String? latestSubmissionId;
      if (submissionsData?.submissions.isNotEmpty == true) {
        final gradedSubmissions = submissionsData!.submissions
            .where((s) => s.isGraded)
            .toList()
          ..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));

        if (gradedSubmissions.isNotEmpty) {
          latestSubmissionId = gradedSubmissions.first.id;
        } else {
          // If no graded submission, get latest submission
          final allSubmissions =
              List<StudentQuizSubmission>.from(submissionsData.submissions)
                ..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
          latestSubmissionId = allSubmissions.first.id;
        }
      }

      if (questions.isEmpty) {
        return _buildModernSection(
          context,
          title: 'Quiz',
          icon: Icons.quiz,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('This quiz has no questions yet'),
              ),
            ),
          ],
        );
      }

      // If exceeded attempts, show view results button
      if (hasExceededAttempts && latestSubmissionId != null) {
        return _buildModernSection(
          context,
          title: 'Quiz Results',
          icon: Icons.quiz,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn đã hoàn thành tất cả các lần làm bài',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã làm: $currentAttempts/$maxAttempts lần',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(
                          Routes.QUIZ_SUBMISSION_DETAIL,
                          arguments: {
                            'submissionId': latestSubmissionId,
                          },
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem kết quả'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final isSubmitting = controller.isSubmittingQuiz.value;
      final studentAnswers = controller.studentAnswers;

      return _buildModernSection(
        context,
        title: 'Quiz Questions',
        icon: Icons.quiz,
        children: [
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < questions.length - 1 ? 16 : 0),
              child: _buildStudentQuestionCard(
                context,
                question,
                index + 1,
                controller,
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ||
                      !_allRequiredQuestionsAnswered(questions, studentAnswers)
                  ? null
                  : () => _submitQuiz(context, controller, questions),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStudentQuestionCard(
    BuildContext context,
    QuizQuestion question,
    int questionNumber,
    QuizController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Question $questionNumber',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (question.isRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (question.questionType == 'multiple_choice' ||
              question.questionType == 'true_false')
            _buildMultipleChoiceOptions(context, question, controller)
          else if (question.questionType == 'essay')
            _buildEssayInput(context, question, controller),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(
    BuildContext context,
    QuizQuestion question,
    QuizController controller,
  ) {
    return Obx(() {
      final selectedOptionId =
          controller.studentAnswers[question.id] as String?;

      return Column(
        children: question.options?.map((option) {
              final isSelected = selectedOptionId == option.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    controller.updateStudentAnswer(question.id, option.id);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.optionText,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList() ??
            [],
      );
    });
  }

  Widget _buildEssayInput(
    BuildContext context,
    QuizQuestion question,
    QuizController controller,
  ) {
    return Obx(() {
      final answerText =
          controller.studentAnswers[question.id] as String? ?? '';

      return TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Type your answer here...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          controller.updateStudentAnswer(question.id, value);
        },
        controller: TextEditingController(text: answerText)
          ..selection = TextSelection.collapsed(offset: answerText.length),
      );
    });
  }

  bool _allRequiredQuestionsAnswered(
    List<QuizQuestion> questions,
    Map<String, dynamic> studentAnswers,
  ) {
    for (final question in questions) {
      if (question.isRequired) {
        final answer = studentAnswers[question.id];
        if (answer == null || (answer is String && answer.isEmpty)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _submitQuiz(
    BuildContext context,
    QuizController controller,
    List<QuizQuestion> questions,
  ) async {
    final studentAnswers = controller.studentAnswers;
    final answers = questions.map((question) {
      final answer = studentAnswers[question.id];
      if (question.questionType == 'essay') {
        return {
          'questionId': question.id,
          'answerText': answer as String?,
          'selectedOptionId': null,
        };
      } else {
        return {
          'questionId': question.id,
          'answerText': null,
          'selectedOptionId': answer as String?,
        };
      }
    }).toList();

    final success = await controller.submitQuiz(quiz.id, answers);
    if (success) {
      // Reload quiz details to refresh UI and show updated state
      await controller.loadQuizDetails(quiz.id);
      // UI will update automatically via Obx, toast already shown in controller
    }
  }
}
