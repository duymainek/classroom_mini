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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 24 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                _buildHeader(context),

                SizedBox(
                    height: ResponsiveBreakpoints.of(context).largerThan(TABLET)
                        ? 40
                        : 32),

                // Login Card
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      ResponsiveBreakpoints.of(context).largerThan(TABLET)
                          ? 32
                          : 24,
                    ),
                    child: GetBuilder<LoginController>(
                      builder: (controller) => Column(
                        children: [
                          // Login Form
                          LoginFormWidget(controller: controller),

                          SizedBox(
                              height: ResponsiveBreakpoints.of(context)
                                      .largerThan(TABLET)
                                  ? 20
                                  : 16),

                          // Validation Message
                          Obx(() => LoginValidationWidget(
                                message: controller.errorMessage.value,
                                isError: true,
                                onDismiss: controller.clearError,
                              )),

                          SizedBox(
                              height: ResponsiveBreakpoints.of(context)
                                      .largerThan(TABLET)
                                  ? 20
                                  : 16),

                          // Quick Login Button (for testing)
                          if (Get.find<LoginController>()
                              .usernameController
                              .text
                              .isEmpty)
                            _buildQuickLoginButton(context, controller),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(
                    height: ResponsiveBreakpoints.of(context).largerThan(TABLET)
                        ? 32
                        : 24),

                // Footer
                _buildFooter(context),
              ],
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
          width: ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 80 : 64,
          height:
              ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 80 : 64,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.school,
            size:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 40 : 32,
            color: Theme.of(context).primaryColor,
          ),
        ),

        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 20 : 16),

        // Title
        Text(
          'Classroom Mini',
          style: Get.textTheme.headlineMedium?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 6 : 4),

        // Subtitle
        Text(
          'Đăng nhập vào hệ thống',
          style: Get.textTheme.bodyLarge?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 16 : 14,
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
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 12 : 10,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hệ thống quản lý lớp học',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 12 : 11,
          ),
        ),
        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 4 : 2),
        Text(
          'Phiên bản 1.0.0',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade400,
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(TABLET) ? 11 : 10,
          ),
        ),
      ],
    );
  }
}
