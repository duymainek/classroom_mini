import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop, fourK }

class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fourK;

  const AdaptiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.fourK,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = _getScreenSize(constraints.maxWidth);

        switch (screenSize) {
          case ScreenSize.fourK:
            return fourK ?? desktop ?? tablet ?? mobile;
          case ScreenSize.desktop:
            return desktop ?? tablet ?? mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.mobile:
          default:
            return mobile;
        }
      },
    );
  }

  static ScreenSize _getScreenSize(double width) {
    if (width >= 1920) {
      return ScreenSize.fourK;
    } else if (width >= 1024) {
      return ScreenSize.desktop;
    } else if (width >= 768) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.mobile;
    }
  }

  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return _getScreenSize(width) == ScreenSize.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return _getScreenSize(width) == ScreenSize.tablet;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final size = _getScreenSize(width);
    return size == ScreenSize.desktop || size == ScreenSize.fourK;
  }

  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    required double tablet,
    required double desktop,
    double? fourK,
  }) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = _getScreenSize(width);

    switch (screenSize) {
      case ScreenSize.fourK:
        return fourK ?? desktop;
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.mobile:
      default:
        return mobile;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = AdaptiveLayout._getScreenSize(constraints.maxWidth);
        return builder(context, screenSize);
      },
    );
  }
}

