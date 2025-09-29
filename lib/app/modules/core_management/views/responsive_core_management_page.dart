import 'package:classroom_mini/app/core/utils/responsive_view_factory.dart';
import 'package:flutter/material.dart';
import 'web/responsive_core_management_page.dart' as web;
import 'mobile/enhanced_core_management_page.dart' as mobile;
import 'desktop/responsive_core_management_page.dart' as desktop;

class ResponsiveCoreManagementPage extends StatelessWidget {
  const ResponsiveCoreManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: const mobile.EnhancedCoreManagementPage(),
      tablet: const desktop.ResponsiveCoreManagementPage(),
      desktop: const desktop.ResponsiveCoreManagementPage(),
      fourK: const web.ResponsiveCoreManagementPage(),
    );
  }
}
