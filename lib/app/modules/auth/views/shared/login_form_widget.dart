import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../controllers/login_controller.dart';

class LoginFormWidget extends StatelessWidget {
  final LoginController controller;

  const LoginFormWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username Field
          TextFormField(
            controller: controller.usernameController,
            decoration: InputDecoration(
              labelText: 'Tài khoản',
              hintText: 'Nhập tài khoản của bạn',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal:
                    ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                        ? 20
                        : 16,
                vertical: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                    ? 20
                    : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tài khoản';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          SizedBox(
              height: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                  ? 24
                  : 20),

          // Password Field
          Obx(() => TextFormField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu của bạn',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal:
                        ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                            ? 20
                            : 16,
                    vertical:
                        ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                            ? 20
                            : 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => controller.login(),
              )),

          SizedBox(
              height: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                  ? 32
                  : 24),

          // Login Button
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical:
                        ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                            ? 18
                            : 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                        height: ResponsiveBreakpoints.of(context)
                                .largerThan(DESKTOP)
                            ? 24
                            : 20,
                        width: ResponsiveBreakpoints.of(context)
                                .largerThan(DESKTOP)
                            ? 24
                            : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.of(context)
                                  .largerThan(DESKTOP)
                              ? 18
                              : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),

          SizedBox(
              height: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                  ? 24
                  : 20),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Container(
                padding: EdgeInsets.all(
                  ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                      ? 16
                      : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size:
                          ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                              ? 20
                              : 18,
                    ),
                    SizedBox(
                        width: ResponsiveBreakpoints.of(context)
                                .largerThan(DESKTOP)
                            ? 12
                            : 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: ResponsiveBreakpoints.of(context)
                                  .largerThan(DESKTOP)
                              ? 14
                              : 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
