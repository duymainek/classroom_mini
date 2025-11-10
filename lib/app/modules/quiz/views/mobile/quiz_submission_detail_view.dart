import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import 'package:classroom_mini/app/core/app_config.dart';
import 'package:intl/intl.dart';

/// Enhanced Quiz Submission Detail View
/// Following UX Design Recommendations with:
/// - Progressive Disclosure
/// - Visual Hierarchy
/// - Consistent Interaction
/// - Accessibility First
class QuizSubmissionDetailView extends GetView<QuizController> {
  final String submissionId;

  const QuizSubmissionDetailView({
    super.key,
    required this.submissionId,
  });

  // Design Tokens - Colors
  static const Color _primaryColor = Color(0xFF2196F3);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFF9800);
  static const Color _errorColor = Color(0xFFF44336);
  static const Color _neutralColor = Color(0xFF757575);

  // Design Tokens - Spacing
  static const double _spacingXS = 4.0;
  static const double _spacingSM = 8.0;
  static const double _spacingMD = 16.0;
  static const double _spacingLG = 24.0;
  static const double _spacingXL = 32.0;

  @override
  Widget build(BuildContext context) {
    final isInstructor = AppConfig.instance.isInstructor;

    // Load submission detail when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSubmission = controller.currentSubmission.value;
      // Load if submission is null or if it's a different submission
      if (currentSubmission == null || currentSubmission.id != submissionId) {
        controller.loadQuizSubmissionDetail(submissionId);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        final submission = controller.currentSubmission.value;
        final isLoading = controller.isLoading.value;
        final hasError = controller.errorMessage.value.isNotEmpty;

        // Show loading if currently loading OR if submission is null and no error yet
        if (isLoading || (submission == null && !hasError)) {
          return _buildLoadingState();
        }

        // Show error if submission is null and there's an error
        if (submission == null) {
          return _buildErrorState(controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Submission not found');
        }

        // Check if this is the correct submission
        if (submission.id != submissionId) {
          return _buildLoadingState();
        }

        return CustomScrollView(
          slivers: [
            _buildModernAppBar(context, submission),
            SliverPadding(
              padding: const EdgeInsets.all(_spacingMD),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSubmissionSummaryCard(context, submission),
                  const SizedBox(height: _spacingMD),
                  _buildSubmissionInfoCard(context, submission),
                  const SizedBox(height: _spacingMD),
                  _buildQuestionsSection(context, submission, isInstructor),
                  const SizedBox(height: _spacingMD),
                  // Complete Grading Button (Instructor only)
                  if (isInstructor &&
                      controller.hasEssayQuestions &&
                      !submission.isGraded)
                    _buildCompleteGradingButton(context, submission),
                  if (isInstructor &&
                      controller.hasEssayQuestions &&
                      !submission.isGraded)
                    const SizedBox(height: _spacingMD),
                  if (submission.feedback != null &&
                      submission.feedback!.isNotEmpty)
                    _buildFeedbackCard(context, submission),
                  const SizedBox(height: _spacingXL),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  // Loading State with smooth animation
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: _spacingMD),
          Text(
            'Loading submission details...',
            style: TextStyle(
              fontSize: 14,
              color: _neutralColor,
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: _errorColor,
          ),
          const SizedBox(height: _spacingMD),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _neutralColor,
            ),
          ),
        ],
      ),
    );
  }

  // Modern App Bar with gradient
  Widget _buildModernAppBar(
      BuildContext context, QuizSubmissionDetail submission) {
    final scorePercentage =
        submission.maxScore != null && submission.maxScore! > 0
            ? (submission.totalScore ?? 0) / submission.maxScore! * 100
            : 0.0;

    Color gradientColor = _getScoreColor(scorePercentage / 100);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: gradientColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          submission.student?.fullName ?? 'Student',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColor,
                gradientColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  _spacingMD, _spacingXL, _spacingMD, _spacingMD),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Score',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: _spacingXS),
                            Text(
                              '${submission.totalScore?.toStringAsFixed(1) ?? 'N/A'} / ${submission.maxScore?.toStringAsFixed(1) ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: _spacingXS),
                            Text(
                              '${scorePercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildGradedBadge(submission.isGraded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Graded Badge with modern design
  Widget _buildGradedBadge(bool isGraded) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGraded ? Icons.check_circle : Icons.pending,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: _spacingXS),
          Text(
            isGraded ? 'Graded' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Submission Summary Card with visual hierarchy
  Widget _buildSubmissionSummaryCard(
      BuildContext context, QuizSubmissionDetail submission) {
    final percentage = submission.maxScore != null && submission.maxScore! > 0
        ? (submission.totalScore ?? 0) / submission.maxScore!
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.assessment, color: _primaryColor, size: 20),
                SizedBox(width: _spacingSM),
                Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingLG),
            _buildScoreProgressBar(context, submission, percentage),
            const SizedBox(height: _spacingLG),
            _buildStatisticsRow(submission),
          ],
        ),
      ),
    );
  }

  // Modern Score Progress Bar
  Widget _buildScoreProgressBar(BuildContext context,
      QuizSubmissionDetail submission, double percentage) {
    final barColor = _getScoreColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _neutralColor,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 24,
          ),
        ),
        const SizedBox(height: _spacingSM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              submission.maxScore?.toStringAsFixed(0) ?? '0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Statistics Row with icons
  Widget _buildStatisticsRow(QuizSubmissionDetail submission) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            Icons.question_answer,
            'Questions',
            submission.answers.length.toString(),
            _primaryColor,
          ),
        ),
        SizedBox(width: _spacingSM),
        Expanded(
          child: _buildStatItem(
            Icons.check_circle_outline,
            'Correct',
            submission.answers.where((a) => a.isCorrect).length.toString(),
            _successColor,
          ),
        ),
        SizedBox(width: _spacingSM),
        Expanded(
          child: _buildStatItem(
            Icons.cancel_outlined,
            'Wrong',
            submission.answers
                .where((a) => !a.isCorrect && a.score != null)
                .length
                .toString(),
            _errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(_spacingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: _spacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: _spacingXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _neutralColor,
            ),
          ),
        ],
      ),
    );
  }

  // Submission Info Card with clean layout
  Widget _buildSubmissionInfoCard(
      BuildContext context, QuizSubmissionDetail submission) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: _primaryColor, size: 20),
                SizedBox(width: _spacingSM),
                Text(
                  'Submission Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: _spacingLG),
            _buildDetailRow(
              Icons.tag,
              'Attempt',
              '#${submission.attemptNumber}',
            ),
            const SizedBox(height: _spacingMD),
            _buildDetailRow(
              Icons.access_time,
              'Submitted At',
              DateFormat('MMM dd, yyyy • HH:mm').format(submission.submittedAt),
            ),
            const SizedBox(height: _spacingMD),
            _buildDetailRow(
              Icons.flag,
              'Status',
              submission.isLate ? 'Late Submission' : 'On Time',
              valueColor: submission.isLate ? _errorColor : _successColor,
            ),
            if (submission.student?.email != null) ...[
              const SizedBox(height: _spacingMD),
              _buildDetailRow(
                Icons.email,
                'Email',
                submission.student!.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: _neutralColor, size: 18),
        const SizedBox(width: _spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _neutralColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: _spacingXS),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Questions Section with progressive disclosure
  Widget _buildQuestionsSection(BuildContext context,
      QuizSubmissionDetail submission, bool isInstructor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _spacingXS),
          child: Row(
            children: const [
              Icon(Icons.quiz, color: _primaryColor, size: 20),
              SizedBox(width: _spacingSM),
              Text(
                'Questions & Answers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _spacingMD),
        ...submission.answers.asMap().entries.map((entry) {
          final index = entry.key;
          final answer = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: _spacingMD),
            child: _buildEnhancedQuestionCard(
                context, answer, index + 1, isInstructor),
          );
        }),
      ],
    );
  }

  // Enhanced Question Card with visual hierarchy
  Widget _buildEnhancedQuestionCard(BuildContext context,
      QuizAnswerDetail answer, int questionNumber, bool isInstructor) {
    final question = answer.question;
    if (question == null) return const SizedBox.shrink();

    final isEssay = question.questionType == 'essay';
    final reviewStatus = answer.reviewStatus ?? 'pending';
    final isPending = isEssay && reviewStatus == 'pending';
    final statusColor = isEssay
        ? (reviewStatus == 'pending'
            ? _warningColor
            : (reviewStatus == 'approved' ? _successColor : _errorColor))
        : (answer.isCorrect ? _successColor : _errorColor);
    final statusText = isEssay
        ? (reviewStatus == 'pending'
            ? 'Pending Review'
            : (reviewStatus == 'approved' ? 'Approved' : 'Rejected'))
        : (answer.isCorrect ? 'Correct' : 'Incorrect');
    final statusIcon = isEssay
        ? (reviewStatus == 'pending'
            ? Icons.pending
            : (reviewStatus == 'approved' ? Icons.check_circle : Icons.cancel))
        : (answer.isCorrect ? Icons.check_circle : Icons.cancel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(_spacingMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: _spacingSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    question.questionType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: _spacingXS),
                Text(
                  '${answer.score?.toStringAsFixed(1) ?? '0'}/${question.points}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(_spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: _spacingMD),
                _buildStudentAnswerSection(question, answer),
                if (!isEssay) ...[
                  const SizedBox(height: _spacingMD),
                  _buildCorrectAnswerSection(question),
                ],
                const SizedBox(height: _spacingMD),
                _buildStatusBadge(statusIcon, statusText, statusColor),
                // Review buttons for essay questions (Instructor only)
                if (isInstructor && isEssay && isPending) ...[
                  const SizedBox(height: _spacingMD),
                  _buildReviewButtons(context, answer),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAnswerSection(
      QuizQuestion question, QuizAnswerDetail answer) {
    return Container(
      padding: const EdgeInsets.all(_spacingMD),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person, color: Colors.blue, size: 16),
              SizedBox(width: _spacingSM),
              Text(
                'Your Answer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingSM),
          if (question.questionType == 'essay')
            Text(
              answer.answerText ?? 'No answer provided',
              style: const TextStyle(fontSize: 14, height: 1.5),
            )
          else
            _buildOptionDisplay(question, answer.selectedOptionId, false),
        ],
      ),
    );
  }

  Widget _buildCorrectAnswerSection(QuizQuestion question) {
    final correctOption = question.options?.firstWhere(
      (opt) => opt.isCorrect,
      orElse: () => question.options!.first,
    );

    return Container(
      padding: const EdgeInsets.all(_spacingMD),
      decoration: BoxDecoration(
        color: _successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: _successColor, size: 16),
              SizedBox(width: _spacingSM),
              Text(
                'Correct Answer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingSM),
          _buildOptionDisplay(question, correctOption?.id, true),
        ],
      ),
    );
  }

  Widget _buildOptionDisplay(
      QuizQuestion question, String? optionId, bool isCorrect) {
    if (optionId == null) {
      return const Text('No option selected',
          style: TextStyle(fontStyle: FontStyle.italic));
    }

    final option = question.options?.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => QuizQuestionOption(
        id: '',
        questionId: '',
        optionText: 'Unknown option',
        isCorrect: false,
        orderIndex: 0,
      ),
    );

    if (option == null) {
      return const Text('Unknown option');
    }

    return Row(
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.radio_button_checked,
          color: isCorrect ? _successColor : Colors.blue,
          size: 18,
        ),
        const SizedBox(width: _spacingSM),
        Expanded(
          child: Text(
            option.optionText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: _spacingSM),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Review buttons for essay answers
  Widget _buildReviewButtons(BuildContext context, QuizAnswerDetail answer) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReviewAnswer(answer.id, 'approve'),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: _spacingMD),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReviewAnswer(answer.id, 'reject'),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Handle review answer action
  void _handleReviewAnswer(String answerId, String action) {
    Get.dialog(
      AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Reject'} Answer?'),
        content: Text(
          'Are you sure you want to ${action == 'approve' ? 'approve' : 'reject'} this essay answer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.reviewAnswer(submissionId, answerId, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'approve' ? _successColor : _errorColor,
            ),
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  // Complete Grading Button
  Widget _buildCompleteGradingButton(
      BuildContext context, QuizSubmissionDetail submission) {
    final allReviewed = controller.hasAllEssaysReviewed;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  allReviewed ? Icons.check_circle : Icons.pending,
                  color: allReviewed ? _successColor : _warningColor,
                  size: 20,
                ),
                const SizedBox(width: _spacingSM),
                Expanded(
                  child: Text(
                    allReviewed
                        ? 'All essay questions reviewed'
                        : 'Some essay questions pending review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: allReviewed ? _successColor : _warningColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMD),
            ElevatedButton.icon(
              onPressed: allReviewed ? () => _handleCompleteGrading() : null,
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Complete Grading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (!allReviewed) ...[
              const SizedBox(height: _spacingSM),
              Text(
                'Please review all essay questions before completing grading.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Handle complete grading action
  void _handleCompleteGrading() {
    Get.dialog(
      AlertDialog(
        title: const Text('Complete Grading?'),
        content: const Text(
          'Are you sure you want to mark this submission as fully graded? '
          'This will finalize the grading process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.completeGrading(submissionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: const Text('Complete Grading'),
          ),
        ],
      ),
    );
  }

  // Feedback Card
  Widget _buildFeedbackCard(
      BuildContext context, QuizSubmissionDetail submission) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.feedback, color: _warningColor, size: 20),
                SizedBox(width: _spacingSM),
                Text(
                  'Instructor Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMD),
            Container(
              padding: const EdgeInsets.all(_spacingMD),
              decoration: BoxDecoration(
                color: _warningColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _warningColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                submission.feedback!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Get color based on score percentage
  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return _successColor;
    if (percentage >= 0.6) return _warningColor;
    return _errorColor;
  }
}
