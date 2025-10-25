import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/response/material_response.dart'
    as material_resp;
import 'material_detail_view.dart';

/**
 * Material Detail Demo
 * Demo page to test material detail functionality
 */
class MaterialDetailDemo extends StatelessWidget {
  const MaterialDetailDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Detail Demo'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Material Detail Demo',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test the material detail view functionality',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Demo buttons
            _buildDemoButton(
              context: context,
              title: 'Test Material Detail View',
              subtitle: 'Navigate to material detail with sample data',
              icon: Icons.description_outlined,
              onTap: () => _testMaterialDetail(),
            ),

            const SizedBox(height: 16),

            _buildDemoButton(
              context: context,
              title: 'Test with Route Navigation',
              subtitle: 'Test navigation using route parameters',
              icon: Icons.route_outlined,
              onTap: () => _testRouteNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testMaterialDetail() {
    // Create a sample material for testing
    final sampleMaterial = material_resp.Material(
      id: 'test-material-1',
      title: 'Tài liệu mẫu - Hướng dẫn lập trình Flutter',
      description:
          'Tài liệu này cung cấp hướng dẫn chi tiết về lập trình Flutter, bao gồm các khái niệm cơ bản, widget, state management và best practices.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      course: const material_resp.MaterialCourse(
        id: 'course-1',
        code: 'CS101',
        name: 'Lập trình di động',
      ),
      instructor: const material_resp.MaterialInstructor(
        id: 'instructor-1',
        fullName: 'Nguyễn Văn A',
        email: 'nguyenvana@example.com',
      ),
      files: [
        const material_resp.MaterialFile(
          id: 'file-1',
          fileName: 'Flutter_Basics.pdf',
          fileUrl: 'https://example.com/files/flutter-basics.pdf',
          fileSize: 2048576, // 2MB
          fileType: 'pdf',
        ),
        const material_resp.MaterialFile(
          id: 'file-2',
          fileName: 'Widget_Examples.docx',
          fileUrl: 'https://example.com/files/widget-examples.docx',
          fileSize: 1024000, // 1MB
          fileType: 'docx',
        ),
        const material_resp.MaterialFile(
          id: 'file-3',
          fileName: 'State_Management.pptx',
          fileUrl: 'https://example.com/files/state-management.pptx',
          fileSize: 5120000, // 5MB
          fileType: 'pptx',
        ),
      ],
      viewCount: 42,
    );

    // Navigate to material detail view
    Get.to(() => MaterialDetailView(materialId: sampleMaterial.id));
  }

  void _testRouteNavigation() {
    // Test navigation using route parameters
    Get.toNamed('/materials/detail/test-material-2');
  }
}
