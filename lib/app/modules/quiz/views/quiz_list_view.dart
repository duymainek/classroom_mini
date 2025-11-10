import 'package:classroom_mini/app/routes/app_routes.dart';
import 'package:classroom_mini/app/core/app_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/quiz_controller.dart';

class QuizListView extends GetView<QuizController> {
  const QuizListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: AppConfig.instance.isInstructor
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed(Routes.QUIZZES_CREATE),
              icon: const Icon(Icons.add),
              label: const Text('Tạo Quiz'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : const SizedBox.shrink(),
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
                'Quizzes',
                style: theme.textTheme.headlineSmall?.copyWith(
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
              IconButton(
                icon: Icon(Icons.search, color: colorScheme.onSurface),
                onPressed: () => _showSearchDialog(context),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
                onPressed: () => _showFilterDialog(context),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Obx(() {
              if (controller.isLoading.value && controller.quizzes.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildLoadingState(context),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return SliverToBoxAdapter(
                  child: _buildErrorState(context),
                );
              }

              if (controller.quizzes.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final quiz = controller.quizzes[index];
                    return _buildModernQuizCard(context, quiz, index);
                  },
                  childCount: controller.quizzes.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading quizzes...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading quizzes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => controller.loadQuizzes(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
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
            'No quizzes found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first quiz to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuizCard(BuildContext context, quiz, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final courseName = quiz.course?.name ?? 'N/A';
    final startDate = DateFormat.yMMMd().add_jm().format(quiz.startDate);
    final dueDate = DateFormat.yMMMd().add_jm().format(quiz.dueDate);
    final lateDueDate = quiz.lateDueDate != null
        ? DateFormat.yMMMd().add_jm().format(quiz.lateDueDate!)
        : null;
    final int? questionCount = quiz.questionCount ?? quiz.questions?.length;
    final String questionCountText =
        questionCount != null ? '$questionCount' : '—';

    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.QUIZZES_DETAIL, arguments: quiz);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header với status và actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: quiz.isActive
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest
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
                      color: quiz.isActive
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: quiz.isActive
                          ? colorScheme.primary
                          : colorScheme.outline,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (quiz.description != null &&
                            quiz.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            quiz.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: quiz.isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quiz.isActive ? 'Active' : 'Closed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Course info
                  _buildInfoRow(
                    context,
                    icon: Icons.school_outlined,
                    label: 'Course',
                    value: courseName,
                  ),

                  const SizedBox(height: 12),

                  // Date range
                  _buildInfoRow(
                    context,
                    icon: Icons.schedule_outlined,
                    label: 'Start Date',
                    value: startDate,
                  ),

                  const SizedBox(height: 8),

                  _buildInfoRow(
                    context,
                    icon: Icons.event_outlined,
                    label: 'Due Date',
                    value: dueDate,
                  ),

                  if (lateDueDate != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.warning_outlined,
                      label: 'Late Due Date',
                      value: lateDueDate,
                      valueColor: Colors.orange,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quiz details grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                context,
                                icon: Icons.quiz_outlined,
                                label: 'Questions',
                                value: questionCountText,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                context,
                                icon: Icons.repeat_outlined,
                                label: 'Max Attempts',
                                value: '${quiz.maxAttempts}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Assigned groups
                        if (quiz.quizGroups != null &&
                            quiz.quizGroups!.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Assigned Groups',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Align(
                          //   alignment: Alignment.centerLeft,
                          //   child: Wrap(
                          //     spacing: 8,
                          //     runSpacing: 8,
                          //     children: quiz.quizGroups!
                          //         .where((g) => g.groups != null)
                          //         .map((g) => _buildGroupChip(
                          //               context,
                          //               g.groups!.name,
                          //             ))
                          //         .toList(),
                          //   ),
                          // ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings info
                  if (quiz.shuffleQuestions ||
                      quiz.shuffleOptions ||
                      quiz.showCorrectAnswers) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (quiz.shuffleQuestions)
                            _buildSettingChip(context, 'Shuffle Questions'),
                          if (quiz.shuffleOptions)
                            _buildSettingChip(context, 'Shuffle Options'),
                          if (quiz.showCorrectAnswers)
                            _buildSettingChip(context, 'Show Answers'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Spacer(),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Get.toNamed(Routes.QUIZZES_DETAIL,
                              arguments: quiz),
                          label: const Text('View Details'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGroupChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Search Quizzes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Enter quiz title or description...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onSubmitted: (value) {
            controller.searchQuizzes(value);
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.searchQuizzes(searchController.text);
              Get.back();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        title: Text(
          'Filter Quizzes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status filter
            _buildFilterSection(
              context,
              title: 'Status',
              options: [
                {'value': 'all', 'label': 'All'},
                {'value': 'active', 'label': 'Active'},
                {'value': 'closed', 'label': 'Closed'},
              ],
              currentValue: controller.statusFilter.value,
              onChanged: (value) => controller.filterByStatus(value),
            ),

            const SizedBox(height: 16),

            // Sort options
            _buildFilterSection(
              context,
              title: 'Sort By',
              options: [
                {'value': 'created_at', 'label': 'Created Date'},
                {'value': 'due_date', 'label': 'Due Date'},
                {'value': 'title', 'label': 'Title'},
              ],
              currentValue: controller.sortBy.value,
              onChanged: (value) =>
                  controller.sortQuizzes(value, controller.sortOrder.value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> options,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = option['value'] == currentValue;
            return FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option['value']!);
                }
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}
