import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveViewFactory {
  /// Creates a responsive view that automatically adapts based on screen size
  static Widget createResponsiveView({
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
    Widget? fourK,
  }) {
    return ResponsiveValue<Widget>(
      getx.Get.context!,
      defaultValue: mobile,
      conditionalValues: [
        if (fourK != null) Condition.largerThan(name: '4K', value: fourK),
        Condition.largerThan(name: DESKTOP, value: desktop),
        Condition.largerThan(name: TABLET, value: tablet),
        Condition.smallerThan(name: TABLET, value: mobile),
      ],
    ).value!;
  }

  /// Creates a responsive view for student pages
  static Widget createStudentView({
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
    Widget? fourK,
  }) {
    return createResponsiveView(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Creates a responsive view for instructor pages
  static Widget createInstructorView({
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
    Widget? fourK,
  }) {
    return createResponsiveView(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Helper method to get current breakpoint name
  static String getCurrentBreakpoint(BuildContext context) {
    return ResponsiveBreakpoints.of(context).breakpoint.name ?? '';
  }

  /// Helper method to check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile;
  }

  /// Helper method to check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }

  /// Helper method to check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }

  /// Helper method to check if current screen is larger than a specific breakpoint
  static bool isLargerThan(BuildContext context, String breakpoint) {
    return ResponsiveBreakpoints.of(context).largerThan(breakpoint);
  }

  /// Helper method to check if current screen is smaller than a specific breakpoint
  static bool isSmallerThan(BuildContext context, String breakpoint) {
    return ResponsiveBreakpoints.of(context).smallerThan(breakpoint);
  }

  /// Helper method to get responsive value based on breakpoint
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
    T? fourK,
  }) {
    return ResponsiveValue<T>(
      context,
      defaultValue: mobile,
      conditionalValues: [
        if (fourK != null) Condition.largerThan(name: '4K', value: fourK),
        Condition.largerThan(name: DESKTOP, value: desktop),
        Condition.largerThan(name: TABLET, value: tablet),
        Condition.smallerThan(name: TABLET, value: mobile),
      ],
    ).value!;
  }
}
