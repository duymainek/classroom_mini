import 'package:flutter/material.dart';
import '../../../data/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = assignment.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 8),

              // Course info
              if (assignment.course != null)
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${assignment.course!.code} - ${assignment.course!.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Groups info
              if (assignment.groups.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Nhóm: ${assignment.groups.map((g) => g.name).join(', ')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Description
              if (assignment.description != null &&
                  assignment.description!.isNotEmpty)
                Text(
                  'Mô tả:  ${assignment.description!}',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Time info
              _buildTimeInfo(theme),

              const SizedBox(height: 8),

              // Submission info
              _buildSubmissionInfo(theme),

              // Actions
              if (showActions) ...[
                const SizedBox(height: 12),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AssignmentStatus status) {
    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.upcoming:
        return Colors.blue;
      case AssignmentStatus.open:
        return Colors.green;
      case AssignmentStatus.lateSubmission:
        return Colors.orange;
      case AssignmentStatus.closed:
        return Colors.red;
      case AssignmentStatus.inactive:
        return Colors.grey;
    }
  }

  Widget _buildTimeInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Bắt đầu: ${_formatDateTime(assignment.startDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.flag,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Hạn chót: ${_formatDateTime(assignment.dueDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (assignment.lateDueDate != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Nộp trễ: ${_formatDateTime(assignment.lateDueDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmissionInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.upload,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Tối đa ${assignment.maxAttempts} lần nộp',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (assignment.fileFormats.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Định dạng: ${assignment.fileFormats.join(', ')}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Sửa'),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Xóa'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class AssignmentListCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;
  final bool isSelected;

  const AssignmentListCard({
    Key? key,
    required this.assignment,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = assignment.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          assignment.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assignment.course != null)
              Text(
                '${assignment.course!.code} - ${assignment.course!.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              'Hạn chót: ${_formatDateTime(assignment.dueDate)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Chip(
                label: Text(
                  status.displayName,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: _getStatusColor(status),
                labelStyle: const TextStyle(color: Colors.white),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${assignment.maxAttempts} lần',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.upcoming:
        return Colors.blue;
      case AssignmentStatus.open:
        return Colors.green;
      case AssignmentStatus.lateSubmission:
        return Colors.orange;
      case AssignmentStatus.closed:
        return Colors.red;
      case AssignmentStatus.inactive:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.upcoming:
        return Icons.schedule;
      case AssignmentStatus.open:
        return Icons.assignment;
      case AssignmentStatus.lateSubmission:
        return Icons.warning;
      case AssignmentStatus.closed:
        return Icons.lock;
      case AssignmentStatus.inactive:
        return Icons.pause;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
