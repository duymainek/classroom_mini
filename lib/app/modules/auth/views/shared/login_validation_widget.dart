import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class LoginValidationWidget extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const LoginValidationWidget({
    super.key,
    required this.message,
    this.isError = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 16 : 12,
      ),
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red.shade600 : Colors.green.shade600,
            size:
                ResponsiveBreakpoints.of(context).largerThan(DESKTOP) ? 20 : 18,
          ),
          SizedBox(
              width: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                  ? 12
                  : 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade600 : Colors.green.shade600,
                fontSize: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                    ? 14
                    : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: isError ? Colors.red.shade600 : Colors.green.shade600,
                size: ResponsiveBreakpoints.of(context).largerThan(DESKTOP)
                    ? 18
                    : 16,
              ),
            ),
        ],
      ),
    );
  }
}
