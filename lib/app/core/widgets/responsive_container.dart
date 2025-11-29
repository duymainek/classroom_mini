import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effectiveMaxWidth = maxWidth ?? _getDefaultMaxWidth(width);
        
        final responsivePadding = padding ?? _getResponsivePadding(width);

        Widget content = Padding(
          padding: responsivePadding,
          child: child,
        );

        if (centerContent && width > effectiveMaxWidth) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              child: content,
            ),
          );
        } else if (width > effectiveMaxWidth) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: content,
          );
        }

        return content;
      },
    );
  }

  double _getDefaultMaxWidth(double screenWidth) {
    if (screenWidth < 768) {
      return double.infinity;
    } else if (screenWidth < 1024) {
      return 900;
    } else {
      return 1200;
    }
  }

  EdgeInsets _getResponsivePadding(double screenWidth) {
    if (screenWidth < 768) {
      return const EdgeInsets.all(16);
    } else if (screenWidth < 1024) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
  }
}

