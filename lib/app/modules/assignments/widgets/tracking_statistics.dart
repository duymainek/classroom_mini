import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/assignment_controller.dart';

/**
 * Statistics widget for assignment tracking
 * Following Material 3 Design Guide patterns
 */
class TrackingStatistics extends StatelessWidget {
  final AssignmentController controller;

  const TrackingStatistics({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildStatisticsContent(context));
  }

  Widget _buildStatisticsContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // First row - Main stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Tổng sinh viên',
                controller.totalStudents.toString(),
                Icons.people_outline,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Đã nộp',
                controller.submittedCount.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Second row - Status stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Chưa nộp',
                controller.notSubmittedCount.toString(),
                Icons.cancel_outlined,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Nộp trễ',
                controller.lateCount.toString(),
                Icons.schedule,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Third row - Progress stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Đã chấm',
                controller.gradedCount.toString(),
                Icons.grade,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Tỷ lệ nộp',
                '${controller.submissionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.teal,
              ),
            ),
          ],
        ),

        // Progress bar section
        if (controller.totalStudents > 0) ...[
          const SizedBox(height: 20),
          _buildProgressSection(context),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important: Use min size
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final submissionProgress = controller.totalStudents > 0
        ? controller.submittedCount / controller.totalStudents
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tiến độ nộp bài',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(submissionProgress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: submissionProgress,
              backgroundColor: colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.submittedCount} / ${controller.totalStudents} sinh viên đã nộp bài',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
