import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class SimpleResponsiveFactory {
  /// Creates a single responsive view that adapts based on screen size
  static Widget createView({
    required Widget child,
    BuildContext? context,
  }) {
    if (context == null) return child;

    return ResponsiveValue<Widget>(
      context,
      conditionalValues: [
        Condition.smallerThan(name: TABLET, value: child),
        Condition.largerThan(name: TABLET, value: child),
        Condition.largerThan(name: DESKTOP, value: child),
      ],
    ).value;
  }

  /// Gets responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return ResponsiveValue<EdgeInsets>(
      context,
      conditionalValues: [
        const Condition.smallerThan(name: TABLET, value: EdgeInsets.all(16)),
        const Condition.largerThan(name: TABLET, value: EdgeInsets.all(24)),
        const Condition.largerThan(name: DESKTOP, value: EdgeInsets.all(32)),
      ],
    ).value;
  }

  /// Gets responsive max width for content
  static double getResponsiveMaxWidth(BuildContext context) {
    return ResponsiveValue<double>(
      context,
      conditionalValues: [
        const Condition.smallerThan(name: TABLET, value: double.infinity),
        const Condition.largerThan(name: TABLET, value: 800.0),
        const Condition.largerThan(name: DESKTOP, value: 1200.0),
      ],
    ).value;
  }

  /// Gets responsive column count for grids
  static int getResponsiveColumnCount(BuildContext context) {
    return ResponsiveValue<int>(
          context,
          conditionalValues: [
            const Condition.smallerThan(name: TABLET, value: 1),
            const Condition.largerThan(name: TABLET, value: 2),
            const Condition.largerThan(name: DESKTOP, value: 3),
          ],
        ).value ??
        1;
  }

  /// Gets responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    return ResponsiveValue<double>(
      context,
      conditionalValues: [
        Condition.smallerThan(name: TABLET, value: mobile),
        Condition.largerThan(name: TABLET, value: tablet),
        Condition.largerThan(name: DESKTOP, value: desktop),
      ],
    ).value;
  }
}
