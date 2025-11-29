import 'package:flutter/material.dart';

class ResponsiveHelpers {
  static double getMaxWidth(double screenWidth) {
    if (screenWidth < 768) {
      return double.infinity;
    } else if (screenWidth < 1024) {
      return 900.0;
    } else {
      return 1200.0;
    }
  }

  static double getHorizontalPadding(double screenWidth) {
    final maxWidth = getMaxWidth(screenWidth);
    return screenWidth > maxWidth ? (screenWidth - maxWidth) / 2 : 0.0;
  }

  static Widget wrapSliverWithPadding({
    required Widget sliver,
    required double horizontalPadding,
    EdgeInsets? additionalPadding,
  }) {
    if (horizontalPadding == 0 && additionalPadding == null) {
      return sliver;
    }

    final padding = EdgeInsets.only(
      left: horizontalPadding + (additionalPadding?.left ?? 0),
      right: horizontalPadding + (additionalPadding?.right ?? 0),
      top: additionalPadding?.top ?? 0,
      bottom: additionalPadding?.bottom ?? 0,
    );

    return SliverPadding(
      padding: padding,
      sliver: sliver,
    );
  }
}

