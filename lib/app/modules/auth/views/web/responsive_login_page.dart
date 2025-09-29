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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 32 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                  ? 500
                  : 400,
            ),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                      ? 40
                      : 32,
                ),
                child: GetBuilder<LoginController>(
                  builder: (controller) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      _buildHeader(context),

                      SizedBox(
                          height: ResponsiveBreakpoints.of(context)
                                  .largerThan(DESKTOP)
                              ? 40
                              : 32),

                      // Login Form
                      LoginFormWidget(controller: controller),

                      SizedBox(
                          height: ResponsiveBreakpoints.of(context)
                                  .largerThan(DESKTOP)
                              ? 24
                              : 20),

                      // Validation Message
                      Obx(() => LoginValidationWidget(
                            message: controller.errorMessage.value,
                            isError: true,
                            onDismiss: controller.clearError,
                          )),

                      SizedBox(
                          height: ResponsiveBreakpoints.of(context)
                                  .largerThan(DESKTOP)
                              ? 24
                              : 20),

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
          width:
              ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 100 : 80,
          height:
              ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 100 : 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.school,
            size:
                ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 50 : 40,
            color: Theme.of(context).primaryColor,
          ),
        ),

        SizedBox(
            height: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                ? 24
                : 20),

        // Title
        Text(
          'Classroom Mini',
          style: Get.textTheme.headlineMedium?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),

        SizedBox(
            height:
                ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 8 : 6),

        // Subtitle
        Text(
          'Đăng nhập vào hệ thống',
          style: Get.textTheme.bodyLarge?.copyWith(
            fontSize:
                ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 16 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLoginButton(
      BuildContext context, LoginController controller) {
    return OutlinedButton.icon(
      onPressed: controller.quickLogin,
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Đăng nhập nhanh (admin/admin)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange.shade600,
        side: BorderSide(color: Colors.orange.shade300),
        padding: EdgeInsets.symmetric(
          vertical:
              ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 12 : 10,
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
