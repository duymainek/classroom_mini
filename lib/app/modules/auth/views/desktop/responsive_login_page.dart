import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../controllers/login_controller.dart';
import '../shared/login_form_widget.dart';
import '../shared/login_validation_widget.dart';

class ResponsiveLoginPage extends StatelessWidget {
  const ResponsiveLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 600 : 500,
            maxHeight:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 700 : 600,
          ),
          child: Card(
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 48 : 40,
              ),
              child: GetBuilder<LoginController>(
                builder: (controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Title
                    _buildHeader(context),

                    SizedBox(
                        height:
                            ResponsiveBreakpoints.of(context).largerThan('4K')
                                ? 48
                                : 40),

                    // Login Form
                    LoginFormWidget(controller: controller),

                    SizedBox(
                        height:
                            ResponsiveBreakpoints.of(context).largerThan('4K')
                                ? 32
                                : 24),

                    // Validation Message
                    Obx(() => LoginValidationWidget(
                          message: controller.errorMessage.value,
                          isError: true,
                          onDismiss: controller.clearError,
                        )),

                    SizedBox(
                        height:
                            ResponsiveBreakpoints.of(context).largerThan('4K')
                                ? 32
                                : 24),

                    // Quick Login Button (for testing)
                    if (Get.find<LoginController>()
                        .usernameController
                        .text
                        .isEmpty)
                      _buildQuickLoginButton(context, controller),

                    SizedBox(
                        height:
                            ResponsiveBreakpoints.of(context).largerThan('4K')
                                ? 32
                                : 24),

                    // Footer
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: ResponsiveBreakpoints.of(context).largerThan('4K') ? 120 : 100,
          height:
              ResponsiveBreakpoints.of(context).largerThan('4K') ? 120 : 100,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.school,
            size: ResponsiveBreakpoints.of(context).largerThan('4K') ? 60 : 50,
            color: Theme.of(context).primaryColor,
          ),
        ),

        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 32 : 24),

        // Title
        Text(
          'Classroom Mini',
          style: Get.textTheme.headlineMedium?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 36 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 12 : 8),

        // Subtitle
        Text(
          'Đăng nhập vào hệ thống quản lý lớp học',
          style: Get.textTheme.bodyLarge?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 18 : 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLoginButton(
      BuildContext context, LoginController controller) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.quickLogin,
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Đăng nhập nhanh (admin/admin)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade600,
          side: BorderSide(color: Colors.orange.shade300),
          padding: EdgeInsets.symmetric(
            vertical:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 16 : 14,
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hệ thống quản lý lớp học thông minh',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 14 : 13,
          ),
        ),
        SizedBox(
            height: ResponsiveBreakpoints.of(context).largerThan('4K') ? 8 : 6),
        Text(
          'Phiên bản 1.0.0 - Desktop Edition',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade400,
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan('4K') ? 12 : 11,
          ),
        ),
      ],
    );
  }
}
