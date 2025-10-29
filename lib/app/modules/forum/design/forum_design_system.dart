import 'package:flutter/material.dart';

/**
 * Forum Design System
 * Centralized design tokens following UX Design Recommendations
 */
class ForumDesignSystem {
  // Private constructor to prevent instantiation
  ForumDesignSystem._();

  // ===== COLORS =====
  static const Color primary = Color(0xFF2196F3);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color neutral = Color(0xFF757575);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFFFFFF);

  // ===== SPACING (8px grid system) =====
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ===== TYPOGRAPHY =====
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // ===== BORDER RADIUS =====
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusPill = 24.0;

  // ===== ELEVATION =====
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;

  // ===== ANIMATION DURATIONS =====
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ===== TOUCH TARGETS =====
  static const double minTouchTarget = 44.0;

  // ===== ICON SIZES =====
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 32.0;

  // ===== AVATAR SIZES =====
  static const double avatarSM = 24.0;
  static const double avatarMD = 32.0;
  static const double avatarLG = 40.0;
  static const double avatarXL = 48.0;

  // ===== RESPONSIVE BREAKPOINTS =====
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;

  // ===== HELPER METHODS =====

  /**
   * Get responsive spacing based on screen width
   */
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return mobile;
    if (width < tabletBreakpoint) return tablet;
    return desktop;
  }

  /**
   * Get responsive padding based on screen width
   */
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(spacingMD);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(spacingLG);
    } else {
      return const EdgeInsets.symmetric(
        horizontal: spacingXXL,
        vertical: spacingLG,
      );
    }
  }

  /**
   * Get card elevation based on interaction state
   */
  static double getCardElevation(bool isPressed, bool isHovered) {
    if (isPressed) return elevationSM;
    if (isHovered) return elevationLG;
    return elevationMD;
  }

  /**
   * Get text color based on context
   */
  static Color getTextColor(
    BuildContext context, {
    bool isSecondary = false,
    bool isDisabled = false,
  }) {
    if (isDisabled) return Colors.grey[400]!;
    if (isSecondary) return Colors.grey[600]!;
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
  }

  /**
   * Get surface color with proper contrast
   */
  static Color getSurfaceColor(
    BuildContext context, {
    bool isElevated = false,
  }) {
    if (isElevated) {
      return Theme.of(context).cardColor;
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }
}

/**
 * Forum Animation Extensions
 * Predefined animation curves and transitions
 */
class ForumAnimations {
  // Animation curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceOut = Curves.bounceOut;

  // Slide transitions
  static Widget slideFromBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: easeOut,
      )),
      child: child,
    );
  }

  static Widget slideFromRight(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: easeOut,
      )),
      child: child,
    );
  }

  // Fade transitions
  static Widget fadeIn(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: easeInOut,
      ),
      child: child,
    );
  }

  // Scale transitions
  static Widget scaleIn(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: bounceOut,
      )),
      child: child,
    );
  }
}

/**
 * Forum Accessibility Extensions
 * Accessibility helpers and semantic labels
 */
class ForumAccessibility {
  /**
   * Get semantic label for topic card
   */
  static String getTopicCardLabel(String title, String author, int replyCount) {
    return 'Topic: $title by $author. $replyCount replies. Tap to view details.';
  }

  /**
   * Get semantic label for reply button
   */
  static String getReplyButtonLabel(String author) {
    return 'Reply to $author';
  }

  /**
   * Get semantic label for like button
   */
  static String getLikeButtonLabel(bool isLiked, int count) {
    return isLiked
        ? 'Unlike this reply. $count likes.'
        : 'Like this reply. $count likes.';
  }

  /**
   * Get semantic label for form field
   */
  static String getFormFieldLabel(String fieldName, {bool isRequired = false}) {
    return isRequired ? '$fieldName (required)' : '$fieldName (optional)';
  }
}
