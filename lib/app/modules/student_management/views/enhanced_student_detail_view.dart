import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedStudentDetailView extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EnhancedStudentDetailView({
    Key? key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dynamic groupObj = student['group'];
    final dynamic courseObj = student['course'];
    String groupLabel = '-';
    if (groupObj is Map<String, dynamic>) {
      groupLabel = (groupObj['name'] ?? groupObj['id'] ?? '-').toString();
    } else {
      groupLabel = (student['groupId'] ?? '-').toString();
    }
    String courseLabel = '-';
    if (courseObj is Map<String, dynamic>) {
      final code = courseObj['code']?.toString();
      final name = courseObj['name']?.toString();
      if (code != null && name != null) {
        courseLabel = '$code - $name';
      } else {
        courseLabel =
            (courseObj['name'] ?? courseObj['code'] ?? courseObj['id'] ?? '-')
                .toString();
      }
    } else {
      courseLabel = (student['courseId'] ?? '-').toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme),
          const SizedBox(height: 24),
          _buildBasicInfoSection(context, colorScheme),
          const SizedBox(height: 24),
          _buildAccountInfoSection(context, colorScheme),
          const SizedBox(height: 24),
          _buildAssignmentSection(context, colorScheme, courseLabel, groupLabel),
          const SizedBox(height: 24),
          _buildStatusSection(context, colorScheme, student['isActive'] ?? true),
          const SizedBox(height: 24),
          _buildActions(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final fullName = student['fullName'] ?? '';
    final email = student['email'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(fullName.isNotEmpty ? fullName : email),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'Chưa có tên',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(
      BuildContext context, ColorScheme colorScheme) {
    return _buildSection(
      context: context,
      colorScheme: colorScheme,
      title: 'Thông tin cơ bản',
      icon: Icons.person_outline,
      children: [
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.badge_outlined,
          label: 'ID',
          value: student['id'] ?? '-',
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.person_outline,
          label: 'Username',
          value: student['username'] ?? '-',
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.badge,
          label: 'Họ và tên',
          value: student['fullName'] ?? '-',
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.email_outlined,
          label: 'Email',
          value: student['email'] ?? '-',
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection(
      BuildContext context, ColorScheme colorScheme) {
    final createdAt = student['createdAt'];
    final updatedAt = student['updatedAt'];
    final lastLoginAt = student['lastLoginAt'];

    String? formatDate(dynamic date) {
      if (date == null) return null;
      try {
        if (date is String) {
          final parsed = DateTime.parse(date);
          return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
        } else if (date is DateTime) {
          return DateFormat('dd/MM/yyyy HH:mm').format(date);
        }
      } catch (e) {
        return null;
      }
      return null;
    }

    return _buildSection(
      context: context,
      colorScheme: colorScheme,
      title: 'Thông tin tài khoản',
      icon: Icons.account_circle_outlined,
      children: [
        if (createdAt != null)
          _buildDetailRow(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tạo',
            value: formatDate(createdAt) ?? '-',
          ),
        if (createdAt != null) const SizedBox(height: 16),
        if (updatedAt != null)
          _buildDetailRow(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.update_outlined,
            label: 'Cập nhật lần cuối',
            value: formatDate(updatedAt) ?? '-',
          ),
        if (updatedAt != null) const SizedBox(height: 16),
        if (lastLoginAt != null)
          _buildDetailRow(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.login_outlined,
            label: 'Đăng nhập lần cuối',
            value: formatDate(lastLoginAt) ?? '-',
          ),
        if (lastLoginAt == null)
          _buildDetailRow(
            context: context,
            colorScheme: colorScheme,
            icon: Icons.login_outlined,
            label: 'Đăng nhập lần cuối',
            value: 'Chưa đăng nhập',
          ),
      ],
    );
  }

  Widget _buildAssignmentSection(BuildContext context, ColorScheme colorScheme,
      String courseLabel, String groupLabel) {
    return _buildSection(
      context: context,
      colorScheme: colorScheme,
      title: 'Phân công',
      icon: Icons.school_outlined,
      children: [
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.school_outlined,
          label: 'Khóa học',
          value: courseLabel,
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context: context,
          colorScheme: colorScheme,
          icon: Icons.group_outlined,
          label: 'Nhóm',
          value: groupLabel,
        ),
      ],
    );
  }

  Widget _buildStatusSection(
      BuildContext context, ColorScheme colorScheme, bool isActive) {
    return _buildSection(
      context: context,
      colorScheme: colorScheme,
      title: 'Trạng thái',
      icon: Icons.toggle_on,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Đang hoạt động' : 'Không hoạt động',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Sinh viên có thể đăng nhập và sử dụng hệ thống'
                          : 'Sinh viên không thể đăng nhập vào hệ thống',
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Chỉnh sửa'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String nameOrEmail) {
    final source = nameOrEmail.trim();
    if (source.isEmpty) return '?';
    final parts = source.contains(' ')
        ? source.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList()
        : source.split('@').first.split('.');
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

